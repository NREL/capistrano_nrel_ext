require "cap_nrel_recipes/actions/remote_tests"

Capistrano::Configuration.instance(true).load do
  #
  # Hooks 
  #
  after "deploy:update_code", "deploy:jammit:precache"

  #
  # Dependencies
  #
  depend(:remote, :gem, "jammit", ">= 0.4.4")
  depend(:remote, :command, "jammit")

  #
  # Tasks
  #
  namespace :deploy do
    namespace :jammit do
      desc <<-DESC
        Precache and compress asset files using Jammit.
      DESC
      task :precache, :except => { :no_release => true } do
        # By default, look inside our root application, as well as any Rails
        # applications that might have their own Jammit configuration.
        jammit_paths = [latest_release]
        if(exists?(:all_rails_applications))
          jammit_paths += all_rails_applications.collect do |application_path, public_path|
            File.join(latest_release, application_path)
          end
        end

        # Run the "jammit" command against all the paths that have a config file
        # inside to generate all the pre-cached files.
        jammit_paths.each do |path|
          if(remote_file_exists?(File.join(path, "config", "assets.yml")))
            run "cd #{File.join(path)} && jammit"
          end
        end
      end
    end
  end
end
