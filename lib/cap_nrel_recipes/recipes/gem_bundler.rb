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
        gem_bundler_apps.each do |app_path|
          run "cd #{File.join(latest_release, app_path)} && " +
            "bundle install"
        end
      end
    end
  end
end
