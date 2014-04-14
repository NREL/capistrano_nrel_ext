require "capistrano_nrel_ext/actions/remote_tests"
require "capistrano_nrel_ext/actions/template_files"

# DEPRECATED: None of the actions in this monit recipe do anything. We're no longer
# using monit, but deployment scripts in old branches might still reference it.
# The quick-fix is to simply make this non-functional so it doesn't cause any
# failures.
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
  before "deploy:start", "deploy:monit:reload"
  before "deploy:restart", "deploy:monit:reload"
  before "undeploy:delete", "undeploy:monit:delete"

  #
  # Dependencies
  #
  # depend(:remote, :directory, monit_conf_dir)

  #
  # Tasks
  #
  namespace :deploy do
    namespace :monit do
      desc <<-DESC
        Does nothing
      DESC
      task :config, :except => { :no_release => true } do
        # Does nothing (see comments at top of file)
      end

      desc <<-DESC
        Does nothing
      DESC
      task :reload, :roles => :app, :except => { :no_release => true } do
        # Does nothing (see comments at top of file)
      end
    end
  end

  namespace :undeploy do
    namespace :monit do
      # Remove the symbolic link to the monit configuration file that's in place
      # for this deployment.
      task :delete do
        # Does nothing (see comments at top of file)
      end
    end
  end
end
