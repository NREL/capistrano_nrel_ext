require "capistrano_nrel_ext/actions/remote_tests"
require "capistrano_nrel_ext/actions/sample_files"

Capistrano::Configuration.instance(true).load do
  #
  # Variables
  #
  set :haproxy_conf_dir, "/etc/haproxy/conf.d"

  #
  # Hooks 
  #
  after "deploy:update_code", "deploy:haproxy:config"
  before "deploy:restart", "deploy:haproxy:install"
  after "deploy:restart", "haproxy:reload"

  #
  # Tasks
  #
  namespace :haproxy do
    desc <<-DESC
      Restart Apache. This should be executed if new Apache configuration
      files have been deployed.
    DESC
    task :reload, :roles => :app, :except => { :no_release => true } do
      sudo "/etc/init.d/haproxy reload"
    end
  end

  namespace :deploy do
    namespace :haproxy do
      desc <<-DESC
        Create the Apache configuration file. If a sample file for the given
        stage is present in config/apache, the sample is run through ERB (for
        variable replacement) to create the actual config file to be used.
      DESC
      task :config, :except => { :no_release => true } do
        parse_sample_files(["config/haproxy/base.cfg", "config/haproxy/public_web.cfg"])
      end

      desc <<-DESC
        Install the Apache configuration file in a system-wide directory for
        Apache to find. This makes a symbolic link to the latest configuration
        file for this deployment in Apache's configuration directory.
      DESC
      task :install, :except => { :no_release => true } do
        public_conf_file = File.join(latest_release, "config", "haproxy", "public_web.cfg")
        if(remote_file_exists?(public_conf_file))
          install_path = File.join(haproxy_conf_dir, "011-public_web-#{deploy_name}.cfg")
          run "ln -sf #{public_conf_file} #{install_path}"
        end

        conf_file = File.join(latest_release, "config", "haproxy", "base.cfg")
        if(remote_file_exists?(conf_file))
          install_path = File.join(haproxy_conf_dir, "#{deploy_name}.cfg")
          run "ln -sf #{conf_file} #{install_path}"
        end
      end
    end
  end
end
