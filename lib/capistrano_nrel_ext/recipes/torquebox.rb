require "capistrano_nrel_ext/recipes/rails"

Capistrano::Configuration.instance(true).load do
  #
  # Variables
  #
  _cset :torquebox_home, "/opt/torquebox"
  _cset :torquebox_http_port, 8180
  _cset(:torquebox_jboss_home) { File.join(torquebox_home, "jboss") }
  _cset(:torquebox_deployments_dir) { File.join(torquebox_jboss_home, "standalone/deployments") }

  set(:torquebox_apps) do
    apps = rails_apps
    apps.each do |app|
      app[:descriptor_path] = File.join(torquebox_deployments_dir, "#{app[:name]}-knob.yml")
    end

    apps
  end

  #
  # Hooks
  #
  before "deploy:start", "deploy:torquebox:install"
  before "deploy:restart", "deploy:torquebox:install"
  after "deploy:start", "deploy:torquebox:reload"
  after "deploy:restart", "deploy:torquebox:reload"
  before "undeploy:delete", "undeploy:torquebox:delete"

  #
  # Dependencies
  #
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
              "root" => app[:current_path],
            },
            "web" => {
              "host" => domain,
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

          # Since this deployment descriptor exists outside the normal path,
          # make sure it explicitly has group writable permissions.
          if(fetch(:group_writable, true))
            commands = []
            if(exists?(:group))
              commands << "chgrp -f #{group} #{app[:descriptor_path]}"
            end

            commands << "chmod -f g+w #{app[:descriptor_path]}"

            begin
              run commands.join("; ")
            rescue Capistrano::CommandError
              # Fail silently. We'll assume if anything failed here, it was because
              # the permissions were already set correctly (but just owned by another
              # user).
            end
          end
        end
      end

      task :reload, :roles => :app, :except => { :no_release => true } do
        torquebox_apps.each do |app|
          run <<-CMD
            if [ -f #{app[:descriptor_path]}.deployed ]; then \
              chmod 777 #{app[:current_path]}/tmp; \
              umask 000; touch #{app[:current_path]}/tmp/restart.txt; \
            else
              umask 000; touch #{app[:descriptor_path]}.dodeploy; \
            fi
          CMD
        end
      end
    end
  end

  namespace :undeploy do
    namespace :torquebox do
      task :delete do
        torquebox_apps.each do |app|
          run "rm -f #{app[:descriptor_path]}"
        end
      end
    end
  end
end
