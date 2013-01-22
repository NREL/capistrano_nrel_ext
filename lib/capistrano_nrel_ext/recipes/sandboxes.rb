Capistrano::Configuration.instance(true).load do
  #
  # Variables
  #

  # Sandboxes can be setup in the developement environment. If no sandbox is
  # given, then things are deployed to cttsdev.nrel.gov. If a sandbox name is
  # given, then a sandbox is created and is accessed by SANDBOX.cttsdev.nrel.gov
  set :sandbox_name, ENV["SANDBOX"].to_s.gsub(/[^A-Za-z0-9]/, "")

  if ENV["BRANCH"]
    # Checkout the branch for git.
    set(:branch) { ENV["BRANCH"] }

    # Checkout the branch for subversion.
    set(:repository_subdirectory) { "branches/#{ENV["BRANCH"]}" }
  end

  if(sandbox_name.empty?)
    set(:deploy_to_subdirectory) { "#{application}/common" }
  else
    # Deploy to a branches subdirectory.
    set(:deploy_to_subdirectory) { "#{application}/#{sandbox_name}" }

    # Use the sandbox name as a subdomain.
    set :subdomain, "#{sandbox_name}."

    # Create a unique name for this sandbox.
    set :deploy_name, "#{stage}-#{application}-#{sandbox_name}"
  end
end
