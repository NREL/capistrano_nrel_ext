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
