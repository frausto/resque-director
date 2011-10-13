# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{resque-director}
  s.version = "2.2.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = [%q{Nolan Frausto}]
  s.date = %q{2011-10-13}
  s.description = %q{resque plugin for automatically scaling workers based on the amount of time it takes a job to go through the queue and/or the length of the queue }
  s.email = %q{nrfrausto@gmail.com}
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.rdoc"
  ]
  s.files = [
    "Gemfile",
    "HISTORY.md",
    "LICENSE.txt",
    "README.rdoc",
    "Rakefile",
    "VERSION",
    "lib/resque-director.rb",
    "lib/resque/plugins/director.rb",
    "lib/resque/plugins/director/config.rb",
    "lib/resque/plugins/director/push_pop.rb",
    "lib/resque/plugins/director/scaler.rb",
    "lib/resque/plugins/director/worker_tracker.rb",
    "resque-director.gemspec",
    "spec/redis-test.conf",
    "spec/resque/plugins/director/config_spec.rb",
    "spec/resque/plugins/director/push_pop_spec.rb",
    "spec/resque/plugins/director/scaler_spec.rb",
    "spec/resque/plugins/director/worker_tracker_spec.rb",
    "spec/resque/plugins/director_spec.rb",
    "spec/spec_helper.rb",
    "spec/support/jobs.rb"
  ]
  s.homepage = %q{http://github.com/frausto/resque-director}
  s.licenses = [%q{MIT}]
  s.require_paths = [%q{lib}]
  s.rubygems_version = %q{1.8.6}
  s.summary = %q{A resque plugin for automatically scaling workers}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<resque>, ["~> 1.10"])
      s.add_development_dependency(%q<rspec>, ["~> 2.3.0"])
      s.add_development_dependency(%q<bundler>, ["~> 1.0.0"])
      s.add_development_dependency(%q<jeweler>, ["~> 1.6.4"])
      s.add_development_dependency(%q<rcov>, [">= 0"])
      s.add_development_dependency(%q<yajl-ruby>, ["~> 0.8.2"])
      s.add_development_dependency(%q<json>, ["~> 1.5.3"])
    else
      s.add_dependency(%q<resque>, ["~> 1.10"])
      s.add_dependency(%q<rspec>, ["~> 2.3.0"])
      s.add_dependency(%q<bundler>, ["~> 1.0.0"])
      s.add_dependency(%q<jeweler>, ["~> 1.6.4"])
      s.add_dependency(%q<rcov>, [">= 0"])
      s.add_dependency(%q<yajl-ruby>, ["~> 0.8.2"])
      s.add_dependency(%q<json>, ["~> 1.5.3"])
    end
  else
    s.add_dependency(%q<resque>, ["~> 1.10"])
    s.add_dependency(%q<rspec>, ["~> 2.3.0"])
    s.add_dependency(%q<bundler>, ["~> 1.0.0"])
    s.add_dependency(%q<jeweler>, ["~> 1.6.4"])
    s.add_dependency(%q<rcov>, [">= 0"])
    s.add_dependency(%q<yajl-ruby>, ["~> 0.8.2"])
    s.add_dependency(%q<json>, ["~> 1.5.3"])
  end
end

