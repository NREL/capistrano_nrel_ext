require "capistrano/recipes/deploy/scm/git"

module Capistrano
  module Deploy
    module SCM
      class GitTracking < Git
        default_command "git"

        # Modify the default git checkout process to checkout and track a
        # specific branch.
        #
        # The default git SCM checks out a specific revision on a local
        # "deploy" branch. This is what we want for real deployment purposes
        # (so the specific revision can be checked out), but when deploying to
        # development sandboxes, we just want a normal checkout that tracks the
        # remote repo.
        def checkout(revision, *args)
          execute = super(revision, *args)

          branch = variable(:branch)
          track_branch = ""
          if branch
            track_branch = "-b #{branch} origin/#{branch}"
          end

          execute.gsub(/-b deploy #{revision}/, track_branch)
        end
      end
    end
  end
end
