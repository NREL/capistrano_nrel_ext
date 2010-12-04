Capistrano::Configuration.instance(true).load do
  #
  # Variables
  #
  set :apache_conf_dir, "/etc/httpd/sites-available"
  set :apache_init_script, "/sbin/service httpd reload"
end
