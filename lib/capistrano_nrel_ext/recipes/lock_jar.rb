require "capistrano_nrel_ext/recipes/gem_bundler"

Capistrano::Configuration.instance(true).load do
  #
  # Varabiles
  #
  set :lock_jar_apps, []

  set(:all_lock_jar_apps) do
    all_apps = lock_jar_apps

    if(exists?(:rails_apps))
      all_apps += rails_apps.collect { |app| app[:path] }
    end

    all_apps.uniq!
    all_apps
  end

  _cset :lock_jar_jarfile, "Jarfile"
  _cset :lock_jar_dir, "vendor/lock_jar"

  set(:lock_jar_shared_children_dirs) do
    unless lock_jar_dir.to_s.empty?
      [lock_jar_dir]
    else
      []
    end
  end

  #
  # Hooks
  #
  after "deploy:update_code", "deploy:lock_jar:install"

  #
  # Tasks
  #
  namespace :deploy do
    namespace :lock_jar do
      task :install, :except => { :no_release => true } do
        all_lock_jar_apps.each do |application_path|
          full_application_path = File.expand_path(File.join(latest_release, application_path))
          jarfile_path = File.join(full_application_path, lock_jar_jarfile)

          if(remote_file_exists?(jarfile_path))
            env = "M2_REPO=#{lock_jar_dir}"
            run "cd #{full_application_path} && #{env} #{bundle_exec} lockjar install"
          end
        end
      end
    end
  end
end
