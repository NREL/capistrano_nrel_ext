Capistrano::Configuration.instance(true).load do
  #
  # Variables
  #

  # Since the branch name may be used as a subdomain, we need to clean it up a
  # bit. Notably, underscores from branch names will be removed, since some
  # browsers have problems with underscores in domain names.
  set :branch_name, ENV["BRANCH"].to_s.gsub(/[^A-Za-z0-9]/, "")

  if(branch_name.empty?)
    set(:deploy_to_subdirectory) { "#{application}/main" }
  else
    # Checkout the branch for git.
    set(:branch) { ENV["BRANCH"] }

    # Checkout the branch for subversion.
    set(:repository_subdirectory) { "branches/#{ENV["BRANCH"]}" }

    # Deploy to a branches subdirectory.
    set(:deploy_to_subdirectory) { "#{application}/branches/#{branch_name}" }

    # Use the branch name as a subdomain.
    set :subdomain, "#{branch_name}."

    # Create a unique name for this branch.
    set :deploy_name, "#{stage}-#{application}-#{branch_name}"
  end
end
