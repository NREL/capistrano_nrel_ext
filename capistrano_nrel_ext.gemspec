# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "capistrano_nrel_ext/version"

Gem::Specification.new do |s|
  s.name        = "capistrano_nrel_ext"
  s.version     = CapistranoNrelExt::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Nick Muerdter"]
  s.email       = ["nick.muerdter@nrel.gov"]
  s.homepage    = ""
  s.summary     = %q{Our custom recipes and additions to Capistrano.}
  s.description = %q{Our custom recipes and additions to Capistrano.}

  s.rubyforge_project = "capistrano_nrel_ext"

  s.add_dependency("capistrano")

  # net-ssh 2.5.x is currently broken:
  # https://github.com/net-ssh/net-ssh/issues/45
  s.add_dependency("net-ssh", ["~> 2.4.0"])

  s.add_dependency("artii")
  s.add_dependency("diffy")
  s.add_dependency("highline")
  s.add_dependency("chronic", [">= 0.6.0"])
  s.add_dependency("erubis", [">= 2.6.0"])
  s.add_dependency("tzinfo", [">= 0.3.0"])

  s.add_development_dependency("rake")

  s.files         = Dir.glob("lib/**/*")
  s.require_paths = ["lib"]
end
