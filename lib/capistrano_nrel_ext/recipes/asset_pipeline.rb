require "capistrano_nrel_ext/actions/remote_tests"
require "capistrano_nrel_ext/recipes/gem_bundler"
require "capistrano_nrel_ext/recipes/rails"

Capistrano::Configuration.instance(true).load do
  #
  # Varabiles
  #
  _cset :asset_pipeline_env, "RAILS_GROUPS=assets"

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
      task :precompile, :roles => :web, :except => { :no_release => true } do
        all_rails_applications.each do |application_path, public_path|
          full_application_path = File.join(latest_release, application_path)

          if(remote_rake_task_exists?(full_application_path, "assets:precompile"))
            relative_url_env = ""
            if(!public_path.to_s.empty? && public_path != "/")
              relative_url_env = "RAILS_RELATIVE_URL_ROOT=#{public_path.inspect}"
            end

            run "cd #{full_application_path} && #{bundle_exec} #{rake} RAILS_ENV=#{rails_env} #{relative_url_env} #{asset_pipeline_env} assets:precompile"
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
      task :clean, :roles => :web, :except => { :no_release => true } do
        all_rails_applications.each do |application_path, public_path|
          full_application_path = File.join(latest_release, application_path)

          if(remote_rake_task_exists?(full_application_path, "assets:clean"))
            run "cd #{full_application_path} && #{rake} RAILS_ENV=#{rails_env} #{asset_pipeline_env} assets:clean"
          end
        end
      end
    end
  end
end
