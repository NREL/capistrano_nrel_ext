Capistrano::Configuration.instance(true).load do
  #
  # Hooks
  #
  after "deploy:finalize_update", "deploy:shared_children:finalize_update"

  #
  # Tasks
  #
  namespace :deploy do
    namespace :shared_children do
      task :finalize_update, :except => { :no_release => true } do
        shared_children.each do |shared_dir|
          begin
            # The log folder should be shared between deployments.
            run "rm -rf #{latest_release}/#{shared_dir} && " +
              "ln -s #{shared_path}/#{shared_dir} #{latest_release}/#{shared_dir}"
          rescue Capistrano::CommandError
          end
        end
      end
    end
  end
end
