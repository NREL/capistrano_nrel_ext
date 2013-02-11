# Automatically include other common recipes that should be used on all
# servers. These recipes should not require additional dependencies on the
# destination server.
require "capistrano_nrel_ext/recipes/clean_slate"
require "capistrano_nrel_ext/recipes/confirm_updated"
require "capistrano_nrel_ext/recipes/locked"
require "capistrano_nrel_ext/recipes/cleanup"
require "capistrano_nrel_ext/recipes/deployed_config"
require "capistrano_nrel_ext/recipes/finalize_permissions"
require "capistrano_nrel_ext/recipes/setup"
require "capistrano_nrel_ext/recipes/shared_children"
require "capistrano_nrel_ext/recipes/shared_children_files"
require "capistrano_nrel_ext/recipes/undeploy"

Capistrano::Configuration.instance(true).load do
  # Setup default environment variables.
  default_environment["LD_LIBRARY_PATH"] = "/var/lib/instantclient" # For Rails & Oracle
  default_environment["TNS_ADMIN"] = "/var/lib/instantclient" # For Rails & Oracle so it knows where to find the sqlnet.ora file.

  # Use a pseudo terminal so sudo will work on systems with requiretty enabled.
  default_run_options[:pty] = true

  # Don't use sudo.
  set :use_sudo, false

  # Allow deploying as another user (such as for Vagrant boxes where the
  # current user is "vagrant" but we want to deploy as our normal user
  # account).
  if ENV["DEPLOY_USER"]
    set :user, ENV["DEPLOY_USER"]
  end

  # Set a unique name for this deployed application.
  set(:deploy_name) { "#{stage}-#{application}" }
  set(:deploy_release_name) { "#{deploy_name}-#{release_name}" }

  # Our deploy path will be made up of our custom deploy_to_base and
  # deploy_to_subdirectory variables which can be set by other extensions or
  # stage configuration.
  set(:deploy_to_base) { abort("Please specify the base path for your application, set :deploy_to_base, '/srv/sites'") }
  set(:deploy_to_subdirectory) { application } 
  set(:deploy_to) { File.join(deploy_to_base, deploy_to_subdirectory) }

  # Keep a cached checkout on the server so updates are quicker.
  set :deploy_via, :remote_cache

  # Set a friendly release name, where the date and time parts are separated.
  set(:release_name) { set :deploy_timestamped, true; Time.now.utc.strftime("%Y_%m_%d_%H_%M_%S") }

  # Set the default repository path which will check out of trunk.
  set :repository_subdirectory, "trunk"
  set(:repository) { "https://cttssvn.nrel.gov/svn/#{application}/#{repository_subdirectory}" }

  # Set some default for the Apache configuration.
  set :base_domain, ""
  set :subdomain, ""
  set(:domain) { "#{subdomain}#{base_domain}" }

  set :base_domain_aliases, []
  set(:domain_aliases) { base_domain_aliases.collect { |base_alias| "#{subdomain}#{base_alias}" } }

  set(:all_domains) { [domain] + domain_aliases }

  # Don't use Capistrano's default `shared_children` since its somewhat broken
  # for handling nested folders in newer versions:
  # https://github.com/capistrano/capistrano/commit/44e96a4a8b69bd7b8ecf8ad384f12a46a7f3e0df
  set :shared_children, []

  # Setup any shared folders that should be kept between deployments.
  set :shared_children_dirs, %w(log)

  # Set any folders or files that need to be writable by the web user. Children
  # paths are given relative to the release's root.
  set :writable_children_dirs, %w(log)

  # Set any absolute paths that need to be writable by the web user.
  set :writable_paths, []

  namespace :deploy do
    task :update_code, :except => { :no_release => true } do
      # Don't delete the checkout on rollback when there's only a single
      # checkout.
      if(![:single_checkout_no_update].include?(deploy_via))
        on_rollback { run "rm -f #{lock_file}; rm -rf #{release_path}; true" }
      end

      strategy.deploy!
      finalize_update
    end

    alias_task :original_cleanup, :cleanup

    desc <<-DESC
      Clean up old releases. By default, the last 5 releases are kept on each \
      server (though you can change this with the keep_releases variable). All \
      other deployed revisions are removed from the servers. By default, this \
      will use sudo to clean up the old releases, but if sudo is not available \
      for your environment, set the :use_sudo variable to false instead.
    DESC
    task :cleanup do
      # Don't every perform a cleanup, when there's only a single checkout of
      # the code.
      if(![:single_checkout_no_update].include?(deploy_via))
        original_cleanup
      end
    end
  end
end
