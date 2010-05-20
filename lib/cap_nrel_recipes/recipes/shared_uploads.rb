Capistrano::Configuration.instance(true).load do
  #
  # Variables
  #
  set(:shared_uploads_path) { File.join(deploy_to_base, "shared_uploads", "current") }

  # Setup any folders where uploaded content will go. The content needs to be
  # kept between deployments, and we also want the ability to check the content
  # into a subversion repository.
  set :upload_children, %w()

  #
  # Hooks
  #
  after "deploy:finalize_update", "deploy:shared_uplaods:finalize_update"

  #
  # Tasks
  #
  namespace :deploy do
    namespace :finalize_update do
      task :finalize_update, :except => { :no_release => true } do
        upload_children.each do |upload_dir|
          begin
            # The log folder should be shared between deployments.
            run "rm -rf #{latest_release}/#{upload_dir} && " +
              "mkdir -p #{shared_uploads_path}/public/#{stage} && " +
              "ln -s #{shared_uploads_path}/public/#{stage} #{latest_release}/#{upload_dir}"
          rescue Capistrano::CommandError
          end

          writable_children << File.join(shared_uploads_path, "public", stage.to_s, upload_dir)
        end
      end
    end
  end
end
