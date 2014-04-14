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
      if(!exists?(:rails_env) || rails_env != "development")
        run "#{try_sudo} mkdir -p #{File.dirname(lock_file)}"

        if(remote_file_exists?(lock_file))
          lock_info = capture("stat -c '%z by %U' #{lock_file}").strip

          raise Capistrano::Error, <<-eos

##### ERROR: DEPLOYMENT LOCKED #####

Another deployment is already in progress. Please wait until that deployment
finishes.

    Lock file created: #{lock_info}

    Note: If you believe this is an error, first make sure all capistrano
    processes are in fact killed (both locally and remotely). Then you may run:

    cap ENVIRONMENT deploy:unlock
          eos
        else
          put("true", lock_file)
        end
      end
    end

    task :unlock, :except => { :no_release => true } do
      run "#{try_sudo} rm -f #{lock_file}"
    end
  end
end

