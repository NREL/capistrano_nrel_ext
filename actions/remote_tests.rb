# Check if a file exists on the remote server.
#
# @param [String] The absolute path to the file to check for on the remote
# server.
# @return [Boolean] True if the file exists on the remote server, false
# otherwise.
def remote_file_exists?(full_path)
  'true' == capture("if [ -f #{full_path} ]; then echo 'true'; fi").strip
end

# Check if a directory exists on the remote server.
#
# @param [String] The absolute path to the directory to check for on the remote
# server.
# @return [Boolean] True if the directory exists on the remote server, false
# otherwise.
def remote_directory_exists?(full_path)
  'true' == capture("if [ -d #{full_path} ]; then echo 'true'; fi").strip
end
