def install_deploy_files(file_paths)
  remote_paths = file_paths.map { |path| "#{File.join(latest_release, path)}.deploy" }

  remote_deploy_file_paths = capture("ls -1 #{remote_paths.join(" ")} 2> /dev/null; true").to_s.split

  commands = []
  remote_deploy_file_paths.each do |remote_deploy_file_path|
    install_remote_path = remote_deploy_file_path.gsub(/\.deploy$/, "")

    if(exists?(:rails_env) && rails_env != "development")
      # In development mode, don't overwrite any existing files.
      commands << "rsync -a --ignore-existing #{remote_deploy_file_path} #{install_remote_path}"
    else
      commands << "cp #{remote_deploy_file_path} #{install_remote_path}"
    end
  end

  if commands.any?
    run commands.join(" && ")
  end
end
