require "shellwords"

module CapistranoNrelExt
  module Actions
    module RemoteTests
      @@remote_file_exists = {}
      @@remote_directory_exists = {}
      @@remote_command_succeeds = {}
      @@remote_command_has_output = {}

      # Check if a file exists on the remote server.
      #
      # @param [String] full_path The absolute path to the file to check for on the
      #   remote server.
      # @return [Boolean] True if the file exists on the remote server, false
      #   otherwise.
      def remote_file_exists?(full_path)
        @@remote_file_exists[full_path] ||= 'true' == capture("if [ -f #{full_path} ]; then echo 'true'; fi").strip
      end

      # Check if a directory exists on the remote server.
      #
      # @param [String] full_path The absolute path to the directory to check for on
      #   the remote server.
      # @return [Boolean] True if the directory exists on the remote server, false
      #   otherwise.
      def remote_directory_exists?(full_path)
        @@remote_directory_exists[full_path] ||= 'true' == capture("if [ -d #{full_path} ]; then echo 'true'; fi").strip
      end

      # Check if running a command on the remote server successed (non-error
      # return code).
      #
      # @param [String] command The command to run.
      # @return [Boolean] True if running the command succeeded.
      def remote_command_succeeds?(command)
        if @@remote_command_succeeds[command].nil?
          begin
            run(command)
            @@remote_command_succeeds[command] = true
          rescue Capistrano::CommandError
            @@remote_command_succeeds[command] = false
          end
        end

        @@remote_command_succeeds[command]
      end

      # Check if running a command on the remote server results in any output.
      #
      # @param [String] command The command to run.
      # @return [Boolean] True if running the command resulted in any output.
      def remote_command_has_output?(command)
        if @@remote_command_has_output[command].nil?
          output = capture(command).strip
          @@remote_command_has_output[command] = !output.empty?
        end

        @@remote_command_has_output[command]
      end

      def remote_file_contains?(full_path, pattern)
        remote_command_succeeds?("grep -E #{pattern.shellescape} #{full_path}")
      end

      # Check if a specific rake task exists on the remote server.
      # @param [String] rake_root The absolute path to the directory containing the
      #   Rakefile on the remote server.
      # @param [String] task The name of the rake task to check for its existence.
      # @return [Boolean] True if the rake task exists on the remote server.
      def remote_rake_task_exists?(rake_root, task)
        if(remote_file_exists?(File.join(rake_root, "Rakefile")))
          rake = fetch(:rake, "rake")
          if(remote_file_exists?(File.join(rake_root, "Gemfile")))
            bundle_exec = fetch(:bundle_exec, "")
            rake = "#{bundle_exec} rake"
          end

          env = ""
          if(exists?(:rails_env))
            env = "RAILS_ENV=#{rails_env}"
          end

          remote_command_has_output?("cd #{rake_root}; #{env} #{rake} --silent --describe #{task} 2> /dev/null")
        else
          false
        end
      end
    end
  end
end

include CapistranoNrelExt::Actions::RemoteTests
