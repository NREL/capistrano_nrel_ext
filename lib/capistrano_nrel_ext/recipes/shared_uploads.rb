Capistrano::Configuration.instance(true).load do
  #
  # Variables
  #
  set(:shared_uploads_path) { abort("Please specify the path for shared uploads, set :shared_uploads_path, '/srv/uploads'") }

  # Define the directories where uploaded content will go. This content will be
  # kept between deployments.
  #
  # The keys of this hash define the public locations, relative to the
  # release's root that will be linked to the shared uploads content. The
  # values of the hash define the path inside the `shared_uploads_path` where
  # the key path will be symbolically linked to. An example might make more
  # sense:
  #
  # set :upload_children, {
  #   "public/uploads" => "/",
  #   "public/some/dir" => "/custom/path",
  # }
  #
  # In the deployed release:
  #
  # CURRENT_RELEASE/public/uploads => SHARED_UPLOADS_PATH
  # CURRENT_RELEASE/public/some/dir => SHARED_UPLOADS_PATH/custom/path
  set :upload_children, {}

  #
  # Hooks
  #
  after "deploy:finalize_update", "deploy:shared_uploads:finalize_update"

  #
  # Tasks
  #
  namespace :deploy do
    namespace :shared_uploads do
      task :finalize_update, :except => { :no_release => true } do
        upload_children.each do |public_dir, shared_upload_dir|
          public_install_path = File.join(latest_release, public_dir)
          shared_upload_destination_path = File.join(shared_uploads_path, shared_upload_dir)

          if(exists?(:disable_internal_symlinks) && disable_internal_symlinks)
            run "mkdir -p #{public_install_path} && chmod -R 777 #{public_install_path}"
          else
            # Install the proper symbolic links if they haven't already been
            # setup.
            run <<-CMD
              if [ "`readlink #{public_install_path}`" != "#{shared_upload_destination_path}" ]; then \
                mkdir -p #{shared_upload_destination_path} && \
                chmod -Rf 777 #{shared_upload_destination_path}; \
                rm -rf #{public_install_path} && \
                ln -s #{shared_upload_destination_path} #{public_install_path}; \
              fi
            CMD
          end
        end
      end
    end
  end
end
