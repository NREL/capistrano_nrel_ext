require "capistrano_nrel_ext/recipes/nginx"
require "capistrano_nrel_ext/recipes/rails"

Capistrano::Configuration.instance(true).load do
  #
  # Variables
  #
  _cset :torquebox_home, "/opt/torquebox"
  _cset :torquebox_http_port, 8180
  _cset(:torquebox_jboss_home) { File.join(torquebox_home, "jboss") }
  _cset(:torquebox_deployments_dir) { File.join(torquebox_jboss_home, "standalone/deployments") }
  _cset :torquebox_deploy_timeout, 120
  _cset :torquebox_deploy_style, :phased
  _cset(:torquebox_app_paths) { rails_app_paths.keys }
  _cset :torquebox_phased_spindown_time, 10
  _cset(:torquebox_release_domain) do
    if(torquebox_deploy_style == :hot)
      domain
    else
      "#{release_name.gsub(/[^A-Za-z0-9]/, "")}.#{domain}"
    end
  end

  set(:torquebox_apps) do
    torquebox_apps = []
    rails_apps.each do |app|
      if(torquebox_app_paths.include?(app[:path]))
        torquebox_app = app.dup

        if(torquebox_deploy_style == :hot)
          torquebox_app[:release_name_prefix] = torquebox_app[:name]
          torquebox_app[:release_name] = torquebox_app[:name]
        else
          torquebox_app[:release_name_prefix] = "#{torquebox_app[:name]}-release-"
          torquebox_app[:release_name] = "#{torquebox_app[:release_name_prefix]}#{release_name}"
        end

        torquebox_app[:descriptor_path] = File.join(torquebox_deployments_dir, "#{torquebox_app[:release_name]}-knob.yml")

        torquebox_apps << torquebox_app
      end
    end

    torquebox_apps
  end

  #
  # Hooks
  #
  before "deploy:start", "deploy:torquebox:install", "deploy:torquebox:phased_prewarm"
  before "deploy:restart", "deploy:torquebox:install", "deploy:torquebox:phased_prewarm"
  after "deploy:start", "deploy:torquebox:hot_reload", "deploy:torquebox:phased_spindown"
  after "deploy:restart", "deploy:torquebox:hot_reload", "deploy:torquebox:phased_spindown"
  before "undeploy:delete", "undeploy:torquebox:delete"

  #
  # Dependencies
  #
  depend(:remote, :command, "curl")
  depend(:remote, :command, "find")
  depend(:remote, :command, "inotifywait")

  #
  # Tasks
  #
  namespace :deploy do
    namespace :torquebox do
      desc <<-DESC
        Install the Torquebox deployment descriptors.
      DESC
      task :install, :roles => :app, :except => { :no_release => true } do
        torquebox_apps.each do |app|
          config = {
            "application" => {
              "root" => File.expand_path(File.join(latest_release, app[:path])),
            },
            "web" => {
              "host" => torquebox_release_domain,
              "context" => app[:base_uri],
            },
            "environment" => {
              "RAILS_ENV" => rails_env,
            },
          }

          if(torquebox_deploy_style == :hot)
            config["application"]["root"] = app[:current_path]
          end

          put(YAML.dump(config), app[:descriptor_path])

          # Since this deployment descriptor exists outside the normal path,
          # make sure it explicitly has group writable permissions.
          if(fetch(:group_writable, true))
            commands = []
            if(exists?(:group))
              commands << "chgrp #{group} #{app[:descriptor_path]}"
            end

            commands << "chmod g+w #{app[:descriptor_path]}"

            run commands.join(" && ")
          end
        end
      end

      task :phased_prewarm, :roles => :app, :except => { :no_release => true } do
        if(torquebox_deploy_style == :phased)
          torquebox_apps.each do |app|
            # Perform the following:
            #
            # - Deploy the new app
            # - Wait for it to finish deploying (marked by the ".dodeploy" file
            #   being deleted).
            # - Make sure it didn't fail deploying.
            # - Make a HEAD request to the app ensure it's pre-warmed.
            run <<-CMD
              umask 000; touch #{app[:descriptor_path]}.dodeploy && \
              inotifywait --timeout #{torquebox_deploy_timeout} --event delete_self #{app[:descriptor_path]}.dodeploy && \
              if [ $? -ne 0 ]; then \
                echo "Deployment of #{app[:name]} to TorqueBox failed. #{app[:descriptor_path]}.dodeploy not cleaned up. See logs for more details"; \
                exit 1; \
              fi; \
              sleep 0.2 && \
              if [ -f #{app[:descriptor_path]}.failed ]; then \
                echo "Pre-deployment of #{app[:name]} to TorqueBox failed. See logs for more details"; \
                exit 1; \
              fi && \
              curl --silent --show-error --head --header 'Host: #{torquebox_release_domain}' 'http://127.0.0.1:#{torquebox_http_port}#{app[:base_uri]}'
            CMD
          end
        end
      end

      task :hot_reload, :roles => :app, :except => { :no_release => true } do
        if(torquebox_deploy_style == :hot)
          torquebox_apps.each do |app|
            run <<-CMD
              if [ -f #{app[:descriptor_path]}.deployed ]; then \
                chmod 777 #{app[:current_path]}/tmp; \
                umask 000; touch #{app[:current_path]}/tmp/restart.txt && \
                inotifywait --timeout #{torquebox_deploy_timeout} --event delete_self #{app[:current_path]}/tmp/restart.txt && \
                if [ $? -ne 0 ]; then \
                  echo "Deployment of #{app[:name]} to TorqueBox failed. #{app[:current_path]}/tmp/restart.txt not cleaned up. See logs for more details"; \
                  exit 1; \
                fi \
              else
                umask 000; touch #{app[:descriptor_path]}.dodeploy && \
                inotifywait --timeout #{torquebox_deploy_timeout} --event delete_self #{app[:descriptor_path]}.dodeploy && \
                if [ $? -ne 0 ]; then \
                  echo "Deployment of #{app[:name]} to TorqueBox failed. #{app[:descriptor_path]}.dodeploy not cleaned up. See logs for more details"; \
                  exit 1; \
                fi; \
                sleep 0.2 && \
                if [ -f #{app[:descriptor_path]}.failed ]; then \
                  echo "Deployment of #{app[:name]} to TorqueBox failed. #{app[:descriptor_path]}.failed present. See logs for more details"; \
                  exit 1; \
                fi \
              fi
            CMD
          end
        end
      end

      task :phased_spindown, :roles => :app, :except => { :no_release => true } do
        if(torquebox_deploy_style == :phased)
          # Find all the descriptor files related to our torquebox apps.
          descriptors_glob = []
          torquebox_apps.each do |app|
            descriptors_glob << "#{app[:release_name_prefix]}*-knob.yml*"

            # Cleanup any deployments from if "hot" deploys were previously used.
            descriptors_glob << "#{app[:name]}-knob.yml*"
          end

          find_args = descriptors_glob.map { |glob| "-name '#{glob}'" }
          descriptors = capture("find #{torquebox_deployments_dir} #{find_args.join(" -or ")}").to_s.split

          # Remove all the descriptors related to the actively deployed versions
          # of the apps.
          active_descriptors = torquebox_apps.map { |app| app[:descriptor_path] }
          active_descriptors.each do |active_descriptor|
            descriptors.reject! { |path| path.start_with?(active_descriptor) }
          end

          # If any descriptors remain, these are from previous versions of the
          # app in previous deployments.
          if descriptors.any?
            # Undeploy the previous versions of the apps, but first wait to allow
            # time for any active connections to the previous version to finish.
            #
            # It would be nice if there were a way to determine if the old
            # version had any active connections or not, but for now, we'll just
            # assume this timeout will cover most circumstances.
            logger.info("Waiting #{torquebox_phased_spindown_time} seconds before undeploying previous versions of TorqueBox apps...")
            sleep torquebox_phased_spindown_time
            run "rm -f #{descriptors.join(" ")}"
          end
        end
      end
    end
  end

  namespace :undeploy do
    namespace :torquebox do
      task :delete do
        descriptors = torquebox_apps.map { |app| app[:descriptor_path] }
        run "rm -f #{descriptors.join(" ")}"
      end
    end
  end
end
