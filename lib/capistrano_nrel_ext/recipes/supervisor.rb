require "capistrano_nrel_ext/actions/remote_tests"
require "capistrano_nrel_ext/actions/sample_files"

Capistrano::Configuration.instance(true).load do
  #
  # Variables
  #
  set :supervisor_conf_dir, "/etc/supervisord.d"
  set :supervisorctl, "supervisorctl"
  set :supervisorctl_rolling_restart, "/usr/local/bin/supervisorctl_rolling_restart"

  #
  # Hooks
  #
  after "deploy:update_code", "deploy:supervisor:config"
  before "deploy:start", "deploy:supervisor:install"
  before "deploy:restart", "deploy:supervisor:install"
  after "deploy:start", "deploy:supervisor:reload"
  after "deploy:restart", "deploy:supervisor:reload"
  before "undeploy:delete", "undeploy:supervisor:delete"

  #
  # Dependencies
  #
  depend(:remote, :directory, supervisor_conf_dir)

  #
  # Tasks
  #
  namespace :deploy do
    namespace :supervisor do
      desc <<-DESC
        Create the Supervisor configuration files, parsing any template config
        files.
      DESC
      task :config, :roles => :app, :except => { :no_release => true } do
        parse_sample_files(["config/supervisor"])
      end

      desc <<-DESC
        Install all the Supervisor configuration files in config/supervisor to
        the system Supervisor directory.
      DESC
      task :install, :roles => :app, :except => { :no_release => true } do
        conf_files = []

        begin
          conf_files = capture("ls -x #{latest_release}/config/supervisor/*.conf").split
        rescue Capistrano::CommandError
          logger.info("Supervisor config files don't exist - Skipping")
        end

        conf_files.each do |conf_file|
          install_filename = "#{deploy_name}-#{File.basename(conf_file)}"
          run "ln -sf #{conf_file} #{File.join(supervisor_conf_dir, install_filename)}"
        end
      end

      desc <<-DESC
        Reload Supervisor configuration.
      DESC
      task :reload, :roles => :app, :except => { :no_release => true } do
        # FIXME: This check is only needed while we're still deploying some old
        # branches haven't been updated. We want to be able to deploy older
        # branches, from our newer deployment recipes, but the older branches
        # won't have the supervisor files there. Remove once all branches have
        # been updated with supervisor config.
        if(remote_directory_exists?(File.join(latest_release, "config", "supervisor")))
          # Have supervisor reload it's configuration and then we'll restart this
          # process group so the latest copy of the program is running after
          # deployment.
          sudo "#{supervisorctl} update"

          if(remote_file_exists?(supervisorctl_rolling_restart))
            sudo "#{supervisorctl_rolling_restart} '#{deploy_name}'"
          else
            sudo "#{supervisorctl} restart '#{deploy_name}:*'"
          end
        end
      end
    end
  end

  namespace :undeploy do
    namespace :supervisor do
      # Remove the symbolic link to the supervisor configuration file that's in place
      # for this deployment.
      task :delete, :roles => :app do
        # Remove all the configuration files related to this deployment.
        run "rm -f #{File.join(supervisor_conf_dir, "#{deploy_name}-*.conf")}"

        # Sending the update command should intelligently read an new
        # configuration changes, and stop and remove things as necessary.
        sudo "#{supervisorctl} update"
      end
    end
  end
end
