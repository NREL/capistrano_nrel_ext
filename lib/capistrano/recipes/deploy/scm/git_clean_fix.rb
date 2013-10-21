require "capistrano/recipes/deploy/scm/git"

module Capistrano
  module Deploy
    module SCM
      class Git
        # Workaround for capistrano not cleaning up defunct submodules:
        # https://github.com/capistrano/capistrano/issues/135
        def sync_with_clean_fix(revision, destination)
          execute = sync_without_clean_fix(revision, destination)
          execute.gsub(/(clean (-q)? -d -x -f)/, '\1 -f')
        end

        alias_method :sync_without_clean_fix, :sync
        alias_method :sync, :sync_with_clean_fix
      end
    end
  end
end
