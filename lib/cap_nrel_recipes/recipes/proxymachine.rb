Capistrano::Configuration.instance(true).load do
  #
  # Variables
  #
  set :proxymachine_servers, []
  set(:proxymachine_conf_file) { File.join(latest_release, "config", "proxymachine.yml") }
  set(:proxymachine_pid_dir) { File.join(current_release, "tmp", "pids") }
  set(:proxymachine_log_dir) { File.join(current_release, "log") }
end
