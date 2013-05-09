require "capistrano_nrel_ext/recipes/shared_children"

Capistrano::Configuration.instance(true).load do
  #
  # Varabiles
  #
  set :npm_apps, []

  set(:npm_shared_children_dirs) do
    dirs = []
    npm_apps.each do |app|
      # FIXME? We can't share node installs across deployments currently due to
      # git dependencies not updating:
      # https://github.com/isaacs/npm/issues/1727
      # So slower deployments for now...
      # dirs << File.join(app, "node_modules")
    end

    dirs
  end

  #
  # Hooks
  #
  after "deploy:update_code", "deploy:npm:install"

  #
  # Dependencies
  #
  depend(:remote, :command, "npm")

  #
  # Tasks
  #
  namespace :deploy do
    namespace :npm do
      send :desc, <<-DESC
        Install npm modules for Node.js apps.
      DESC
      task :install, :except => { :no_release => true } do
        # Gather all the paths for npm applications.
        npm_paths = npm_apps.collect do |application_path|
          File.join(latest_release, application_path)
        end

        npm_paths.each do |full_application_path|
          run "cd #{full_application_path} && npm install"
        end
      end
    end
  end
end
