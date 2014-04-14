require "capistrano/recipes/deploy/strategy/remote"

class Capistrano::Deploy::Strategy::Remote
  # Override the default scm_run command to explicitly set the shell.
  # This allows SCM commands to run as the original user, rather than the
  # deploy user we normally sudo to for everything else. This is so that
  # the SCM commands can still work with SSH agent forwarding.
  def scm_run(command)
    run(command, :shell => "/bin/bash") do |ch,stream,text|
      ch[:state] ||= { :channel => ch }
      output = source.handle_data(ch[:state], stream, text)
      ch.send_data(output) if output
    end
  end
end

require "capistrano/configuration/actions/file_transfer"

class Capistrano::Configuration
  # Files get uploaded via SFTP or SCP as the original user. Workaround to make
  # these become owned by the deploy user.
  def transfer_with_owner(direction, from, to, options={}, &block)
    if(direction == :up)
      temp_to = "#{to}.tmp"
      transfer_without_owner(direction, from, temp_to, options, &block)
      run "cp #{temp_to} #{to}"
      run "rm #{temp_to}", :shell => "/bin/bash"
    else
      transfer_without_owner(direction, from, to, options, &block)
    end
  end

  alias_method :transfer_without_owner, :transfer
  alias_method :transfer, :transfer_with_owner
end
