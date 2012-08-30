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

      # Run the cache clearing command twice. This shouldn't be necessary, but
      # it seems to be for now.
      #
      # I think this relates to us not actually reloading the php-fpm processes
      # on deployment (because the reload process isn't very graceful:
      # https://bugs.php.net/bug.php?id=60961). Since we don't perform a
      # reload, I think the first PHP hit sort of internally reloads things,
      # and then the second one will actually clear the APC cache properly. At
      # least that's my theory.
      #
      # This should probably be revisited if php-fpm's reload process becomes
      # more graceful.
      2.times do
        run <<-CMD
          echo "<?php header('Cache-Control: max-age=0'); apc_clear_cache(); apc_clear_cache('user'); ?>" > #{apc_clear_cache_path} && \
          curl -s "http://#{domain}/apc_clear_cache.php?cache_buster=#{Time.now.to_f}"; \
          rm -f #{apc_clear_cache_path};
        CMD
      end
    end
  end
end
