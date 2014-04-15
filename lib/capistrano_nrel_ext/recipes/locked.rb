require "time"
require "capistrano/cli"

class Capistrano::CLI
  # Monkey patch Capistrano's internal execute_requested_actions method to
  # ensure the lock file gets cleaned up on deployment failures.
  #
  # We normally rely on the `after "deploy"` callback to cleanup the lock file,
  # but if the deployment fails at a variety of other places during setup or in
  # before tasks, the after callbacks never get called. To work around that
  # issue, we intercept all exceptions raised by the Capistrano tasks and
  # cleanup the lock file as appropriate.
  def execute_requested_actions_with_lock_cleanup(config)
    begin
      execute_requested_actions_without_lock_cleanup(config)
    rescue => e
      # Only cleanup the lock file if the lock file was created during this
      # capistrano run (since we don't want to remove it if the error being
      # raised is actually the error about the lock file existing).
      if(config.fetch(:cleanup_lock_on_error, false))
        config.find_and_execute_task("deploy:unlock")
      end

      raise e
    end
  end

  alias_method :execute_requested_actions_without_lock_cleanup, :execute_requested_actions
  alias_method :execute_requested_actions, :execute_requested_actions_with_lock_cleanup
end


Capistrano::Configuration.instance(true).load do
  #
  # Variables
  #
  _cset(:lock_file) { File.join(shared_path, "DEPLOY_LOCKED") }

  #
  # Hooks
  #
  before "deploy", "deploy:lock"
  before "deploy:cold", "deploy:lock"
  after "deploy", "deploy:unlock"
  after "deploy:cold", "deploy:unlock"

  #
  # Tasks
  #
  namespace :deploy do
    task :lock, :except => { :no_release => true } do
      if(!exists?(:deploy_via) || deploy_via != "single_checkout_no_update")
        run "#{try_sudo} mkdir -p #{File.dirname(lock_file)}"

        if(remote_file_exists?(lock_file))
          lock_info = capture("stat -c '%y' #{lock_file}; cat #{lock_file}").strip.split("\n")
          lock_time = Time.parse(lock_info[0])
          lock_user = lock_info[1]

          raise Capistrano::Error, <<-eos

##### ERROR: DEPLOYMENT LOCKED #####

Another deployment is already in progress. Please wait until that deployment
finishes.

    Lock file created: #{lock_time} by #{lock_user}

    Note: If you believe this is an error, first make sure all capistrano
    processes are in fact killed (both locally and remotely). Then you may run:

    cap ENVIRONMENT deploy:unlock
          eos
        else
          set :cleanup_lock_on_error, true
          put(user, lock_file)
        end
      end
    end

    task :unlock, :except => { :no_release => true } do
      run "#{try_sudo} rm -f #{lock_file}"
    end
  end
end

