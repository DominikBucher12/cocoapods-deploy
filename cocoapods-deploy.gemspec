# -*- encoding: utf-8 -*-
# stub: cocoapods-deploy 0.0.12 ruby lib

Gem::Specification.new do |s|
  s.name = "cocoapods-deploy"
  s.version = "0.0.12"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["James Campbell"]
  s.date = "2016-03-07"
  s.description = "Implement's bundler's --deployment functionality in CocoaPods."
  s.email = ["james@supmenow.com"]
  s.files = [".gitignore", "Gemfile", "LICENSE.txt", "README.md", "Rakefile", "cocoapods-deploy.gemspec", "lib/cocoapods-deploy/command.rb", "lib/cocoapods-deploy/command/deploy.rb", "lib/cocoapods-deploy/deploy_transformer.rb", "lib/cocoapods-deploy/deploy_analyzer.rb", "lib/cocoapods-deploy/deploy_downloader.rb", "lib/cocoapods-deploy/deploy_installer.rb", "lib/cocoapods-deploy/gem_version.rb", "lib/cocoapods-deploy.rb", "lib/cocoapods_plugin.rb", "spec/spec_helper.rb", "lib/cocoapods-deploy/patches/write_lockfile_patch.rb"]
  s.homepage = "https://github.com/jcampbell05/cocoapods-deploy"
  s.licenses = ["MIT"]
  s.rubygems_version = "2.4.8"
  s.summary = "Implement's bundler's --deployment functionality in CocoaPods."
  s.test_files = ["spec/command/deploy_spec.rb", "spec/spec_helper.rb"]

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<bundler>, ["~> 1.3"])
      s.add_development_dependency(%q<rake>, [">= 0"])
    else
      s.add_dependency(%q<bundler>, ["~> 1.3"])
      s.add_dependency(%q<rake>, [">= 0"])
    end
  else
    s.add_dependency(%q<bundler>, ["~> 1.3"])
    s.add_dependency(%q<rake>, [">= 0"])
  end
end
