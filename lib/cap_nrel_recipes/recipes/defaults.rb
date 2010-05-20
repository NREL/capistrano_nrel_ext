# Automatically include other common recipes that should be used on all
# servers. These recipes should not require additional dependencies on the
# destination server.
require "cap_nrel_recipes/recipes/clean_slate"
require "cap_nrel_recipes/recipes/cleanup"
require "cap_nrel_recipes/recipes/finalize_permissions"
require "cap_nrel_recipes/recipes/setup"
require "cap_nrel_recipes/recipes/shared_children"
require "cap_nrel_recipes/recipes/shared_children_files"
require "cap_nrel_recipes/recipes/undeploy"

Capistrano::Configuration.instance(true).load do
  # Setup default environment variables.
  default_environment["LD_LIBRARY_PATH"] = "/var/lib/instantclient" # For Rails & Oracle
  default_environment["TNS_ADMIN"] = "/var/lib/instantclient" # For Rails & Oracle so it knows where to find the sqlnet.ora file.

  # Don't use sudo.
  set :use_sudo, false

  # Set a unique name for this deployed application.
  set(:deploy_name) { "#{stage}-#{application}" }

  # Our deploy path will be made up of our custom deploy_to_base and
  # deploy_to_subdirectory variables which can be set by other extensions or
  # stage configuration.
  set(:deploy_to_base) { abort("Please specify the base path for your application, set :deploy_to_base, '/srv/afdc/cttsdev'") }
  set(:deploy_to_subdirectory) { application } 
  set(:deploy_to) { File.join(deploy_to_base, deploy_to_subdirectory) }

  # Keep a cached checkout on the server so updates are quicker.
  set :deploy_via, :remote_cache

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

  # Set any folders or files that need to be writable by the Apache user.
  set :writable_children, %w(log)
end
