Capistrano::Configuration.instance(true).load do
  set :base_server_port, 9000
  set :deployment_server_ports, []
  set :used_server_ports, {}
  set :used_server_port_numbers, []

  #after "undeploy:delete", "undeploy:monit:delete"

  def used_server_ports
    connections = `netstat --inet --udp --all --numeric`

    used_ports = []
    connections.each do |row|
      # Skip the header lines
      if(row !~ /^(Active|Proto)/)
        columns = row.split(/\w+/)
        address = columns[3]
        port = address.split(":").last

        used_ports << port
      end
    end

    used_ports
  end

  def free_server_port
    free_port = base_server_port
    unavailable_ports = used_server_ports + deployment_server_ports

    while(unavailable_ports.include?(free_port))
      free_port += 1
    end

    deployment_server_ports << free_port

    free_port
  end

=begin
  def free_server_port
    last_used_port = used_server_port_numbers.last || base_server_port
    next_port = last_used_port + 1

    potential_port_range = base_server_port..next_port
    free_ports = potential_port_range.to_a - used_server_port_numbers
    free_port = free_ports.first

    used_server_port_numbers << free_port
    used_server_ports[deploy_name] << free_port

    free_port
  end
=end

  #before "deploy", "server_ports:fetch_config"
  #after "deploy", "server_ports:write_config"

  namespace :server_ports do
    task :fetch_config do


      remote_ports_file_path = File.join(deploy_to_base, "server_ports.yml")
      if(remote_file_exists?(remote_ports_file_path))
        require "tempfile"
        local_ports_file = Tempfile.new("server_ports")

        get(remote_ports_file_path, local_ports_file.path)

        used_server_ports = YAML::load(local_ports_file.read)
        used_server_ports ||= {}

        # Get a list of all the used port numbers.
        used_server_port_numbers = used_server_ports.values.flatten.sort

        # Unset the ports used by this specific deployment. This lets us
        # recalculate the ports used for this deployment, while freeing up the
        # old ports.
        used_server_ports[deploy_name] = []

        set :used_server_ports, used_server_ports
        set :used_server_port_numbers, used_server_port_numbers
      end
    end

    task :write_config do
puts "WRITE SERVER PORTS: #{used_server_ports.inspect}"
      remote_ports_file_path = File.join(deploy_to_base, "server_ports.yml")
      put(YAML::dump(used_server_ports), remote_ports_file_path)
    end
  end

  namespace :undeploy do
    namespace :server_ports do
      task :delete do
        run "rm -f #{monit_conf_dir}/#{deploy_name}.monitrc"
        deploy.monit.reload
      end
    end
  end
end
