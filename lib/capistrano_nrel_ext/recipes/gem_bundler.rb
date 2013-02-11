require "capistrano_nrel_ext/recipes/shared_children"

Capistrano::Configuration.instance(true).load do
  #
  # Varabiles
  #
  set :gem_bundler_apps, []

  set(:all_gem_bundler_apps) do
    all_apps = gem_bundler_apps

    if(exists?(:rails_apps))
      all_apps += rails_apps.collect { |app| app[:path] }
    end

    all_apps
  end

  _cset :bundle_gemfile, "Gemfile"
  _cset :bundle_dir, "vendor/bundle"
  _cset :bundle_cmd, "bundle"

  _cset(:bundle_without) do
    if(stage == :development)
      []
    else
      [:development, :test]
    end
  end

  _cset(:bundle_flags) do
    if(stage == :development)
      ""
    else
      "--deployment"
    end
  end

  set(:gem_bundler_shared_children_dirs) do
    unless bundle_dir.to_s.empty?
      bundle_dir
    else
      []
    end
  end

  set :bundle_exec, lambda { "#{bundle_cmd} exec" }

  #
  # Hooks
  #
  after "deploy:update_code", "deploy:gem_bundler:install"

  #
  # Dependencies
  #
  depend(:remote, :gem, "bundler", ">= 1.0.0")
  depend(:remote, :command, "bundle")

  #
  # Tasks
  #
  namespace :deploy do
    namespace :gem_bundler do
      send :desc, <<-DESC
        Install the current Bundler environment. This is based on Bundler's \
        own capistrano task, but customized to handle our multiple \
        applications in a single deployment.

        By default, gems will be installed to the shared/bundle path. Gems in \
        the development and test group will not be installed. The install \
        command is executed with the --deployment and --quiet flags. If the \
        bundle cmd cannot be found then you can override the bundle_cmd \
        variable to specifiy which one it should use.

        You can override any of these defaults by setting the variables shown below.

          set :bundle_gemfile,  "Gemfile"
          set :bundle_dir,      File.join(fetch(:shared_path), 'bundle')
          set :bundle_flags,    "--deployment --quiet"
          set :bundle_without,  [:development, :test]
          set :bundle_cmd,      "bundle" # e.g. "/opt/ruby/bin/bundle"
      DESC
      task :install, :except => { :no_release => true } do
        # Gather all the paths for bundler applications.
        gem_bundler_paths = all_gem_bundler_apps.collect do |application_path|
          File.join(latest_release, application_path)
        end

        gem_bundler_paths.each do |full_application_path|
          gemfile_path = File.join(full_application_path, bundle_gemfile)

          if(remote_file_exists?(gemfile_path))
            args = ["--gemfile #{gemfile_path}"]
	    if bundle_dir.to_s.empty?
              args << "--system" 
            else
              args << "--path #{File.join(latest_release, bundle_dir)}" 
            end
            args << bundle_flags.to_s
            args << "--without #{bundle_without.compact.join(" ")}" unless bundle_without.empty?

            run "cd #{full_application_path} && #{bundle_cmd} install #{args.join(' ')}"
          end
        end
      end
    end
  end
end
