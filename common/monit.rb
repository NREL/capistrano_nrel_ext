# Set some default Monit variables. 
set :monit_conf_dir, "/etc/monit/ctts"

# Create the monit configuration file for this site based on the sample file.
after "deploy:update_code", "deploy:monit:config"

# Put the monit configuration file in place.
before "deploy:restart", "deploy:monit:install"

# Reload Monit configuration after deploys
after "deploy:start", "deploy:monit:reload"
after "deploy:restart", "deploy:monit:reload"

# Remove the installed monit configuration file when undeploying.
after "undeploy:delete", "undeploy:monit:delete"

# Require that the monit configuration directory be in place.
depend(:remote, :directory, monit_conf_dir)

namespace :deploy do
  namespace :monit do
    desc <<-DESC
      Create the Monit configuration file. If a sample file for the given stage
      is present in config/monit, the sample is run through ERB (for variable
      replacement) to create the actual config file to be used.
    DESC
    task :config, :except => { :no_release => true } do
      parse_sample_files([
        "config/shared_config/monit/delayed_job.monitrc",
        "config/monit/#{stage}.monitrc"])
    end

    desc <<-DESC
      Install the Monit configuration file in a system-wide directory for Monit
      to find. This makes a symbolic link to the latest configuration file for
      this deployment in Monit's configuration directory.
    DESC
    task :install, :except => { :no_release => true } do
      path = File.join(latest_release, "config", "monit", "#{stage}.monitrc")
      if(remote_file_exists?(path))
        run "ln -sf #{path} #{monit_conf_dir}/#{deploy_name}.monitrc"
      end
    end

    desc <<-DESC
      Reload Monit configuration.
    DESC
    task :reload, :roles => :app, :except => { :no_release => true } do
      begin
        sudo "monit reload"
      rescue Capistrano::CommandError
      end
    end
  end
end

namespace :undeploy do
  namespace :monit do
    # Remove the symbolic link to the monit configuration file that's in place
    # for this deployment.
    task :delete do
      run "rm -f #{monit_conf_dir}/#{deploy_name}.monitrc"
      deploy.monit.reload
    end
  end
end
