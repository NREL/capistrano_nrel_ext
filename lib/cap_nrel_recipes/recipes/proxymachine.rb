Capistrano::Configuration.instance(true).load do
  set :proxymachine_servers, []
  set :proxymachine_conf_dir, "/etc/proxymachine"
  set(:proxymachine_conf_file) { File.join(latest_release, "config", "proxymachine.yml") }

  # Create the apache configuration file for this site based on the sample file.
  after "deploy:update_code", "deploy:proxymachine:config"
  # Put the created apache configuration file in place.
  before "deploy:restart", "deploy:proxymachine:install"

  namespace :proxymachine do
    desc <<-DESC
      Restart Apache. This should be executed if new Apache configuration
      files have been deployed.
    DESC
    task :restart, :roles => :app, :except => { :no_release => true } do
      sudo "/etc/init.d/proxymachine restart"
    end
  end

  namespace :deploy do
    namespace :proxymachine do
      desc <<-DESC
        Create the Apache configuration file. If a sample file for the given
        stage is present in config/apache, the sample is run through ERB (for
        variable replacement) to create the actual config file to be used.
      DESC
      task :config, :except => { :no_release => true } do
        config = {}
        proxymachine_servers.each do |server_config|
          server_name = "#{deploy_name}-#{server_config[:host]}-#{server_config[:port]}"
          config[server_name] = server_config
        end

        put(YAML.dump(config), proxymachine_conf_file)
      end

      desc <<-DESC
        Install the Apache configuration file in a system-wide directory for
        Apache to find. This makes a symbolic link to the latest configuration
        file for this deployment in Apache's configuration directory.
      DESC
      task :install, :except => { :no_release => true } do
        if(remote_file_exists?(proxymachine_conf_file))
          run "ln -sf #{proxymachine_conf_file} #{proxymachine_conf_dir}/#{deploy_name}.yml"
        end
      end
    end
  end
end
