# encoding: UTF-8

require "capistrano/cli"
require "rainbow"

class Capistrano::CLI
  # Monkey patch Capistrano's internal execute_requested_actions method to
  # ensure we show a failure message on deployment failures.
  #
  # We can't rely on rollback callbacks or after deploy callbacks, since those
  # fail to get called in a variety of situations. To work around that issue,
  # we intercept all exceptions raised by the Capistrano tasks and display our
  # messages there.
  def execute_requested_actions_with_failure_message(config)
    begin
      execute_requested_actions_without_failure_message(config)
    rescue => e
      puts config.fetch(:failure_message)
      raise e
    end
  end

  alias_method :execute_requested_actions_without_failure_message, :execute_requested_actions
  alias_method :execute_requested_actions, :execute_requested_actions_with_failure_message
end

Capistrano::Configuration.instance(true).load do
  _cset(:failure_message) do
    message = <<-eos
                       █▄░░░░░░░░░░░░░░░░░░░░░░░░▄▄███
                       ███▄░░░░░░░░░░░░░░░░░░░░▄██████
                       █████▄░░░░░░░░░░░░░░░░░▄███████
                       ███████▄░░░░▄▄▄▄▄░░░░▄█████████
                       █████████▄▀▀░░░░░▀▀▀▄██████████
                       ▀█████▀░░░░░░░░░░░░░░▀████████░
                       ░▀██▀░░░░░░░░░░░░░░░░░░░▀████▌░
                       ░░██░░░░░░░░░░░░░░░░░░░░░░███░░
                       ░░█▀░░░░░░░░░░░░░░░░░░░░░░░██░░
                       ░░█░░▄████▄░░░░░▄████▄░░░░░░█░░
                       ░░█░░█▐▄█▐█░░░░░█▐▄█▐█░░░░░░█▄░
                       ░░█░░██▄▄██░░░░░██▄▄██░░░░░░░█░
                       ░▐▌░░░░░░░░░░░░░░░░░░░░░░░░░░▐▌
                       ░▐▌░░░░░░░▀▄▄▄▄▀░░░░░░░░░░░░░▐▌
                       ░▐▌░░░░░░░░░▐▌░░░░░░░░░░░░░░░▐▌
                       ░▐▌░░░░░░░▄▀▀▀▀▄░░░░░░░░░░░░░▐▌
                       ░░█▄░░░░░▀░░░░░░▀░░░░░░░░░░░░█▌
                       ░░▐█▀▄▄░░░░░░░░░░░░░░░░░░▄▄▀▀░█
                       ░▐▌░░░░▀▀▄▄░░░░░░░░▄▄▄▄▀▀░░░░░█
                       ░█░░░░░░░░░▀▀▄▄▄▀▀▀░░░░░░░░░░░█
                       ▐▌░░░░░░░░░░░░░░░░░░░░░░░░░░░░█
                       ▐▌░░░░░░░░░░░░░░░░░░░░░░░░░░░░█

██╗██╗██╗    ███████╗ █████╗ ██╗██╗     ██╗   ██╗██████╗ ███████╗    ██╗██╗██╗
██║██║██║    ██╔════╝██╔══██╗██║██║     ██║   ██║██╔══██╗██╔════╝    ██║██║██║
██║██║██║    █████╗  ███████║██║██║     ██║   ██║██████╔╝█████╗      ██║██║██║
╚═╝╚═╝╚═╝    ██╔══╝  ██╔══██║██║██║     ██║   ██║██╔══██╗██╔══╝      ╚═╝╚═╝╚═╝
██╗██╗██╗    ██║     ██║  ██║██║███████╗╚██████╔╝██║  ██║███████╗    ██╗██╗██╗
╚═╝╚═╝╚═╝    ╚═╝     ╚═╝  ╚═╝╚═╝╚══════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝    ╚═╝╚═╝╚═╝
    eos
    Rainbow(message).red
  end

  _cset(:success_message) do
    message = <<-eos
          ───────▄▄────────▄█▄────────▄▄───────
          ───────█░█───────█░█───────█░█───────
          ──▄▄────█░█──────█░█──────█░█────▄▄──
          ──█░█────█░█─────█░█─────█░█────█░█──
          ───█░█────█░█──███████──█░█────█░█───
          ────█░█────█████░░░░░█████────█░█────
          ─────█░█──██░░░░░░░░░░░░░██──█░█─────
          ──────█░██░░░░░░░░░░░░░░░░░██░█──────
          ───────███████████████████████───────
          ─▄▄▄▄▄▄███████████░███████████▄▄▄▄▄▄─
          █░░░░░░█░████████░░░████████░█░░░░░░█
          ─▀▀▀▀▀▀█░░░████░░░░░░░████░░░█▀▀▀▀▀▀─
          ───────█░░░░░░░░░░░░░░░░░░░░░█───────
          ───────██░░░░█░░░░░░░░░█░░░░░█───────
          ──────█░██░░░░█░░░░░░░█░░░░░█░█──────
          ─────█░█──█░░░░███████░░░░██─█░█─────
          ────█░█────██░░░░░░░░░░░██────█░█────
          ───█░█─────█░███████████░█─────█░█───
          ──█░█─────█░█────█░█────█░█─────█░█──
          ──▀▀─────█░█─────█░█─────█░█─────▀▀──
          ────────█░█──────█░█──────█░█────────
          ───────█░█───────█░█───────█░█───────
          ───────▀▀────────▀█▀────────▀▀───────

     ██████╗ ███████╗██████╗ ██╗      ██████╗ ██╗   ██╗
     ██╔══██╗██╔════╝██╔══██╗██║     ██╔═══██╗╚██╗ ██╔╝
     ██║  ██║█████╗  ██████╔╝██║     ██║   ██║ ╚████╔╝
     ██║  ██║██╔══╝  ██╔═══╝ ██║     ██║   ██║  ╚██╔╝
     ██████╔╝███████╗██║     ███████╗╚██████╔╝   ██║
     ╚═════╝ ╚══════╝╚═╝     ╚══════╝ ╚═════╝    ╚═╝

███████╗██╗   ██╗ ██████╗ ██████╗███████╗███████╗███████╗██╗██╗
██╔════╝██║   ██║██╔════╝██╔════╝██╔════╝██╔════╝██╔════╝██║██║
███████╗██║   ██║██║     ██║     █████╗  ███████╗███████╗██║██║
╚════██║██║   ██║██║     ██║     ██╔══╝  ╚════██║╚════██║╚═╝╚═╝
███████║╚██████╔╝╚██████╗╚██████╗███████╗███████║███████║██╗██╗
╚══════╝ ╚═════╝  ╚═════╝ ╚═════╝╚══════╝╚══════╝╚══════╝╚═╝╚═╝
    eos
    Rainbow(message).green
  end

  after "deploy", "deploy:success_message"

  namespace :deploy do
    # Show a clear success message after a full deployment. This is mostly to
    # clarify that any rm errors showing up from the cleanup task still mean the
    # deploy succeeded.
    task :success_message, :except => { :no_release => true } do
      duration = ChronicDuration.output(Time.now - $deployment_start_time, :format => :short)
      logger.info("\n\nYour deployment to #{stage} has succeeded.\n\nDeployment took: #{duration}\n\n\n")

      # A silly banner, because its fun.
      puts fetch(:success_message)
    end
  end
end
