# Check if a file exists on the remote server.
#
# @param [String] full_path The absolute path to the file to check for on the
#   remote server.
# @return [Boolean] True if the file exists on the remote server, false
#   otherwise.
def remote_file_exists?(full_path)
  'true' == capture("if [ -f #{full_path} ]; then echo 'true'; fi").strip
end

# Check if a directory exists on the remote server.
#
# @param [String] full_path The absolute path to the directory to check for on
#   the remote server.
# @return [Boolean] True if the directory exists on the remote server, false
#   otherwise.
def remote_directory_exists?(full_path)
  'true' == capture("if [ -d #{full_path} ]; then echo 'true'; fi").strip
end

# Check if running a command on the remote server results in any output.
#
# @param [String] command The command to run.
# @return [Boolean] True if running the command resulted in any output.
def remote_command_has_output?(command)
  output = capture(command).strip
  !output.empty?
end

# Check if a specific rake task exists on the remote server.
# @param [String] rake_root The absolute path to the directory containing the
#   Rakefile on the remote server.
# @param [String] task The name of the rake task to check for its existence.
# @return [Boolean] True if the rake task exists on the remote server.
def remote_rake_task_exists?(rake_root, task)
  if(remote_file_exists?(File.join(rake_root, "Rakefile")))
    remote_command_has_output?("cd #{rake_root} && rake --silent --describe #{task} 2> /dev/null")
  else
    false
  end
end
