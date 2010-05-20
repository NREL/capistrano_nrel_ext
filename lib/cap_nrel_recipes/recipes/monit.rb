require "cap_nrel_recipes/actions/remote_tests"
require "cap_nrel_recipes/actions/sample_files"
require "cap_nrel_recipes/recipes/previous_release"

Capistrano::Configuration.instance(true).load do
  #
  # Variables
  #
  set :monit_conf_dir, "/etc/monit/conf.d"
  set :monit_conf_files, []
  set(:monit_group) { "#{deploy_name}-#{release_name}" }
  set(:previous_monit_group) { if(previous_release_name) then "#{deploy_name}-#{previous_release_name}" else nil end}

  #
  # Hooks 
  #
  after "deploy:update_code", "deploy:monit:config"
  before "deploy:restart", "deploy:monit:install"
  after "deploy:restart", "deploy:monit:remove_previous_group"
  before "undeploy:delete", "undeploy:monit:delete"

  #
  # Dependencies
  #
  depend(:remote, :directory, monit_conf_dir)

  #
  # Tasks
  #
  namespace :deploy do
    namespace :monit do
      desc <<-DESC
        Create the Monit configuration file. If a sample file for the given stage
        is present in config/monit, the sample is run through ERB (for variable
        replacement) to create the actual config file to be used.
      DESC
      task :config, :except => { :no_release => true } do
        parse_sample_files(monit_conf_files)
      end

      desc <<-DESC
        Install the Monit configuration files in a system-wide directory for
        Monit to find. This makes a symbolic link to the latest configuration
        file for this deployment in Monit's configuration directory.
      DESC
      task :install, :except => { :no_release => true } do
        monit_conf_files.each do |file|
          path = File.join(latest_release, file)
          if(remote_file_exists?(path))
            filename = "#{monit_group}-#{File.basename(path)}"
            run "ln -sf #{path} #{File.join(monit_conf_dir, filename)}"
          end
        end

        deploy.monit.reload
      end

      desc <<-DESC
        Reload Monit configuration.
      DESC
      task :reload, :roles => :app, :except => { :no_release => true } do
        begin
          sudo "monit reload"
        rescue Capistrano::CommandError
        end

        deploy.monit.start_group
      end

      desc <<-DESC
        Start the group of monit processes for this deployment.
      DESC
      task :start_group, :roles => :app, :except => { :no_release => true } do
        begin
          sudo "monit -g #{monit_group} start all"
        rescue Capistrano::CommandError
        end
      end

      desc <<-DESC
        Stop the group of monit processes for this deployment.
      DESC
      task :stop_group, :roles => :app, :except => { :no_release => true } do
        begin
          sudo "monit -g #{monit_group} stop all"
        rescue Capistrano::CommandError
        end
      end

      task :remove_previous_group, :roles => :app, :except => { :no_release => true } do
        if previous_monit_group
          begin
            sudo "monit -g #{previous_monit_group} stop all"
          rescue Capistrano::CommandError
          end

          run "rm -f #{monit_conf_dir}/#{previous_monit_group}-*"
        end
      end
    end
  end

  namespace :undeploy do
    namespace :monit do
      # Remove the symbolic link to the monit configuration file that's in place
      # for this deployment.
      task :delete do
        deploy.monit.stop_group
        run "rm -f #{monit_conf_dir}/#{monit_group}-*"
        deploy.monit.reload
      end
    end
  end
end
