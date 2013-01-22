require "diffy"

Capistrano::Configuration.instance(true).load do
  #
  # Hooks
  #
  before "deploy:finalize_update", "deploy:confirm_updated"

  #
  # Dependencies
  #
  depend(:remote, :command, "shasum")
  depend(:local, :command, "shasum")

  #
  # Tasks
  #
  namespace :deploy do
    task :confirm_updated, :except => { :no_release => true } do
      files = ["Gemfile", "Gemfile.lock"]
      files += capture("cd #{latest_release} && find config -type f").to_s.split

      # Ignore SCM files.
      files.reject! { |file| file =~ %r{.(svn|git)(/|$)} }

      # For the development environment, we might be deploying on top of an
      # existing sandbox. So ignore any files that get generated dynamically as
      # part of the deployment process.
      template_files = files.select { |file| file =~ /\.erb$/ }
      parsed_template_files = template_files.collect { |file| file.gsub(/\.erb$/, "") }
      files -= parsed_template_files
      files.reject! { |file| file =~ %r{config/deployed.yml$} }

      files.sort!

      local_checksum = run_locally("shasum -a 256 #{files.join(" ")}").strip.gsub(/[\r\n]+/, "\n")
      remote_checksum = capture("cd #{latest_release} && shasum -a 256 #{files.join(" ")}").strip.gsub(/[\r\n]+/, "\n")

      if(local_checksum != remote_checksum)
        diff = Diffy::Diff.new(local_checksum, remote_checksum, :diff => ["-U 0"])
        raise Capistrano::Error, <<-eos

##### ERROR: MISMATCHED DEPLOYMENT RESOURCES #####

The deployment scripts or resources on the destination server do not match the
versions present locally. Please make sure your working copy is up to date or
any pending commits to deployment resource files are commited.

The following files differ:

#{diff}
        eos
      end
    end
  end
end
