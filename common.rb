load "#{File.dirname(__FILE__)}/actions/remote_tests"
load "#{File.dirname(__FILE__)}/actions/sample_files"

# Setup default environment variables.
default_environment["LD_LIBRARY_PATH"] = "/var/lib/instantclient_11_1" # For Rails & Oracle
default_environment["TNS_ADMIN"] = "/var/lib/instantclient_11_1" # For Rails & Oracle so it knows where to find the sqlnet.ora file.

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

# Set the default repository path which will check out of trunk.
set :repository_subdirectory, "trunk"
set(:repository) { "https://cttssvn.nrel.gov/svn/#{application}/#{repository_subdirectory}" }

# Set some default for the Apache configuration.
set :base_domain, ""
set :subdomain, ""
set(:domain) { "#{subdomain}#{base_domain}" }
set :apache_conf_dir, "/etc/apache2/ctts"

# Setup any shared folders that should be kept between deployments.
set :shared_children, %w(log)

# Setup any shared files that should be kept between deployments.
set :shared_children_files, %w()

# Setup any folders where uploaded content will go. The content needs to be
# kept between deployments, and we also want the ability to check the content
# into a subversion repository.
set :upload_children, %w()
set(:shared_uploads_path) { File.join(deploy_to_base, "shared_uploads", "current") }

# Set any folders or files that need to be writable by the Apache user.
set :writable_children, %w(log)

# Always run setup and check before deployment, since it's nondestructive and
# means one less step.
before "deploy", "deploy:try_setup", "deploy:check"

# Cleanup after deployment so we only keep a few of the latest releases around.
after "deploy", "deploy:try_cleanup"

# Show a success message after a full deployment.
after "deploy", "deploy:success_message"

# Setup for our custom shared_children_files.
after "deploy:setup", "deploy:setup_shared_children_files"

# Create the apache configuration file for this site based on the sample file.
after "deploy:update_code", "deploy:apache:config"

# Make everything group writable.
after "deploy:update_code", "deploy:finalize_permissions"

# Put the created apache configuration file in place.
before "deploy:restart", "deploy:apache:install"

load "#{File.dirname(__FILE__)}/common/jammit"
load "#{File.dirname(__FILE__)}/common/maintenance"
load "#{File.dirname(__FILE__)}/common/monit"
load "#{File.dirname(__FILE__)}/common/rails"
load "#{File.dirname(__FILE__)}/common/servlets"

# Remote dependencies.
depend(:remote, :directory, apache_conf_dir)
depend(:remote, :file, "/etc/apache2/sites-enabled/ctts")

namespace :deploy do
  # Kill any default tasks we don't want at all.
  [:restart].each do |default_task|
    desc <<-DESC
      Default task overriden to do nothing.
    DESC
    task default_task do 
    end
  end

  # By default, we'll try to run setup, but we don't care if it fails. This
  # probably just means that the deployment has already succeeded once, and
  # things are already setup.
  task :try_setup, :except => { :no_release => true } do
    begin
      deploy.setup
    rescue Capistrano::CommandError
    end
  end

  task :setup_shared_children_files, :except => { :no_release => true } do
    dirs = shared_children_files.collect { |file| File.join(shared_path, File.dirname(file)) }
    dirs.uniq!

    if(dirs.any?)
      run "#{try_sudo} mkdir -p #{dirs.join(' ')} && #{try_sudo} chmod g+w #{dirs.join(' ')}"
    end
  end

  # Override the default finalize_update task to sh
  task :finalize_update, :except => { :no_release => true } do
    shared_children.each do |shared_dir|
      begin
        # The log folder should be shared between deployments.
        run "rm -rf #{latest_release}/#{shared_dir} && " +
          "ln -s #{shared_path}/#{shared_dir} #{latest_release}/#{shared_dir}"
      rescue Capistrano::CommandError
      end
    end


    shared_children_files.each do |shared_file|
      begin
        run "rm -f #{latest_release}/#{shared_file} && " +
          "touch #{shared_path}/#{shared_file} && " +
          "ln -s #{shared_path}/#{shared_file} #{latest_release}/#{shared_file}"
      rescue Capistrano::CommandError
      end
    end


    upload_children.each do |upload_dir|
      begin
        # The log folder should be shared between deployments.
        run "rm -rf #{latest_release}/#{upload_dir} && " +
          "mkdir -p #{shared_uploads_path}/public/#{stage} && " +
          "ln -s #{shared_uploads_path}/public/#{stage} #{latest_release}/#{upload_dir}"
      rescue Capistrano::CommandError
      end
    end
  end

  # Make everything writable at a later stage in deployment than normal, so
  # any generated files can also be handled.
  task :finalize_permissions, :except => { :no_release => true } do
    # Try to make everything group writable. If any of this fails, we don't
    # care, since it probably means the files are owned by someone else,
    # but should already be setup to be group writable.
    if(fetch(:group_writable, true))
      begin
        # Make the latest release group writable.
        run "chmod -Rf g+w #{latest_release}"
      rescue Capistrano::CommandError
      end

      begin
        # Make all of the shared files group writable. 
        run "chmod -Rf g+w #{shared_path}"
      rescue Capistrano::CommandError
      end
    end

    # Files and folders that need to be writable by the web server
    # (www-data user) will need to be writable by everyone.
    begin
      # Try changing the permissions in both the release directory and the
      # shared directory, since chmod won't recursively follow symlinks.
      dirs = writable_children.collect { |d| File.join(latest_release, d) } + 
        writable_children.collect { |d| File.join(shared_path, d) } +
        upload_children.collect { |d| File.join(shared_uploads_path, "public", stage.to_s, d) }

      if(dirs.any?)
        run "chmod -Rf o+w #{dirs.join(" ")}"
      end
    rescue Capistrano::CommandError
    end
  end

  # We'll try to run cleanup after a deployment. But this might fail if the
  # deployment contains files that are owned by www-data (such as Rails cache
  # files). Try to gracefully handle those errors.
  task :try_cleanup, :except => { :no_release => true } do
    begin
      deploy.cleanup
    rescue Capistrano::CommandError
      # If a cleanup failed, it was probably permission errors. Try rerunning
      # the command using sudo. If this still fails, we don't care too much.
      # The problem files will just sit around for a while until someone with
      # sudo access does a deployment.
      begin
        set :run_method, :sudo
        deploy.cleanup
        set :run_method, :run
      rescue Capistrano::CommandError
      end
    end
  end

  # Show a clear success message after a full deployment. This is mostly to
  # clarify that any rm errors showing up from the cleanup task still mean the
  # deploy succeeded.
  task :success_message, :except => { :no_release => true } do
    logger.info("\n\nYour deployment to #{stage} has succeeded.\n\n\n")

    # A silly banner, because its fun.
    print `figlet -f big "Deployment Success!!" 2> /dev/null`
  end

  # Apache tasks
  namespace :apache do
    desc <<-DESC
      Restart Apache. This should be executed if new Apache configuration
      files have been deployed.
    DESC
    task :restart, :roles => :app, :except => { :no_release => true } do
      sudo "/etc/init.d/apache2 reload"
    end

    desc <<-DESC
      Create the Apache configuration file. If a sample file for the given
      stage is present in config/apache, the sample is run through ERB (for
      variable replacement) to create the actual config file to be used.
    DESC
    task :config, :except => { :no_release => true } do
      parse_sample_files([
        "config/apache/paths.conf",
        "config/apache/#{stage}.conf"])
    end

    desc <<-DESC
      Install the Apache configuration file in a system-wide directory for
      Apache to find. This makes a symbolic link to the latest configuration
      file for this deployment in Apache's configuration directory.
    DESC
    task :install, :except => { :no_release => true } do
      conf_file = "#{latest_release}/config/apache/#{stage}.conf"

      if(remote_file_exists?(conf_file))
        # Ensure the the Apache configuration directories are in place.
        dirs = ["#{apache_conf_dir}/include", "#{apache_conf_dir}/sites"]
        begin
          run "mkdir -p #{dirs.join(' ')}"
          run "chmod -f g+w #{dirs.join(' ')}"
        rescue Capistrano::CommandError
        end

        run "ln -sf #{conf_file} #{apache_conf_dir}/sites/#{deploy_name}.conf"
      end
    end
  end
end

# Provide a way to remove deployed branches or sandboxes in the testing or
# development environment.
namespace :undeploy do
  desc <<-DESC
    Undeploy and completely remove a deployment. This should only be run if
    you're cleaning up unused sandboxes or branches.
  DESC
  task :default do
    # Never run an undeploy on the production server.
    if(stage == :production)
      abort("This should not be run on the production server")
    end

    confirm = Capistrano::CLI.ui.ask("Are you sure you would like to completely remove the deployment from:\n#{deploy_to}? (y/n) ") do |q|
      q.default = "n"
    end.downcase

    if(confirm == "y")
      apache.delete
      delete

      # Restart Apache after the configuration file has been removed.
      deploy.apache.restart
    end
  end

  # Remove the entire deploy_to directory.
  task :delete do
    delete_command = "rm -rf #{deploy_to}"

    begin
      run(delete_command)
    rescue Capistrano::CommandError
      begin
        sudo(delete_command)
      rescue Capistrano::CommandError
      end
    end
  end

  namespace :apache do
    # Remove the symbolic link to the apache configuration file that's in
    # place for this deployment.
    task :delete do
      run "rm -f #{apache_conf_dir}/sites/#{deploy_name}.conf"
    end
  end
end
