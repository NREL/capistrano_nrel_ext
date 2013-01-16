Capistrano::Configuration.instance(true).load do
  # For development, don't maintain multiple releases.
  set :deploy_via, :cached_checkout

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

  # Don't bother with permissions, since we'll assume everything should be
  # owned by the deployment user.
  set :group_writable, false
end
