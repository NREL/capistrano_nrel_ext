Capistrano::Configuration.instance(true).load do
  #
  # Hooks
  #
  after "deploy:start", "php_apc:clear_cache"
  after "deploy:restart", "php_apc:clear_cache"

  #
  # Tasks
  #
  namespace :php_apc do
    desc <<-DESC
      Clear the PHP APC cache. This should be executed if new PHP files have
      been deployed.
    DESC
    task :clear_cache, :roles => :app, :except => { :no_release => true } do
      apc_clear_cache_path = File.join(current_path, "public/apc_clear_cache.php")
      run <<-CMD
        echo "<?php header('Cache-Control: max-age=0'); apc_clear_cache(); apc_clear_cache('user'); ?>" > #{apc_clear_cache_path} && \
        curl -s "http://#{domain}/apc_clear_cache.php?cache_buster=#{Time.now.to_f}"; \
        rm -f #{apc_clear_cache_path};
      CMD
    end
  end
end
