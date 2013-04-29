Capistrano::Configuration.instance(true).load do
  #
  # Varabiles
  #
  set :shared_children_dirs, []

  set(:all_shared_children_dirs) do
    all_paths = shared_children_dirs

    if(exists?(:rails_shared_children_dirs))
      all_paths += rails_shared_children_dirs
    end

    if(exists?(:gem_bundler_shared_children_dirs))
      all_paths += gem_bundler_shared_children_dirs
    end

    if(exists?(:npm_shared_children_dirs))
      all_paths += npm_shared_children_dirs
    end

    all_paths
  end

  #
  # Hooks
  #
  after "deploy:setup", "deploy:shared_children_tasks:setup"
  after "deploy:finalize_update", "deploy:shared_children_tasks:finalize_update"

  #
  # Tasks
  #
  namespace :deploy do
    namespace :shared_children_tasks do
      task :setup, :except => { :no_release => true } do
        shared_dirs = all_shared_children_dirs.map { |shared_dir| File.join(shared_path, shared_dir) }
        if(exists?(:disable_internal_symlinks) && disable_internal_symlinks)
          shared_dirs = all_shared_children_dirs.map { |shared_dir| File.join(latest_release, shared_dir) }
        end

        if shared_dirs.any?
          run "#{try_sudo} mkdir -p #{shared_dirs.join(' ')}"
          run "#{try_sudo} chmod g+w #{shared_dirs.join(' ')}" if fetch(:group_writable, true)
        end
      end

      task :finalize_update, :except => { :no_release => true } do
        commands = []

        all_shared_children_dirs.each do |shared_dir|
          shared_dir_path = File.join(shared_path, shared_dir)
          release_dir_path = File.join(latest_release, shared_dir)

          if(!exists?(:disable_internal_symlinks) || !disable_internal_symlinks)
            commands << "rm -rf #{release_dir_path}"
            commands << "mkdir -p #{File.dirname(release_dir_path)}"
            commands << "ln -s #{shared_dir_path} #{release_dir_path}"
          end
        end

        if commands.any?
          run commands.join(" && ")
        end
      end
    end
  end
end
