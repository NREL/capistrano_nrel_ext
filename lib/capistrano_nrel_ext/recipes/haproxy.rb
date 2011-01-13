require "capistrano_nrel_ext/actions/sample_files"

Capistrano::Configuration.instance(true).load do
  #
  # Variables
  #
  set :haproxy_conf_dir, "/etc/haproxy/conf"

  #
  # Hooks 
  #
  after "deploy:update_code", "deploy:haproxy:config"
  before "deploy:restart", "deploy:haproxy:install"
  after "deploy:restart", "haproxy:reload"

  #
  # Tasks
  #
  namespace :haproxy do
    desc <<-DESC
      Reload HAProxy. This should be executed if new HAProxy configuration
      files have been deployed.
    DESC
    task :reload, :roles => :app, :except => { :no_release => true } do
      sudo "/etc/init.d/haproxy reload"
    end
  end

  namespace :deploy do
    namespace :haproxy do
      desc <<-DESC
        Parse any HAProxy configuration files in `config/haproxy` as ERB
        templates.
      DESC
      task :config, :except => { :no_release => true } do
        parse_sample_files(["config/haproxy"])
      end

      desc <<-DESC
        Install the HAProxy configuration files in a system-wide directory for
        HAProxy to find.
      DESC
      task :install, :except => { :no_release => true } do
        shared_frontends = begin
          capture("ls -1 #{File.join(latest_release, "config", "haproxy", "shared_frontends", "*.cfg")}").to_s.split
        rescue Capistrano::CommandError
          []
        end

        frontends = begin
          capture("ls -1 #{File.join(latest_release, "config", "haproxy", "frontends", "*.cfg")}").to_s.split
        rescue Capistrano::CommandError
          []
        end

        backends = begin
          capture("ls -1 #{File.join(latest_release, "config", "haproxy", "backends", "*.cfg")}").to_s.split
        rescue Capistrano::CommandError
          []
        end

        # Install the static shared frontend configuration files that may serve
        # as the basis for other frontends to be installed.
        shared_frontends.each do |path|
          install_path = File.join(haproxy_conf_dir, "frontend.d", File.basename(path))
          run "cp #{path} #{install_path}"
        end

        # Install all of this deployment's frontend configuration files.
        frontends.each do |path|
          install_filename = "#{File.basename(path, ".cfg")}-#{deploy_name}.cfg"
          install_path = File.join(haproxy_conf_dir, "frontend.d", install_filename)
          run "ln -sf #{path} #{install_path}"
        end

        # Install all of this deployment's backend configuration files.
        backends.each do |path|
          install_filename = "#{File.basename(path, ".cfg")}-#{deploy_name}.cfg"
          install_path = File.join(haproxy_conf_dir, "backend.d", install_filename)
          run "ln -sf #{path} #{install_path}"
        end
      end
    end
  end
end
