require "capistrano_nrel_ext/recipes/development_deploy"

Capistrano::Configuration.instance(true).load do
  # Separate the releases from the other deployment content so the paths are
  # easier to navigate in development. This is also necessary for Vagrant so
  # the release is on the shared drive, while the other deployment content is
  # on Vagrant's local disk partition (where the "current" symlink is allowed).
  set :releases_path, "/vagrant/workspace"

  # Don't use symlinks for shared content, since there's only one deployment
  # (and Vagrant doesn't support them on shared drives).
  set :disable_internal_symlinks, true

  # Inside vagrant boxes, all deployments should run as the vagrant user. This
  # ensures that even if the DEPLOY_USER environment variable has some other
  # default value for all other deployments, the local vagrant deploys still
  # deploy as vagrant.
  set :user, "vagrant"
  set :deploy_sudo_user, "vagrant"

  # Reset this, since the one in defaults.rb gets set at load time, so it
  # doesn't pick up the fact that we've changed the deployment sudo user.
  default_run_options[:shell] = "sudo -u #{deploy_sudo_user} /bin/bash"
end
