require "pathname"

Capistrano::Configuration.instance(true).load do
  #
  # Varabiles
  #
  set :writable_children_dirs, []

  set(:all_writable_children_dirs) do
    all_paths = writable_children_dirs

    if(exists?(:rails_writable_children_dirs))
      all_paths += rails_writable_children_dirs
    end

    all_paths
  end

  #
  # Hooks
  #
  before "deploy:create_symlink", "deploy:finalize_permissions"

  #
  # Dependencies
  #
  depend(:remote, :command, "setfacl")

  #
  # Tasks
  #
  namespace :deploy do
    # Make everything writable at a later stage in deployment than normal, so
    # any generated files can also be handled.
    task :finalize_permissions, :except => { :no_release => true } do
      commands = []

      # Try to make everything group writable.
      if(fetch(:group_writable, true))
        base_path = Pathname.new(deploy_to_base).expand_path
        path = Pathname.new(deploy_to).expand_path

        # Catch all the subdirectories possibly between the deploy_to_base and
        # deploy_to paths, and make them all group writable.
        #
        # We don't just recursively change deploy_to, since that would keep
        # change the permissions for all old releases, which slows things down
        # for big deployments.
        nonrecursive_paths = [base_path, releases_path]
        while(path != base_path && path.to_s != "/" )
          nonrecursive_paths << path
          path = path.parent
        end

        nonrecursive_paths.each do |path|
          if(exists?(:group))
            commands << "chgrp #{group} #{path}"
          end

          commands << "chmod g+w #{path}"
        end

        recursive_paths = [latest_release]
        recursive_paths.each do |path|
          if(exists?(:group))
            commands << "chgrp -R #{group} #{path}"
          end

          commands << "chmod -R g+w #{path}"
        end
      end

      if(commands.any?)
        run(commands.join(" && "))
      end

      # Files and folders that need to be writable by the web server
      # (www-data user) will need to be writable by everyone.
      #
      # Try changing the permissions in both the release directory and the
      # shared directory, since chmod won't recursively follow symlinks.
      if(file_system_acl_support)
        dirs = all_writable_children_dirs.collect { |d| File.expand_path(File.join(latest_release, d)) } +
          all_writable_children_dirs.collect { |d| File.expand_path(File.join(shared_path, d)) } +
          writable_paths
        if(dirs.any?)
          run "setfacl -R -m 'u:#{web_server_user}:rwx' #{dirs.join(" ")} &> /dev/null; true"
        end
      end
    end
  end
end

