require "capistrano_nrel_ext/actions/template_files"

Capistrano::Configuration.instance(true).load do
  #
  # Variables
  #
  _cset :tomcat_context_dir, "/etc/tomcat6/Catalina/localhost"
  _cset :tomcat_init_script, "/etc/init.d/tomcat6"

  #
  # Hooks
  #
  after   "deploy:update_code", "deploy:tomcat:config"
  before  "deploy:start",       "deploy:tomcat:install"
  before  "deploy:restart",     "deploy:tomcat:install"
  #after   "deploy:start",       "tomcat:reload"
  #after   "deploy:restart",     "tomcat:reload"
  before  "undeploy:delete",    "undeploy:tomcat:delete"
  #after   "undeploy",           "tomcat:reload"

  #
  # Dependencies
  #
  depend(:remote, :directory, tomcat_context_dir)
  depend(:remote, :file, tomcat_init_script)

  #
  # Tasks
  #
  namespace :tomcat do
    desc <<-DESC
      Reload Tomcat. This should be executed if new Tomcat configuration files
      have been deployed.
    DESC
    task :reload, :roles => :app, :except => { :no_release => true } do
      sudo "#{tomcat_init_script} reload"
    end
  end

  namespace :deploy do
    namespace :tomcat do
      desc <<-DESC
        Create the Tomcat configuration file. If a sample file for the given
        stage is present in config/tomcat, the sample is run through ERB (for
        variable replacement) to create the actual config file to be used.
      DESC
      task :config, :except => { :no_release => true } do
        parse_template_files(["config/tomcat"])
      end

      desc <<-DESC
        Install the Tomcat configuration file in a system-wide directory for
        Tomcat to find. This makes a symbolic link to the latest configuration
        file for this deployment in Tomcat's configuration directory.
      DESC
      task :install, :except => { :no_release => true } do
        context_files = capture("find #{latest_release}/config/tomcat -name '*.xml'").to_s.split
        install_commands = context_files.collect do |path|
          "ln -sf #{path} #{tomcat_context_dir}/#{File.basename(path)}"
        end

        run install_commands.join(" && ")
      end
    end
  end

  namespace :undeploy do
    namespace :tomcat do
      # Remove the symbolic link to the tomcat configuration file that's in
      # place for this deployment.
      task :delete do
        run "rm -f #{tomcat_conf_dir}/#{deploy_name}.xml"
      end
    end
  end
end

