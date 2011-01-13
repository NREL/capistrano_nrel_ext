Capistrano::Configuration.instance(true).load do
  # Pick a port number to start reserving port numbers from. We'll pick
  # something relatively high to keep our stuff separate.
  set :server_port_start, 60000

  # Keep track of the port numbers reserved during the current deployment.
  set :deployment_server_ports, []

  def used_server_ports
    # Use netstat to fetch all the connections currently using ports.
    connections = `netstat --inet --all --numeric`

    # Parse out the port numbers in use from the connection info.
    used_ports = []
    connections.each do |row|
      # Skip the header lines
      if(row !~ /^(Active|Proto)/)
        # Grab the port number out of a line like:
        #
        # tcp        0      0 127.0.0.1:6379          0.0.0.0:*               LISTEN
        columns = row.split(/ +/)
        address = columns[3]
        port = address.split(":").last

        used_ports << port.to_i
      end
    end

    used_ports
  end

  def free_server_port
    # Pick a starting point to look for free ports.
    free_port = server_port_start

    # Ports currently in use, or ports that have already been reserved by this
    # deployment are unavailable.
    unavailable_ports = used_server_ports + deployment_server_ports

    # Go until we find a free port.
    while(unavailable_ports.include?(free_port))
      free_port += 1
    end

    # Make sure to reserve this new free port.
    deployment_server_ports << free_port

    free_port
  end
end
