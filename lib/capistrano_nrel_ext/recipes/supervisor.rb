require "capistrano_nrel_ext/actions/remote_tests"
require "capistrano_nrel_ext/actions/sample_files"

Capistrano::Configuration.instance(true).load do
  #
  # Variables
  #
  set :supervisor_conf_dir, "/etc/supervisor/conf.d"
  set :supervisorctl, "supervisorctl -c /etc/supervisor/supervisord.conf"

  #
  # Hooks
  #
  after "deploy:update_code", "deploy:supervisor:config"
  before "deploy:restart", "deploy:supervisor:install"
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
      task :config, :except => { :no_release => true } do
        parse_sample_files(["config/supervisor"])
      end

      desc <<-DESC
        Install all the Supervisor configuration files in config/supervisor to
        the system Supervisor directory.
      DESC
      task :install, :except => { :no_release => true } do
        conf_files = capture("ls -x #{latest_release}/config/supervisor/*.conf").split
        conf_files.each do |conf_file|
          install_filename = "#{deploy_name}-#{File.basename(conf_file)}"
          run "ln -sf #{conf_file} #{File.join(supervisor_conf_dir, install_filename)}"
        end
      end

      desc <<-DESC
        Reload Monit configuration.
      DESC
      task :reload, :roles => :app, :except => { :no_release => true } do
        # Stop all the programs that belong to this deployment's supervisor
        # group. Reread the supervisor configuration. Then start this
        # deployment's group again.
        sudo "#{supervisorctl} stop '#{deploy_name}:*'"
        sudo "#{supervisorctl} reread"
        sudo "#{supervisorctl} start '#{deploy_name}:*'"
      end
    end
  end

  namespace :undeploy do
    namespace :supervisor do
      # Remove the symbolic link to the supervisor configuration file that's in place
      # for this deployment.
      task :delete do
        # Stop all the programs that belong to this deployment's supervisor
        # group.
        sudo "#{supervisorctl} stop #{deploy_name}"

        # Remove all the configuration files related to this deployment.
        run "rm -f #{File.join(supervisor_conf_dir, "#{deploy_name}-*.conf")}"

        # Reload all the configuration files.
        sudo "#{supervisorctl} reread"
      end
    end
  end
end
