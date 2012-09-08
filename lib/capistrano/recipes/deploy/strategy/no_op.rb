require "capistrano/recipes/deploy/strategy/base"

module Capistrano
  module Deploy
    module Strategy
      class NoOp < Base
        def deploy!
          # Do nothing
        end
      end
    end
  end
end
