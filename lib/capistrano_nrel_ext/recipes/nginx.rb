require "capistrano_nrel_ext/actions/remote_tests"
require "capistrano_nrel_ext/actions/template_files"

Capistrano::Configuration.instance(true).load do
  #
  # Variables
  #
  _cset :nginx_conf_dir, "/etc/nginx/sites-available"
  _cset :nginx_init_script, "/etc/init.d/nginx"
  _cset :nginx_applications, ["."]

  #
  # Hooks 
  #
  after "deploy:update_code", "deploy:nginx:config"
  before "deploy:start", "deploy:nginx:install"
  before "deploy:restart", "deploy:nginx:install"
  after "deploy:start", "nginx:reload"
  after "deploy:restart", "nginx:reload"
  before "undeploy:delete", "undeploy:nginx:delete"
  after "undeploy", "nginx:reload"

  #
  # Tasks
  #
  namespace :nginx do
    desc <<-DESC
      Restart Nginx. This should be executed if new Nginx configuration
      files have been deployed.
    DESC
    task :reload, :roles => :app, :except => { :no_release => true } do
      sudo "#{nginx_init_script} configtest && sudo #{nginx_init_script} reload"
    end
  end

  namespace :deploy do
    namespace :nginx do
      desc <<-DESC
        Create the Nginx configuration file. If a sample file for the given
        stage is present in config/nginx, the sample is run through ERB (for
        variable replacement) to create the actual config file to be used.
      DESC
      task :config, :roles => :app, :except => { :no_release => true } do
        parse_template_files(["config/nginx"])
      end

      desc <<-DESC
        Install the Nginx configuration file in a system-wide directory for
        Nginx to find. This makes a symbolic link to the latest configuration
        file for this deployment in Nginx's configuration directory.
      DESC
      task :install, :roles => :app, :except => { :no_release => true } do
        # Make sure the existing nginx config in place on the server is valid
        # before installing any new stuff.
        sudo "#{nginx_init_script} configtest"

        conf_file = "#{latest_release}/config/nginx/site.conf"
        if(remote_file_exists?(conf_file))
          run "ln -sf #{conf_file} #{nginx_conf_dir}/#{deploy_name}"
          run "nxensite #{deploy_name}"
        end

        # Ensure the new configuration in place is valid.
        sudo "#{nginx_init_script} configtest"
      end
    end
  end

  namespace :undeploy do
    namespace :nginx do
      # Remove the symbolic link to the nginx configuration file that's in
      # place for this deployment.
      task :delete do
        begin
          run "nxdissite #{deploy_name}"
        rescue Capistrano::CommandError
        end

        run "rm -f #{nginx_conf_dir}/#{deploy_name}"
      end
    end
  end
end
