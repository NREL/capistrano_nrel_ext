Capistrano::Configuration.instance(true).load do
  #
  # Hooks
  #

  # Always run setup and check before deployment, since it's nondestructive and
  # means one less step.
  before "deploy", "deploy:setup", "deploy:check"
  before "deploy:cold", "deploy:setup", "deploy:check"
end

