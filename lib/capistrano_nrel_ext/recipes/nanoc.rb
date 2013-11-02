require "capistrano_nrel_ext/recipes/gem_bundler"

Capistrano::Configuration.instance(true).load do
  #
  # Hooks
  #
  after "deploy:update_code", "deploy:nanoc:compile"

  namespace :deploy do
    namespace :nanoc do
      task :compile, :except => { :no_release => true } do
        run "cd #{latest_release} && #{bundle_exec} nanoc compile"
      end
    end
  end
end
