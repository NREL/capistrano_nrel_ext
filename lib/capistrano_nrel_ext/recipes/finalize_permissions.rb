Capistrano::Configuration.instance(true).load do
  #
  # Hooks
  #
  after "deploy:update_code", "deploy:finalize_permissions"

  #
  # Tasks
  #
  namespace :deploy do
    # Make everything writable at a later stage in deployment than normal, so
    # any generated files can also be handled.
    task :finalize_permissions, :except => { :no_release => true } do
      # Try to make everything group writable. If any of this fails, we don't
      # care, since it probably means the files are owned by someone else,
      # but should already be setup to be group writable.
      if(fetch(:group_writable, true))
        begin
          # Make the latest release group writable.
          run "chmod -Rf g+w #{latest_release}"
        rescue Capistrano::CommandError
        end

        begin
          # Make all of the shared files group writable. 
          run "chmod -Rf g+w #{shared_path}"
        rescue Capistrano::CommandError
        end
      end

      # Files and folders that need to be writable by the web server
      # (www-data user) will need to be writable by everyone.
      begin
        # Try changing the permissions in both the release directory and the
        # shared directory, since chmod won't recursively follow symlinks.
        dirs = writable_children.collect { |d| File.join(latest_release, d) } + 
          writable_children.collect { |d| File.join(shared_path, d) }

        if(dirs.any?)
          run "chmod -Rf o+w #{dirs.join(" ")}"
        end
      rescue Capistrano::CommandError
      end
    end
  end
end

