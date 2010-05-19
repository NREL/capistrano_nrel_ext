Capistrano::Configuration.instance(true).load do
  #
  # Hooks
  #

  # Always run setup and check before deployment, since it's nondestructive and
  # means one less step.
  before "deploy", "deploy:try_setup", "deploy:check"

  #
  # Tasks
  #
  namespace :deploy do
    # By default, we'll try to run setup, but we don't care if it fails. This
    # probably just means that the deployment has already succeeded once, and
    # things are already setup.
    task :try_setup, :except => { :no_release => true } do
      begin
        deploy.setup
      rescue Capistrano::CommandError
      end
    end
  end
end

