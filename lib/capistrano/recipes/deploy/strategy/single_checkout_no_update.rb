require 'capistrano/recipes/deploy/strategy/checkout'

module Capistrano
  module Deploy
    module Strategy
      class SingleCheckoutNoUpdate < Checkout
        protected

        # Only perform a checkout if the directory doesn't exist. After it
        # exists, don't touch it (we'll assume the user wants to manage it).
        def command
          @command ||= "if [ ! -d #{configuration[:release_path]} ]; then " +
            "#{source.checkout(revision, configuration[:release_path])}; fi"
        end
      end
    end
  end
end
