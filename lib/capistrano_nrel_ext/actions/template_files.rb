require "erubis"
require "capistrano_nrel_ext/actions/remote_tests"

# Run template configuration files through ERB so ruby variables can be
# substituted into the file to produce the actual configuration file.
#
# The supplied paths are a list of files that may have template versions of the
# file. If a template version of the file is found (given by the additional file
# extension ".erb"), it is run through ERB, and the result is uploaded to
# the server as a non-template file (without the ".erb" file extension).
#
# For example, if ["config/apache/development.conf"] was given to this method,
# it would look for a "config/apache/development.conf.erb" file on the
# server. If that file was found, the "development.conf.erb" file would be
# run through ERB and the result would be uploaded to the server as
# "development.conf"
#
# @param [Array<String>] An array of file paths, relative to the release
# directory, that might potentially have template versions.
def parse_template_files(file_paths)
  require "tempfile"

  file_paths.each do |file_path|
    remote_path = File.join(latest_release, file_path)

    remote_template_paths = []

    # If a file was given, see if a template file exists.
    begin
      remote_template_paths += capture("ls -1 #{remote_path}.erb").to_s.split
    rescue Capistrano::CommandError
    end

    # If a path was given, see recursively check for any templates.
    begin
      remote_template_paths += capture("find #{remote_path} -name '*.erb'").to_s.split
    rescue Capistrano::CommandError
    end

    remote_template_paths.each do |remote_template_path|
      # Download the template path from the server. We want to grab the copy from
      # the server, and not the local copy, since they may differ (If I'm doing
      # a deploy and I haven't done an svn update or I'm deploying a specific
      # branch while sitting in another branch locally).
      Tempfile.open("capistrano-template") do |temp_file|
        get(remote_template_path, temp_file.path)

        # Parse the template file as a Ruby file so we can evaluate
        # variables.
        content = File.read(temp_file.path)
        parsed_content = Erubis::Eruby.new(content).result(binding)

        logger.info("Parsed template file:\n\n")
        puts parsed_content
        logger.info("\n")

        install_remote_path = remote_template_path.gsub(/\.erb$/, "")

        # Write the evaluated configuration file to the server as the real
        # configuration file.
        put(parsed_content, install_remote_path)
      end
    end
  end
end
