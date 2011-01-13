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

  s.add_dependency("capistrano", ["~> 2.5"])
  s.add_dependency("erubis", ["~> 2.6"])

  s.files         = Dir.glob("lib/**/*")
  s.require_paths = ["lib"]
end
