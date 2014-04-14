Capistrano::Configuration.instance(true).load do
  #
  # Varabiles
  #

  # Setup any shared files that should be kept between deployments.
  set :shared_children_files, %w()

  #
  # Hooks
  #
  after "deploy:setup", "deploy:shared_children_file_tasks:setup"
  after "deploy:finalize_update", "deploy:shared_children_file_tasks:finalize_update"

  #
  # Tasks
  #
  namespace :deploy do
    namespace :shared_children_file_tasks do
      task :setup, :except => { :no_release => true } do
        dirs = shared_children_files.collect { |file| File.join(shared_path, File.dirname(file)) }
        dirs.uniq!

        if(dirs.any?)
          run "#{try_sudo} mkdir -p #{dirs.join(' ')} && #{try_sudo} chmod g+w #{dirs.join(' ')}"
        end
      end

      task :finalize_update, :except => { :no_release => true } do
        commands = []
        shared_children_files.each do |shared_file|
          commands << "rm -f #{latest_release}/#{shared_file}"
          commands << "touch #{shared_path}/#{shared_file}"
          commands << "ln -s #{shared_path}/#{shared_file} #{latest_release}/#{shared_file}"
        end

        run commands.join(" && ")
      end
    end
  end
end
