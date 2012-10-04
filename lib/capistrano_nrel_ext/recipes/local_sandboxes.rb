require "capistrano_nrel_ext/recipes/local_deploy"
require "capistrano_nrel_ext/recipes/sandboxes"

Capistrano::Configuration.instance(true).load do
  set(:release_name) { if(sandbox_name.empty?) then "main" else sandbox_name end }
end
