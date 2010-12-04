Capistrano::Configuration.instance(true).load do
  #
  # Varabiles
  #
  set :gem_bundler_apps, []

  #
  # Hooks
  #
  after "deploy:update_code", "deploy:gem_bundler:install"

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
        # Gather all the paths specifically defined as Bundler apps.
        gem_bundler_paths = gem_bundler_apps.collect do |application_path|
          File.join(latest_release, application_path)
        end

        # Also add all the paths to Rails apps that might use Bundler.
        if(exists?(:all_rails_applications))
          gem_bundler_paths += all_rails_applications.collect do |application_path, public_path|
            File.join(latest_release, application_path)
          end
        end

        bundle_cmd     = fetch(:bundle_cmd, "bundle")
        bundle_flags   = fetch(:bundle_flags, "--deployment --quiet")
        bundle_gemfile = fetch(:bundle_gemfile, "Gemfile")
        bundle_without = [*fetch(:bundle_without, [:development, :test])].compact

        gem_bundler_paths.each do |full_application_path|
          gemfile_path = File.join(full_application_path, bundle_gemfile)

          if(remote_file_exists?(gemfile_path))
            bundle_dir     = fetch(:bundle_dir, File.join(full_application_path, "vendor", "bundle"))

            args = ["--gemfile #{gemfile_path}"]
            args << "--path #{bundle_dir}" unless bundle_dir.to_s.empty?
            args << bundle_flags.to_s
            args << "--without #{bundle_without.join(" ")}" unless bundle_without.empty?

            run "#{bundle_cmd} install #{args.join(' ')}"
          end
        end
      end
    end
  end
end
