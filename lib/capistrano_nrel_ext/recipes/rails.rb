require "capistrano_nrel_ext/actions/remote_tests"

Capistrano::Configuration.instance(true).load do
  #
  # Varabiles
  #
  set :rails_applications, []

  set :sub_rails_applications, {}

  set(:all_rails_applications) do
    all = {}

    rails_applications.each do |application_path|
      all[application_path] = "/"
    end

    all.merge!(sub_rails_applications)

    all
  end

  # Set the paths to any rails applications that are part of this project. The
  # key of this hash is the path, relative to latest_release, of the rails
  # application. The value of the hash is the public path this application should
  # be deployed to.
  set :rails_applications, {}

  # Setup any shared folders that should be kept between deployments inside a
  # Rails application.
  set :rails_shared_children, %w(log tmp/pids vendor/bundle public/javascripts/compiled)

  # Set any folders or files that need to be writable by the Apache user inside
  # every Rails application. Since this applies to every Rails application, the
  # project-specific "writable_children" configuration option should be used for
  # any special cases where additional folders need to be writable inside
  # specific Rails applications.
  set :rails_writable_children, %w(log tmp public)

  # Set the default Rails environment.
  set :rails_env, "development"

  #
  # Hooks
  #
  after "deploy:setup", "deploy:rails:setup"
  after "deploy:finalize_update", "deploy:rails:finalize_update"
  after "deploy:update_code", "deploy:rails:symlink_public_directories"
  after "deploy:update_code", "deploy:rails:gems:install"
  after "deploy:update_code", "deploy:rails:finalize_permissions"

  #
  # Dependencies
  #

  # For Passenger and Monit, this ruby_env_wrapper script needs to be in place
  # for Oracle compatibility.
  # depend(:remote, :file, "/usr/bin/ruby_env_wrapper")

  # The daemons gem is needed for the delayed_job scripts to run.
  #depend(:remote, :gem, "daemons", ">= 1.0.10")

  #
  # Tasks
  #
  namespace :deploy do
    task :cold do
      update
      schema_load
      start
    end

    task :schema_load, :roles => :db, :only => { :primary => true } do
      all_rails_applications.each do |application_path, public_path|
        rake = fetch(:rake, "rake")
        app_directory = File.join(latest_release, application_path)

        if(remote_file_exists?(File.join(app_directory, "Gemfile")))
          bundle_exec = fetch(:bundle_exec, "")
          rake = "#{bundle_exec} rake"
        end

        run "cd #{app_directory}; #{rake} RAILS_ENV=#{rails_env}_migrations db:schema:load"
      end
    end

    namespace :rails do
      task :setup, :except => { :no_release => true } do
        dirs = []
        all_rails_applications.each do |application_path, public_path|
          rails_shared_children.each do |shared_dir|
            dirs << File.join(shared_path, application_path, shared_dir)
          end
        end

        if(dirs.any?)
          run "#{try_sudo} mkdir -p #{dirs.join(' ')} && #{try_sudo} chmod g+w #{dirs.join(' ')}"
        end
      end

      task :finalize_update, :except => { :no_release => true } do
        all_rails_applications.each do |application_path, public_path|
          rails_shared_children.each do |shared_dir|
            run "mkdir -p #{File.join(shared_path, application_path, shared_dir)} && " +
              "rm -rf #{File.join(latest_release, application_path, shared_dir)} && " +
              "mkdir -p #{File.dirname(File.join(latest_release, application_path, shared_dir))} && " +
              "ln -s #{File.join(shared_path, application_path, shared_dir)} #{File.join(latest_release, application_path, shared_dir)}"
          end
        end
      end

      task :finalize_permissions, :except => { :no_release => true } do
        all_rails_applications.each do |application_path, public_path|
          # Files and folders that need to be writable by the web server
          # (www-data user) will need to be writable by everyone.
          begin
            # Try changing the permissions in both the release directory and the
            # shared directory, since chmod won't recursively follow symlinks.
            dirs = rails_writable_children.collect { |d| File.join(latest_release, application_path, d) } + 
              rails_writable_children.collect { |d| File.join(shared_path, application_path, d) }

            if(dirs.any?)
              run "chmod -Rf o+w #{dirs.join(" ")}"
            end
          rescue Capistrano::CommandError
          end
        end
      end

      task :symlink_public_directories, :except => { :no_release => true } do
        sub_rails_applications.each do |application_path, public_path|
          run("ln -fs #{File.join(latest_release, application_path, "public")} #{File.join(latest_release, "public", public_path)}")
        end
      end

      task :restart, :roles => :app, :except => { :no_release => true } do
        all_rails_applications.each do |application_path, public_path|
          run("touch #{File.join(current_release, application_path, "tmp", "restart.txt")}")
        end
      end

      namespace :gems do
        task :install, :except => { :no_release => true } do
          all_rails_applications.each do |application_path, public_path|
            rake = fetch(:rake, "rake")
            app_directory = File.join(latest_release, application_path)

            if(remote_file_exists?(File.join(app_directory, "Rakefile")))
              if(remote_file_exists?(File.join(app_directory, "Gemfile")))
                bundle_exec = fetch(:bundle_exec, "")
                rake = "#{bundle_exec} rake"
              end

              # Only run the old gem install command if no Gemfile exists.
              if(!remote_file_exists?(File.join(latest_release, application_path, "Gemfile")))
                run "cd #{File.join(latest_release, application_path)} && " +
                  "RAILS_ENV=#{rails_env} #{rake} gems:install && " +
                  "RAILS_ENV=#{rails_env} #{rake} gems:unpack:dependencies && " +
                  "RAILS_ENV=#{rails_env} #{rake} gems:build"
              end
            end
          end
        end
      end
    end
  end
end
