require 'capistrano/recipes/deploy/strategy/checkout'

module Capistrano
  module Deploy
    module Strategy
      class CachedCheckout < Checkout
        protected

        # Returns the SCM's checkout command for the revision to deploy.
        def command
          @command ||= "if [ -d #{configuration[:release_path]} ]; then " +
            "#{source.sync(revision, configuration[:release_path])}; " +
            "else #{source.checkout(revision, configuration[:release_path])}; fi"
        end
      end
    end
  end
end
