Capistrano::Configuration.instance(true).load do
  #
  # Variables
  #
  set :servlets_deploy_to, "/var/lib/tomcat6/webapps"

  #
  # Hooks
  #
  after "deploy:update_code", "deploy:servlets:install"

  #
  # Tasks
  #
  namespace :deploy do
    namespace :servlets do
      desc <<-DESC
        Install servlets into Tomcat's apps directory. 
      DESC
      task :install, :except => { :no_release => true } do
        # Only deploy servlets if a "servlets" directory exists in this project's
        # root folder.
        if(remote_directory_exists?(File.join(latest_release, "servlets")))
          # Copy the servlets to the system-wide deployment directory. Only
          # perform the copy for newer files.
          run "cp -R --update #{File.join(latest_release, "servlets", "*")} #{servlets_deploy_to}"

          begin
            run "chmod -Rf g+w #{servlets_deploy_to}"
          rescue Capistrano::CommandError
          end
        end
      end
    end
  end
end
