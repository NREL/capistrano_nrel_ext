Capistrano::Configuration.instance(true).load do
  #
  # Variables
  #
  _cset :varnish_ban_script, "/usr/local/bin/varnish_ban"

  #
  # Hooks 
  #
  after "deploy:restart", "varnish:ban"

  #
  # Tasks
  #
  namespace :varnish do
    desc <<-DESC
      Clear the Varnish cache for this host. This should be executed on new
      deployments.
    DESC
    task :ban, :roles => :app, :except => { :no_release => true } do
      sudo %(#{varnish_ban_script} 'req.http.host == "#{domain}"')
    end
  end
end
