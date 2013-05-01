require "capistrano_nrel_ext/recipes/nginx"
require "capistrano_nrel_ext/recipes/rails"

# Zero-Downtime deployments with TorqueBox and Nginx. The overall strategy is:
#
# - On each deployment, each TorqueBox app gets deployed under a new subdomain
#   (based on the timestamp release name).
# - Nginx is used to proxy to the TorqueBox apps running at these subdomains.
# - On each deployment, the Nginx configuration should get updated to proxy to
#   the latest release's unique subdomain.
# - Prior to Nginx's reload, we deploy and pre-warm the Rails app on the new
#   subdomain.
# - After Nginx's reload, two versions of the app are deployed inside
#   TorqueBox. All new traffic is routed to the new, pre-warmed app, while any
#   active connections at the time of reload can still finish their request
#   against the old version of the app.
# - After a default time of 30 seconds, it's assumed any requests to the old
#   version of the app are finished and the old version is undeployed.
Capistrano::Configuration.instance(true).load do
  #
  # Variables
  #
  _cset :torquebox_home, "/opt/torquebox/home"
  _cset :torquebox_http_port, 8180
  _cset(:torquebox_jboss_home) { File.join(torquebox_home, "jboss") }
  _cset(:torquebox_deployments_dir) { File.join(torquebox_jboss_home, "standalone/deployments") }
  _cset :torquebox_deploy_timeout, 120
  _cset :torquebox_spindown_time, 30

  _cset :torquebox_apps, []
  set(:torquebox_apps) do
    apps = rails_apps
    apps.each do |app|
      # Each deployment goes to a unique hostname based on the timestamped
      # release name. 
      app[:host] = "#{release_name.gsub(/[^A-Za-z0-9]/, "")}.#{domain}"

      app[:release_name_prefix] = "#{app[:name]}-release-"
      app[:release_name] = "#{app[:release_name_prefix]}#{release_name}"
      app[:descriptor_path] = File.join(torquebox_deployments_dir, "#{app[:release_name]}-knob.yml")
    end

    apps
  end

  #
  # Hooks
  #
  before "deploy:start", "deploy:torquebox:install", "deploy:torquebox:prewarm"
  before "deploy:restart", "deploy:torquebox:install", "deploy:torquebox:prewarm"
  after "deploy:start", "deploy:torquebox:spindown"
  after "deploy:restart", "deploy:torquebox:spindown"

  #
  # Dependencies
  #
  depend(:remote, :command, "inotifywait")
  depend(:remote, :command, "curl")

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
              "root" => File.expand_path(File.join(current_release, app[:path])),
            },
            "web" => {
              "host" => app[:host],
              "context" => app[:base_uri],
            },
            "environment" => {
              "RAILS_ENV" => rails_env,
            },
          }

          file_options = {}
          if(fetch(:group_writable, true))
            file_options[:mode] = "0664"
          end

          put(YAML.dump(config), app[:descriptor_path], file_options)
        end
      end

      desc <<-DESC
        Prewam each Torquebox app before it goes live. 
      DESC
      task :prewarm, :roles => :app, :except => { :no_release => true } do
        torquebox_apps.each do |app|
          # Perform the following:
          #
          # - Deploy the new app
          # - Wait for it to finish deploying (marked by the ".dodeploy" file
          #   being deleted).
          # - Make sure it didn't fail deploying.
          # - Make a HEAD request to the app ensure it's pre-warmed.
          run <<-CMD
            touch #{app[:descriptor_path]}.dodeploy && \
            inotifywait --timeout #{torquebox_deploy_timeout} --event delete_self #{app[:descriptor_path]}.dodeploy && \
            sleep 0.2 && \
            if [ -f #{app[:descriptor_path]}.failed ]; then \
              echo "Pre-deployment of #{app[:name]} to TorqueBox failed. See logs for more details"; \
              exit 1; \
            fi && \
            curl --head --header 'Host: #{app[:host]}' 'http://127.0.0.1:#{torquebox_http_port}#{app[:base_uri]}'
          CMD
        end
      end

      desc <<-DESC
        Undeploy any old applications
      DESC
      task :spindown, :roles => :app, :except => { :no_release => true } do
        # Cleanup any files left from previously undeployed apps.
        sudo "rm -f #{File.join(torquebox_deployments_dir, "*knob.yml.undeployed")}"

        # Find all the descriptor files related to our torquebox apps.
        descriptors_glob = torquebox_apps.map do |app|
          File.join(torquebox_deployments_dir, "#{app[:release_name_prefix]}*-knob.yml*")
        end
        descriptors = capture("ls -1 #{descriptors_glob.join(" ")}").to_s.split

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
          logger.info("Waiting #{torquebox_spindown_time} seconds before undeploying previous versions of TorqueBox apps...")
          sleep torquebox_spindown_time
          sudo "rm -f #{descriptors.join(" ")}"
        end
      end
    end
  end
end
