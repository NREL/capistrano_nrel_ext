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
      app_name = app_path.gsub(%r{(^/|/$)}, "").gsub("/", "_")
      if(app_name.empty?)
        app_name = "app"
      end

      apps << {
        :name => "#{deploy_name}-#{app_name}",
        :path => app_path,
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

  # Set any folders or files that need to be writable by the Apache user inside
  # every Rails application. Since this applies to every Rails application, the
  # project-specific "writable_children_dirs" configuration option should be
  # used for any special cases where additional folders need to be writable
  # inside specific Rails applications.
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
      rails_apps.each do |app|
        rake = fetch(:rake, "rake")
        app_directory = File.join(latest_release, app[:path])

        if(remote_file_exists?(File.join(app_directory, "Gemfile")))
          bundle_exec = fetch(:bundle_exec, "")
          rake = "#{bundle_exec} rake"
        end

        env = "RAILS_ENV=#{rails_env}_migrations"

        run "cd #{app_directory}; #{env} #{rake} db:schema:load"
      end
    end
  end
end
