require "capistrano_nrel_ext/recipes/sandboxes"

Capistrano::Configuration.instance(true).load do
  #
  # Variables
  #

  if(sandbox_name.empty?)
    set(:deploy_to_subdirectory) { "#{application}/main" }
  else
    # Deploy to a branches subdirectory.
    set(:deploy_to_subdirectory) { "#{application}/#{sandbox_name}" }
  end
end
