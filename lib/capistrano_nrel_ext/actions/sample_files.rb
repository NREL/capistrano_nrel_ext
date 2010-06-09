require "capistrano_nrel_ext/actions/remote_tests"

# Run sample configuration files through ERB so ruby variables can be
# substituted into the file to produce the actual configuration file.
#
# The supplied paths are a list of files that may have sample versions of the
# file. If a sample version of the file is found (given by the additional file
# extension ".sample"), it is run through ERB, and the result is uploaded to
# the server as a non-sample file (without the ".sample" file extension).
#
# For example, if ["config/apache/development.conf"] was given to this method,
# it would look for a "config/apache/development.conf.sample" file on the
# server. If that file was found, the "development.conf.sample" file would be
# run through ERB and the result would be uploaded to the server as
# "development.conf"
#
# @param [Array<String>] An array of file paths, relative to the release
# directory, that might potentially have sample versions.
def parse_sample_files(file_paths)
  require "tempfile"

  file_paths.each do |file_path|
    remote_path = File.join(latest_release, file_path)

    remote_sample_paths = []

    begin
      remote_sample_paths += capture("ls -1 #{remote_path}.erb").to_s.split
    rescue Capistrano::CommandError
    end

    begin
      remote_sample_paths += capture("ls -1 #{remote_path}.sample").to_s.split
    rescue Capistrano::CommandError
    end

    begin
      remote_sample_paths += capture("find #{remote_path} -name '*.erb' -o -name '*.sample'").to_s.split
    rescue Capistrano::CommandError
    end

    puts "REMOTE SAMPLE PATHS: #{remote_sample_paths.inspect}"

    remote_sample_paths.each do |remote_sample_path|
      # Download the sample path from the server. We want to grab the copy from
      # the server, and not the local copy, since they may differ (If I'm doing
      # a deploy and I haven't done an svn update or I'm deploying a specific
      # branch while sitting in another branch locally).
      local_sample_path = Tempfile.new("capistrano-sample").path
      get(remote_sample_path, local_sample_path)

      # Parse the sample file as a Ruby file so we can evaluate
      # variables.
      content = File.read(local_sample_path)
      parsed_content = ERB.new(content).result(binding)

      logger.info("Parsed sample file:\n\n")
      puts parsed_content
      logger.info("\n")

      remote_path = remote_sample_path.gsub(/\.(erb|sample)$/, "")

      # Write the evaluated configuration file to the server as the real
      # configuration file.
      put(parsed_content, remote_path)
    end
  end
end
