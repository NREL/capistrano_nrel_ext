require "capistrano_nrel_ext/actions/remote_tests"
require "capistrano_nrel_ext/actions/sample_files"

Capistrano::Configuration.instance(true).load do
  #
  # Variables
  #
  set :monit_conf_dir, "/etc/monit/conf.d"
  set :monit_init_script, "/etc/init.d/monit"
  set :monit_groups, {}

  #
  # Hooks 
  #
  after "deploy:update_code", "deploy:monit:config"
  before "deploy:restart", "deploy:monit:reload"
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
        monit_groups.each do |group_name, conf_file|
          set :monit_group_name, group_name
          parse_sample_files(conf_file)
        end
      end

      desc <<-DESC
        Reload Monit configuration.
      DESC
      task :reload, :roles => :app, :except => { :no_release => true } do
        # Reloading monit gets a wee bit ugly. We want to stop all group
        # processes, reload the configuration, and then start all group
        # processes. Reloading this way accounts for any new additions or
        # subtractions that might be inside the monit config files.
        
        begin
          # Stop the monit daemon. This lets the monit stop group command below
          # happen synchronously. If the daemon is running during the group
          # stop command, it gets backgrounded, and then the next call to
          # reload the configuration happens immediately, before the processes
          # may have stopped.
          sudo "#{monit_init_script} stop"
        rescue Capistrano::CommandError
        end

        # With the monit daemon stopped, these group start and stop commands
        # now happen synchronously, so we can reliably stop all processes, put
        # in our new configuration file, and then start all processes using
        # that new config file.
        monit_groups.each do |group_name, conf_file|
          conf_file_path = File.join(latest_release, conf_file)
          if(remote_file_exists?(conf_file_path))
            begin
              begin
                run "sudo monit -g #{group_name} stop all"
              rescue Capistrano::CommandError
              end

              run "ln -sf #{conf_file_path} #{File.join(monit_conf_dir, "#{group_name}.monitrc")} && " +
                "sudo monit -g #{group_name} start all"
            rescue Capistrano::CommandError
            end
          end
        end

        # Bring the monit daemon back up.
        sudo "#{monit_init_script} start"

        # Since the daemon was down while we added new groups, it might not be
        # monitoring them. This group should already be up, but we'll just be
        # sure monit knows about it.
        monit_groups.each do |group_name, files|
          sudo "monit -g #{group_name} start all"
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
        begin
          begin
            sudo "#{monit_init_script} stop"
          rescue Capistrano::CommandError
          end

          monit_groups.each do |group_name, conf_file|
            sudo "monit -g #{group_name} stop all"
          end
        ensure
          sudo "#{monit_init_script} start"
        end
      end
    end
  end
end
