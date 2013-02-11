require "capistrano_nrel_ext/actions/remote_tests"
require "capistrano_nrel_ext/recipes/gem_bundler"
require "capistrano_nrel_ext/recipes/rails"

Capistrano::Configuration.instance(true).load do
  #
  # Varabiles
  #
  _cset :asset_pipeline_env, "RAILS_GROUPS=assets"
  _cset :asset_pipeline_role, [:web]
  _cset :asset_pipeline_dir, "public/assets"

  #
  # Hooks
  #
  after "deploy:update_code", "deploy:asset_pipeline:precompile"

  namespace :deploy do
    namespace :asset_pipeline do
      desc <<-DESC
        Run the asset precompilation rake task. You can specify the full path \
        to the rake executable by setting the rake variable. You can also \
        specify additional environment variables to pass to rake via the \
        asset_pipeline_env variable. The defaults are:

          set :rake,      "rake"
          set :rails_env, "production"
          set :asset_pipeline_env, "RAILS_GROUPS=assets"
      DESC
      task :precompile, :roles => asset_pipeline_role, :except => { :no_release => true } do
        if(rails_env != "development")
          commands = []
          rails_apps.each do |app|
            full_application_path = File.join(latest_release, app[:path])

            if(remote_file_contains?(File.join(full_application_path, "Gemfile"), "group :assets"))
              turbo_sprockets = remote_file_contains?(File.join(full_application_path, "Gemfile.lock"), "turbo-sprockets")

              # If turbo sprockets is being used, copy the previous assets into
              # the current deployment's directory so they can be used as a
              # cache.
              if(turbo_sprockets && previous_release)
                previous_assets_path = File.join(previous_release, app[:path], asset_pipeline_dir)
                new_assets_path = File.join(full_application_path, asset_pipeline_dir)
                commands << "cp -pr #{previous_assets_path} #{new_assets_path}"
              end

              relative_url_env = ""
              if(!app[:base_uri].to_s.empty? && app[:base_uri] != "/")
                relative_url_env = "RAILS_RELATIVE_URL_ROOT=#{app[:base_uri].inspect}"
              end

              commands << "cd #{full_application_path}"
              commands << "#{bundle_exec} #{rake} RAILS_ENV=#{rails_env} #{relative_url_env} #{asset_pipeline_env} assets:precompile"

              # If turbo sprockets is being used, expire any old assets, so the
              # assets folder doesn't grow indefinitely.
              if(turbo_sprockets)
                commands << "#{bundle_exec} #{rake} RAILS_ENV=#{rails_env} #{relative_url_env} #{asset_pipeline_env} assets:clean_expired"
              end
            end
          end

          if commands.any?
            run commands.join(" && ")
          end
        end
      end

      desc <<-DESC
        Run the asset clean rake task. Use with caution, this will delete \
        all of your compiled assets. You can specify the full path \
        to the rake executable by setting the rake variable. You can also \
        specify additional environment variables to pass to rake via the \
        asset_pipeline_env variable. The defaults are:

          set :rake,      "rake"
          set :rails_env, "production"
          set :asset_pipeline_env, "RAILS_GROUPS=assets"
      DESC
      task :clean, :roles => asset_pipeline_role, :except => { :no_release => true } do
        rails_apps.each do |app|
          full_application_path = File.join(latest_release, app[:path])

          if(remote_file_contains?(File.join(full_application_path, "Gemfile"), "group :assets"))
            run "cd #{full_application_path} && #{rake} RAILS_ENV=#{rails_env} #{asset_pipeline_env} assets:clean"
          end
        end
      end
    end
  end
end
