Capistrano::Configuration.instance(true).load do
  #
  # Hooks
  #

  # Cleanup after deployment so we only keep a few of the latest releases around.
  after "deploy", "deploy:try_cleanup"

  #
  # Tasks
  #
  namespace :deploy do
    # We'll try to run cleanup after a deployment. But this might fail if the
    # deployment contains files that are owned by www-data (such as Rails cache
    # files). Try to gracefully handle those errors.
    task :try_cleanup, :except => { :no_release => true } do
      begin
        deploy.cleanup
      rescue Capistrano::CommandError
        # If a cleanup failed, it was probably permission errors. Try rerunning
        # the command as the web server user.
        begin
          original_run_method = fetch(:run_method)
          original_as = fetch(:as)
          set :run_method, :sudo
          set :as, web_server_user

          deploy.cleanup

          set :run_method, original_run_method
          set :as, original_as
        rescue Capistrano::CommandError
          # Now that all the web user files should be deleted, let's try
          # cleanup one final time.
          deploy.cleanup
        end
      end
    end
  end
end
