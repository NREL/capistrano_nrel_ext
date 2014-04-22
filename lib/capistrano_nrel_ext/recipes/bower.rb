require "capistrano_nrel_ext/recipes/npm"

Capistrano::Configuration.instance(true).load do
  #
  # Varabiles
  #
  set :bower_apps, []
  _cset :bower_cmd, "./node_modules/.bin/bower"
  _cset :bower_flags, ""

  #
  # Hooks
  #
  after "deploy:npm:install", "deploy:bower:install"

  #
  # Tasks
  #
  namespace :deploy do
    namespace :bower do
      send :desc, <<-DESC
        Install bower dependencies.
      DESC
      task :install, :except => { :no_release => true } do
        # Gather all the paths for bower applications.
        bower_paths = bower_apps.collect do |application_path|
          File.join(latest_release, application_path)
        end

        bower_paths.each do |full_application_path|
          run "cd #{full_application_path} && #{bower_cmd} install --config.interactive=false #{bower_flags}"
        end
      end
    end
  end
end
