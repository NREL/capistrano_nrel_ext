Capistrano::Configuration.instance(true).load do
  # For development, don't try to maintain the checkout. Checkout a single copy
  # on the first deployment (if it doesn't already exist), but don't ever
  # attempt to update or switch it (we'll assume the user wants to manage it
  # after the initial checkout).
  set :deploy_via, :single_checkout_no_update

  # For development, when using git, use our custom git_tracking scm so the
  # initial checkouts for sandboxes use real branches.
  if(exists?(:scm))
    if(scm.to_s == "git")
      set :scm, "git_tracking"
    end
  end

  # Only maintain a single release.
  set(:releases) { [release_name] }

  # Because there's only one release, forgo the timestamped releases to make
  # the paths easier.
  set(:release_name) do
    # Default to using the application name as the release name.
    name = application

    # If sandboxes are being used make the release name based on the sandbox
    # name instead (since the application name will already be in the path).
    if exists?(:sandbox_name)
      if(sandbox_name.empty?)
        name = "main"
      else
        name = sandbox_name
      end
    end

    name
  end

  # Separate the releases from the other deployment content so the paths are
  # easier to navigate in development.
  set(:releases_path_base) { abort("Please specify the base path for your releases, set :releases_path_base, '/srv'") }
  set(:releases_path) { File.join(releases_path_base, application) }

  # For user sandboxes, everything should just run as the normal user (so no
  # sudo-ing to a shared "deploy" user).
  set(:deploy_sudo_user) do
    if(!exists?(:sandbox_name) || sandbox_name.empty?)
      "deploy"
    else
      default_run_options[:shell] = "/bin/bash"
      user
    end
  end

  # For user sandboxes, don't bother with group permissions, since we'll assume
  # everything should be owned by the deployment user.
  set(:group_writable) do
    if(!exists?(:sandbox_name) || sandbox_name.empty?)
      true
    else
      false
    end
  end
end
