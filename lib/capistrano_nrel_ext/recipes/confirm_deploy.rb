require "highline"

Capistrano::Configuration.instance(true).load do
  terminal = HighLine.new

  banner = <<eos
################################################################################
#
# Are you REALLY sure you want to deploy to #{stage}?
#
################################################################################
eos

  terminal.say(terminal.color(banner, HighLine::RED))
  response = terminal.ask(terminal.color("Continue deployment? [y/n] ", HighLine::RED)) do |question|
    question.case = :downcase
  end

  if response != "y"
    exit
  end
end
