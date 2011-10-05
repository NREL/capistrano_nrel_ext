require "yaml"

Capistrano::Configuration.instance(true).load do
  #
  # Variables
  #
  _cset :deployed_config_variables, [:deploy_name, :deploy_release_name, :domain]

  #
  # Hooks 
  #
  after "deploy:update_code", "deploy:deployed_config:install"

  #
  # Tasks
  #
  namespace :deploy do
    namespace :deployed_config do
      task :install, :except => { :no_release => true } do
        variable_values = {}
        deployed_config_variables.each do |variable, value|
          variable_values[variable.to_s] = fetch(variable, nil)
        end

        variables_yaml = YAML.dump(variable_values)

        path = File.join(latest_release, "config", "deployed.yml")
        put(variables_yaml, path)
      end
    end
  end
end
