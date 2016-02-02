# coding: utf-8
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)
require 'mx-validator/version'

Gem::Specification.new do |spec|
  spec.add_development_dependency 'bundler', '~> 1.0'
  spec.authors = ['Haris Krajina']
  spec.description = %q{MX validator is gem for verifying email addresses via MX records.}
  spec.email = 'haris.krajina@gmail.com'
  spec.files = %w(README.md Gemfile mx-validator.gemspec)
  spec.files += Dir.glob("bin/**/*")
  spec.files += Dir.glob("lib/**/*.rb")
  spec.files += Dir.glob("spec/**/*")
  spec.homepage = 'https://github.com/hkraji/mx-validator'
  spec.licenses = ['MIT']
  spec.name = 'mx-validator'
  spec.require_paths = ['lib']
  spec.required_rubygems_version = '>= 1.3.5'
  spec.summary = spec.description
  spec.test_files = Dir.glob("spec/**/*")
  spec.version = MxValidator::VERSION

  spec.add_dependency 'dnsruby', '>= 1.5.4'
end