Capistrano::Configuration.instance(true).load do
  # For local development, don't attempt to checkout the code or maintain
  # multiple releases.
  set :deploy_via, :no_op
  set(:release_name) { application }
  set(:releases_path) { File.join("/vagrant/workspace") }
  set(:releases) { [release_name] }

  # Don't bother with permissions, since we'll assume everything should be
  # owned by the deployment user.
  set :group_writable, false

  # Don't use symlinks for shared content, since there's only one deployment
  # (and Vagrant doesn't support them on shared drives).
  set :disable_internal_symlinks, true
end
