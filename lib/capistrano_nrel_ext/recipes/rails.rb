require "capistrano_nrel_ext/actions/install_deploy_files"
require "capistrano_nrel_ext/actions/remote_tests"
require "capistrano_nrel_ext/recipes/shared_children"

Capistrano::Configuration.instance(true).load do
  #
  # Varabiles
  #

  # Set the paths to any rails applications that are part of this project. The
  # key of this hash is the path, relative to latest_release, of the rails
  # application. The value of the hash is the public path this application should
  # be deployed to.
  set :rails_app_paths, {}

  set(:rails_apps) do
    apps = []

    rails_app_paths.each do |app_path, base_uri|
      # Come up with a unique name for this application, suitable for use in
      # file names.
      app_name = app_path.gsub(%r{(^/|/$)}, "").gsub(/[\/\.]/, "-")
      if(app_name.empty?)
        app_name = "app"
      end

      apps << {
        :name => "#{deploy_name}-#{app_name}".gsub(/-+/, "-").gsub(/-$/, ""),
        :path => app_path,
        :current_path => File.expand_path(File.join(current_path, app_path)),
        :base_uri => base_uri,
      }
    end

    apps
  end

  # Setup any shared folders that should be kept between deployments inside a
  # Rails application.
  set :rails_shared_children, %w(log tmp/pids)

  set(:rails_shared_children_dirs) do
    dirs = []

    rails_apps.each do |app|
      rails_shared_children.each do |shared_dir|
        dirs << File.join(app[:path], shared_dir)
      end
    end

    dirs
  end

  # Set any folders or files that need to be writable by the web server user
  # inside every Rails application. Since this applies to every Rails
  # application, the global "writable_children_dirs" configuration option
  # should be used for any special cases where additional folders need to be
  # writable inside specific Rails applications.
  #
  # public is writable for Rails page caching.
  set :rails_writable_children, %w(log tmp tmp/cache public)

  set(:rails_writable_children_dirs) do
    dirs = []

    rails_apps.each do |app|
      rails_writable_children.each do |writable_dir|
        dirs << File.join(app[:path], writable_dir)
      end
    end

    dirs
  end

  # Set the default Rails environment.
  set :rails_env, "development"

  set :rails_auto_migrate, true
  set :rails_migrate_task, "db:migrate"
  set(:rails_migrate_env) { rails_env }

  set :rails_auto_seed, true
  set :rails_seed_task, "db:seed"
  set(:rails_seed_env) { rails_env }

  #
  # Hooks
  #
  after "deploy:update_code", "deploy:rails:config"
  before "deploy:start", "deploy:rails:auto_migrate"
  before "deploy:restart", "deploy:rails:auto_migrate"
  before "deploy:start", "deploy:rails:auto_seed"
  before "deploy:restart", "deploy:rails:auto_seed"

  #
  # Tasks
  #
  namespace :deploy do
    namespace :rails do
      desc <<-DESC
        Create any Rails configuration files.
      DESC
      task :config, :roles => :app, :except => { :no_release => true } do
        files = []
        rails_apps.each do |app|
          files << File.join(app[:path], "config/database.yml")
          files << File.join(app[:path], "config/elasticsearch.yml")
          files << File.join(app[:path], "config/mongoid.yml")
        end

        install_deploy_files(files)

        # Ensure the Rails log file gets created and is writable by the web
        # server user and deploy group.
        log = File.join(latest_release, "log/#{rails_env}.log")
        commands = ["touch #{log}"]

        if(file_system_acl_support)
          commands << "setfacl -m 'u:#{web_server_user}:rwx' #{log}"
        end

        if(fetch(:group_writable, true))
          if(exists?(:group))
            commands << "chgrp -R #{group} #{log}"
          end

          commands << "chmod g+w #{log}"
        end

        run commands.join(" && ")
      end

      task :auto_migrate, :roles => :migration, :except => { :no_release => true } do
        if(rails_auto_migrate)
          deploy.rails.migrate
        end
      end

      desc <<-DESC
        Run the migrate rake task.
      DESC
      task :migrate, :roles => :migration, :except => { :no_release => true } do
        rails_apps.each do |app|
          app_directory = File.expand_path(File.join(latest_release, app[:path]))

          env = "RAILS_ENV=#{rails_migrate_env}"
          run "cd #{app_directory}; #{bundle_exec} #{rake} #{env} #{rails_migrate_task}"
        end
      end

      task :auto_seed, :roles => :migration, :except => { :no_release => true } do
        if(rails_auto_seed)
          deploy.rails.seed
        end
      end

      desc <<-DESC
        Run the seed rake task.
      DESC
      task :seed, :roles => :migration, :except => { :no_release => true } do
        rails_apps.each do |app|
          app_directory = File.expand_path(File.join(latest_release, app[:path]))

          env = "RAILS_ENV=#{rails_seed_env}"
          run "cd #{app_directory}; #{bundle_exec} #{rake} #{env} #{rails_seed_task}"
        end
      end
    end

    task :cold do
      update
      schema_load
      start
    end

    task :schema_load, :roles => :migration, :except => { :no_release => true } do
      rails_apps.each do |app|
        app_directory = File.expand_path(File.join(latest_release, app[:path]))

        env = "RAILS_ENV=#{rails_migrate_env}"
        run "cd #{app_directory}; #{bundle_exec} #{rake} #{env} db:schema:load"
      end
    end
  end
end
