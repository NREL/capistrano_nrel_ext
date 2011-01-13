require "capistrano_nrel_ext/actions/sample_files"

Capistrano::Configuration.instance(true).load do
  #
  # Variables
  #
  set :maintenance_type, "general"

  #
  # Tasks
  #
  namespace :deploy do
    namespace :web do
      desc <<-DESC
        Present a maintenance page to visitors. Disables your application's web \
        interface by writing a "maintenance.html" file to each web server. The \
        servers must be configured to detect the presence of this file, and if \
        it is present, always display it instead of performing the request.

        By default, the maintenance page will just say the site is down for \
        "maintenance", and will be back "shortly", but you can customize the \
        page by specifying the REASON and UNTIL environment variables:

          $ cap deploy:web:disable \\
                REASON="hardware upgrade" \\
                UNTIL="12pm Central Time"

        Further customization will require that you write your own task.
      DESC
      task :disable, :roles => :web, :except => { :no_release => true } do
        require "active_support" # For time zone support

        on_rollback { run "rm -f #{shared_path}/public/system/maintenance.html && rm -f #{shared_path}/public/system/maintenance_#{maintenance_type}" }

        warn <<-EOHTACCESS
        
          # Please add something like this to your site's htaccess to redirect users to the maintenance page.
          # More Info: http://www.shiftcommathree.com/articles/make-your-rails-maintenance-page-respond-with-a-503
          
          ErrorDocument 503 /system/maintenance.html
          RewriteEngine On
          RewriteCond %{REQUEST_URI} !\.(css|gif|jpg|png)$
          RewriteCond %{DOCUMENT_ROOT}/system/maintenance.html -f
          RewriteCond %{SCRIPT_FILENAME} !maintenance.html
          RewriteRule ^.*$  -  [redirect=503,last]
        EOHTACCESS

        reason = ENV['REASON']
        deadline = ENV['UNTIL']

        parse_sample_files(["config/templates/maintenance.html"])
        run "mv #{File.join(latest_release, "config", "templates", "maintenance.html")} #{File.join(shared_path, "public", "system", "maintenance.html")}"
        run "touch #{File.join(shared_path, "public", "system", "maintenance_#{maintenance_type}")}"
      end

      desc <<-DESC
        Makes the application web-accessible again. Removes the \
        "maintenance.html" page generated by deploy:web:disable, which (if your \
        web servers are configured correctly) will make your application \
        web-accessible again.
      DESC
      task :enable, :roles => :web, :except => { :no_release => true } do
        run "rm -f #{shared_path}/public/system/maintenance.html && rm -f #{shared_path}/public/system/maintenance_#{maintenance_type}"
      end

      desc <<-DESC
        Present a maintenance page to visitors for data-input pages.
      DESC
      task :disable_input, :roles => :web, :except => { :no_release => true } do
        set :maintenance_type, "input"
        deploy.web.disable
      end

      desc <<-DESC
        Makes the data-input pages web-accessible again.
      DESC
      task :enable_input, :roles => :web, :except => { :no_release => true } do
        set :maintenance_type, "input"
        deploy.web.enable
      end
    end
  end
end
