Capistrano::Configuration.instance(true).load do
  # Provide a way to remove deployed branches or sandboxes in the testing or
  # development environment.
  namespace :undeploy do
    desc <<-DESC
      Undeploy and completely remove a deployment. This should only be run if
      you're cleaning up unused sandboxes or branches.
    DESC
    task :default do
      # Never run an undeploy on the production server.
      if(stage == :production)
        abort("This should not be run on the production server")
      end

      confirm = Capistrano::CLI.ui.ask("Are you sure you would like to completely remove the deployment from:\n#{deploy_to}? (y/n) ") do |q|
        q.default = "n"
      end.downcase

      if(confirm == "y")
        apache.delete
        delete

        # Restart Apache after the configuration file has been removed.
        deploy.apache.restart
      end
    end

    # Remove the entire deploy_to directory.
    task :delete do
      delete_command = "rm -rf #{deploy_to}"

      begin
        run(delete_command)
      rescue Capistrano::CommandError
        begin
          sudo(delete_command)
        rescue Capistrano::CommandError
        end
      end
    end

    namespace :apache do
      # Remove the symbolic link to the apache configuration file that's in
      # place for this deployment.
      task :delete do
        run "rm -f #{apache_conf_dir}/sites/#{deploy_name}.conf"
      end
    end
  end
end
