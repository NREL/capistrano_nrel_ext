require "capistrano_nrel_ext/actions/remote_tests"
require "capistrano_nrel_ext/actions/template_files"

Capistrano::Configuration.instance(true).load do
  #
  # Variables
  #
  _cset :apache_conf_dir, "/etc/apache2/sites-available"
  _cset :apache_init_script, "/etc/init.d/apache2"

  #
  # Hooks
  #
  after "deploy:update_code", "deploy:apache:config"
  before "deploy:start", "deploy:apache:install"
  before "deploy:restart", "deploy:apache:install"
  after "deploy:start", "apache:reload"
  after "deploy:restart", "apache:reload"
  before "undeploy:delete", "undeploy:apache:delete"
  after "undeploy", "apache:reload"

  #
  # Dependencies
  #
  #depend(:remote, :directory, apache_conf_dir)

  #
  # Tasks
  #
  namespace :apache do
    desc <<-DESC
      Restart Apache. This should be executed if new Apache configuration
      files have been deployed.
    DESC
    task :reload, :roles => :app, :except => { :no_release => true } do
      sudo "#{apache_init_script} configtest && sudo #{apache_init_script} reload"
    end
  end

  namespace :deploy do
    namespace :apache do
      desc <<-DESC
        Create the Apache configuration file. If a sample file for the given
        stage is present in config/apache, the sample is run through ERB (for
        variable replacement) to create the actual config file to be used.
      DESC
      task :config, :except => { :no_release => true } do
        parse_template_files(["config/apache"])
      end

      desc <<-DESC
        Install the Apache configuration file in a system-wide directory for
        Apache to find. This makes a symbolic link to the latest configuration
        file for this deployment in Apache's configuration directory.
      DESC
      task :install, :except => { :no_release => true } do
        conf_file = "#{latest_release}/config/apache/site.conf"
        if(remote_file_exists?(conf_file))
          run "ln -sf #{conf_file} #{apache_conf_dir}/#{deploy_name}"
          run "a2ensite #{deploy_name}"
        end

        # Ensure the new configuration in place is valid.
        sudo "#{apache_init_script} configtest"
      end
    end
  end

  namespace :undeploy do
    namespace :apache do
      # Remove the symbolic link to the apache configuration file that's in
      # place for this deployment.
      task :delete do
        begin
          run "a2dissite #{deploy_name}"
        rescue Capistrano::CommandError
        end

        run "rm -f #{apache_conf_dir}/#{deploy_name}"
      end
    end
  end
end
