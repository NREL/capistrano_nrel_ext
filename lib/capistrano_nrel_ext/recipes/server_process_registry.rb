require "tmpdir"

class ServerProcessRegistry
  attr_reader :registry

  def initialize(cap)
    @cap = cap
    @deploy_name = cap.deploy_name
    @starting_port = cap.server_process_registry_starting_port
    @system_conf_dir = cap.server_process_registry_conf_dir

    @registry = {}
    @registry[@deploy_name] ||= {}
  end

  def add_server(server_type, server_config = {})
    remote_registry
    server_config[:host] ||= "127.0.0.1"
    server_config[:port] ||= pick_server_port(server_type, server_config[:host])

    @registry[@deploy_name][server_type] ||= []
    @registry[@deploy_name][server_type] << server_config
  end

  def servers(server_type)
    @registry[@deploy_name][server_type] ||= []
  end

  private

  def remote_registry
    unless @remote_registry
      @remote_registry = {}

      tmp_dir = Dir.mktmpdir
      @cap.get(@cap.server_process_registry_conf_dir, tmp_dir, :recursive => true)

      Dir.glob(File.join(tmp_dir, "*.yml")).each do |file|
        @remote_registry.merge!(YAML.load_file(file))
      end
    end

    @remote_registry
  end

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

  def all_registered_ports
    unless @all_registered_ports
      @all_registered_ports = []

      remote_registry.each do |deploy_name, deploy_config|
        deploy_config.each do |server_type, servers|
          servers.each do |server|
            @all_registered_ports << server[:port]
          end
        end
      end
    end

    @all_registered_ports
  end

  def deployment_reserved_ports
    @deployment_reserved_ports ||= []
  end

  def unavailable_ports
    @unavailable_ports ||= used_server_ports + all_registered_ports
  end

  def pick_server_port(server_type, host)
    port = pick_existing_server_port(server_type, host) || pick_free_server_port
    puts "PICKED PORT: #{port}"

    # Make sure to reserve this new free port.
    deployment_reserved_ports << port

    port
  end

  def pick_existing_server_port(server_type, host)
    port = nil

    if(remote_registry[@deploy_name] && remote_registry[@deploy_name][server_type])
      remote_registry[@deploy_name][server_type].each do |server|
        if(server[:host] == host)
          if(!deployment_reserved_ports.include?(server[:port]))
            port = server[:port]
          end
        end
      end
    end

    puts "PICKED EXISTING PORT: #{port}"
    port
  end

  def pick_free_server_port
    # Pick a starting point to look for free ports.
    port = @starting_port

    # Go until we find a free port.
    while(unavailable_ports.include?(port) || deployment_reserved_ports.include?(port))
      port += 1
    end

    puts "PICKED FREE PORT: #{port}"
    port
  end
end

Capistrano::Configuration.instance(true).load do
  #
  # Variables
  #
  set :server_process_registry_conf_dir, "/etc/server_process_registry"

  # Pick a port number to start reserving port numbers from. We'll pick
  # something relatively high to keep our stuff separate.
  set :server_process_registry_starting_port, 50000

  set(:default_server_process_registry) { ServerProcessRegistry.new(self) }

  set(:server_process_registry) { default_server_proecess_registry }

  set(:server_process_registry_conf_file) { File.join(latest_release, "config", "server_process_registry.yml") }

  #
  # Hooks 
  #
  after "deploy:update_code", "deploy:server_process_registry_tasks:config"
  before "deploy:start", "deploy:server_process_registry_tasks:install"
  before "deploy:restart", "deploy:server_process_registry_tasks:install"

  #
  # Tasks
  #
  namespace :deploy do
    namespace :server_process_registry_tasks do
      desc <<-DESC
        Create the Apache configuration file. If a sample file for the given
        stage is present in config/apache, the sample is run through ERB (for
        variable replacement) to create the actual config file to be used.
      DESC
      task :config, :except => { :no_release => true } do
        put(YAML.dump(server_process_registry.registry), server_process_registry_conf_file)
      end

      task :install, :except => { :no_release => true } do
        if(remote_file_exists?(server_process_registry_conf_file))
          install_path = File.join(server_process_registry_conf_dir, "#{deploy_name}.yml")
          run "ln -sf #{server_process_registry_conf_file} #{install_path}"
        end
      end
    end
  end
end
