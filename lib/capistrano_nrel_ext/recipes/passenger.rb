require "capistrano_nrel_ext/recipes/rails"

Capistrano::Configuration.instance(true).load do
  #
  # Variables
  #
  _cset :passenger_symlink_sub_uris, true

  #
  # Hooks
  #
  after "deploy:update_code", "deploy:rails:symlink_public_directories"

  #
  # Tasks
  #
  namespace :deploy do
    namespace :rails do
      task :symlink_public_directories, :except => { :no_release => true } do
        if(passenger_symlink_sub_uris)
          rails_apps.each do |app|
            if(app[:base_uri] != "/")
              run("ln -fs #{File.join(latest_release, app[:path], "public")} #{File.join(latest_release, "public", app[:base_uri])}")
            end
          end
        end
      end

      task :restart, :roles => :app, :except => { :no_release => true } do
        rails_apps.each do |app|
          run("touch #{File.join(current_release, app[:path], "tmp", "restart.txt")}")
        end
      end
    end
  end
end
