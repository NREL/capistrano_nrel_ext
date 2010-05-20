require "cap_nrel_recipes/actions/remote_tests"
require "cap_nrel_recipes/actions/sample_files"

Capistrano::Configuration.instance(true).load do
  # Create the apache configuration file for this site based on the sample file.
  after "deploy:update_code", "deploy:haproxy:config"

  namespace :haproxy do
    desc <<-DESC
      Restart Apache. This should be executed if new Apache configuration
      files have been deployed.
    DESC
    task :restart, :roles => :app, :except => { :no_release => true } do
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
        parse_sample_files(["config/haproxy.cfg"])
      end

      desc <<-DESC
        Install the Apache configuration file in a system-wide directory for
        Apache to find. This makes a symbolic link to the latest configuration
        file for this deployment in Apache's configuration directory.
      DESC
      task :install, :except => { :no_release => true } do
        conf_file = "#{latest_release}/config/apache/#{stage}.conf"

        if(remote_file_exists?(conf_file))
          # Ensure the the Apache configuration directories are in place.
          dirs = ["#{apache_conf_dir}/include", "#{apache_conf_dir}/sites"]
          begin
            run "mkdir -p #{dirs.join(' ')}"
            run "chmod -f g+w #{dirs.join(' ')}"
          rescue Capistrano::CommandError
          end

          run "ln -sf #{conf_file} #{apache_conf_dir}/sites/#{deploy_name}.conf"
        end
      end
    end
  end
end
