# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{capistrano_nrel_ext}
  s.version = "0.1.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = ["Nick Muerdter"]
  s.date = %q{2010-12-07}
  s.description = %q{}
  s.email = %q{nick.muerdter@nrel.gov}
  s.extra_rdoc_files = ["lib/capistrano_nrel_ext/actions/remote_tests.rb", "lib/capistrano_nrel_ext/actions/sample_files.rb", "lib/capistrano_nrel_ext/recipes/apache.rb", "lib/capistrano_nrel_ext/recipes/branches.rb", "lib/capistrano_nrel_ext/recipes/clean_slate.rb", "lib/capistrano_nrel_ext/recipes/cleanup.rb", "lib/capistrano_nrel_ext/recipes/defaults.rb", "lib/capistrano_nrel_ext/recipes/finalize_permissions.rb", "lib/capistrano_nrel_ext/recipes/gem_bundler.rb", "lib/capistrano_nrel_ext/recipes/haproxy.rb", "lib/capistrano_nrel_ext/recipes/jammit.rb", "lib/capistrano_nrel_ext/recipes/maintenance.rb", "lib/capistrano_nrel_ext/recipes/monit.rb", "lib/capistrano_nrel_ext/recipes/previous_release.rb", "lib/capistrano_nrel_ext/recipes/proxymachine.rb", "lib/capistrano_nrel_ext/recipes/rails.rb", "lib/capistrano_nrel_ext/recipes/redhat.rb", "lib/capistrano_nrel_ext/recipes/sandboxes.rb", "lib/capistrano_nrel_ext/recipes/server_ports.rb", "lib/capistrano_nrel_ext/recipes/server_process_registry.rb", "lib/capistrano_nrel_ext/recipes/servlets.rb", "lib/capistrano_nrel_ext/recipes/setup.rb", "lib/capistrano_nrel_ext/recipes/shared_children.rb", "lib/capistrano_nrel_ext/recipes/shared_children_files.rb", "lib/capistrano_nrel_ext/recipes/shared_uploads.rb", "lib/capistrano_nrel_ext/recipes/undeploy.rb"]
  s.files = ["Manifest", "Rakefile", "capistrano_nrel_ext.gemspec", "lib/capistrano_nrel_ext/actions/remote_tests.rb", "lib/capistrano_nrel_ext/actions/sample_files.rb", "lib/capistrano_nrel_ext/recipes/apache.rb", "lib/capistrano_nrel_ext/recipes/branches.rb", "lib/capistrano_nrel_ext/recipes/clean_slate.rb", "lib/capistrano_nrel_ext/recipes/cleanup.rb", "lib/capistrano_nrel_ext/recipes/defaults.rb", "lib/capistrano_nrel_ext/recipes/finalize_permissions.rb", "lib/capistrano_nrel_ext/recipes/gem_bundler.rb", "lib/capistrano_nrel_ext/recipes/haproxy.rb", "lib/capistrano_nrel_ext/recipes/jammit.rb", "lib/capistrano_nrel_ext/recipes/maintenance.rb", "lib/capistrano_nrel_ext/recipes/monit.rb", "lib/capistrano_nrel_ext/recipes/previous_release.rb", "lib/capistrano_nrel_ext/recipes/proxymachine.rb", "lib/capistrano_nrel_ext/recipes/rails.rb", "lib/capistrano_nrel_ext/recipes/redhat.rb", "lib/capistrano_nrel_ext/recipes/sandboxes.rb", "lib/capistrano_nrel_ext/recipes/server_ports.rb", "lib/capistrano_nrel_ext/recipes/server_process_registry.rb", "lib/capistrano_nrel_ext/recipes/servlets.rb", "lib/capistrano_nrel_ext/recipes/setup.rb", "lib/capistrano_nrel_ext/recipes/shared_children.rb", "lib/capistrano_nrel_ext/recipes/shared_children_files.rb", "lib/capistrano_nrel_ext/recipes/shared_uploads.rb", "lib/capistrano_nrel_ext/recipes/undeploy.rb"]
  s.homepage = %q{}
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "Capistrano_nrel_ext"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{capistrano_nrel_ext}
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
