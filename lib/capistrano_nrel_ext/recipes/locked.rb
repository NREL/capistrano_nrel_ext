require "time"

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
          put(user, lock_file)
        end
      end
    end

    task :unlock, :except => { :no_release => true } do
      run "#{try_sudo} rm -f #{lock_file}"
    end
  end
end

