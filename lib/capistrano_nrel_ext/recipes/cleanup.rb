require "artii"

Capistrano::Configuration.instance(true).load do
  #
  # Hooks
  #

  # Cleanup after deployment so we only keep a few of the latest releases around.
  after "deploy", "deploy:try_cleanup"

  # Show a success message after a full deployment.
  after "deploy", "deploy:success_message"

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
        # the command using sudo. If this still fails, we don't care too much.
        # The problem files will just sit around for a while until someone with
        # sudo access does a deployment.
        begin
          set :run_method, :sudo
          deploy.cleanup
          set :run_method, :run
        rescue Capistrano::CommandError
        end
      end
    end

    # Show a clear success message after a full deployment. This is mostly to
    # clarify that any rm errors showing up from the cleanup task still mean the
    # deploy succeeded.
    task :success_message, :except => { :no_release => true } do
      logger.info("\n\nYour deployment to #{stage} has succeeded.\n\n\n")

      # A silly banner, because its fun.
      banner = Artii::Base.new(:font => "big")
      puts banner.asciify("Deployment")
      puts banner.asciify("Success!!")
    end
  end
end
