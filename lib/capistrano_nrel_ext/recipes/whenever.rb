require "capistrano_nrel_ext/recipes/gem_bundler"
require "whenever/capistrano/v2/recipes"

# This just shifts whenever's default capistrano recipes to happen slightly
# later so it gets along with when we install gems (after deploy:update_code
# instead of before deploy:finalize_update).
#
# (This could be revisited if we shift when we install gems, but at this point,
# that might be a bit tricky.)
Capistrano::Configuration.instance(true).load do
  # Write the new cron jobs near the end.
  after "deploy:update_code", "whenever:update_crontab"

  # If anything goes wrong, undo.
  after "deploy:rollback", "whenever:update_crontab"
end
