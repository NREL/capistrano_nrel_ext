Capistrano::Configuration.instance(true).load do
  #
  # Varabiles
  #
  set :gem_bundler_apps, []

  #
  # Hooks
  #
  after "deploy:update_code", "deploy:gem_bundler:install"

  #
  # Tasks
  #
  namespace :deploy do
    namespace :gem_bundler do
      task :install, :except => { :no_release => true } do
        gem_bundler_paths = gem_bundler_apps.collect do |application_path|
          File.join(latest_release, application_path)
        end

        if(exists?(:all_rails_applications))
          gem_bundler_paths += all_rails_applications.collect do |application_path, public_path|
            File.join(latest_release, application_path)
          end
        end

        gem_bundler_paths.each do |application_path|
          if(remote_file_exists?(File.join(application_path, "Gemfile")))
            run "cd #{application_path} && " +
              "mkdir -p #{application_path}/vendor && " +
              "bundle install vendor/bundle"
          end
        end
      end
    end
  end
end
