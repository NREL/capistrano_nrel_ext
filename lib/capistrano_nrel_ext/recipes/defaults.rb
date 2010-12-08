# Automatically include other common recipes that should be used on all
# servers. These recipes should not require additional dependencies on the
# destination server.
require "capistrano_nrel_ext/recipes/clean_slate"
require "capistrano_nrel_ext/recipes/cleanup"
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

  # Set a unique name for this deployed application.
  set(:deploy_name) { "#{stage}-#{application}" }
  set(:deploy_release_name) { "#{deploy_name}-#{release_name}" }

  # Our deploy path will be made up of our custom deploy_to_base and
  # deploy_to_subdirectory variables which can be set by other extensions or
  # stage configuration.
  set(:deploy_to_base) { abort("Please specify the base path for your application, set :deploy_to_base, '/srv/afdc/cttsdev'") }
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

  # Setup any shared folders that should be kept between deployments.
  set :shared_children, %w(log)

  # Set any folders or files that need to be writable by the web user. Children
  # paths are given relative to the release's root.
  set :writable_children, %w(log)

  # Set any absolute paths that need to be writable by the web user.
  set :writable_paths, []
end
