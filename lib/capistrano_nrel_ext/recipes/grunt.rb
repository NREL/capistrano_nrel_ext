require "capistrano_nrel_ext/recipes/npm"

# Ensure that bower and gem's callbacks get handled before grunt's, so those
# dependencies will be in place in case grunt needs those dependencies (bower
# for assets, gems for potential compass integration). If bower or gems aren't
# used by this grunt task, then including them should do nothing.
require "capistrano_nrel_ext/recipes/bower"
require "capistrano_nrel_ext/recipes/gem_bundler"

Capistrano::Configuration.instance(true).load do
  #
  # Varabiles
  #
  set :grunt_apps, []

  #
  # Hooks
  #
  after "deploy:update_code", "deploy:grunt:build"

  #
  # Tasks
  #
  namespace :deploy do
    namespace :grunt do
      send :desc, <<-DESC
        Perform the 'build' action from grunt.
      DESC
      task :build, :except => { :no_release => true } do
        env = ""
        if(exists?(:rails_env))
          env = "NODE_ENV=#{rails_env}"
        end

        # Gather all the paths for grunt applications.
        grunt_paths = grunt_apps.collect do |application_path|
          File.join(latest_release, application_path)
        end

        grunt_paths.each do |full_application_path|
          run "cd #{full_application_path} && #{env} ./node_modules/.bin/grunt build"
        end
      end
    end
  end
end
