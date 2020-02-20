$:.unshift File.join(File.dirname(__FILE__), 'lib')
require 'docker/remote/version'

Gem::Specification.new do |s|
  s.name     = 'docker-remote'
  s.version  = ::Docker::Remote::VERSION
  s.authors  = ['Cameron Dutro']
  s.email    = ['camertron@gmail.com']
  s.homepage = 'http://github.com/camertron/docker-remote'

  s.description = s.summary = 'A Ruby client for communicating with the Docker HTTP API v2.'

  s.platform = Gem::Platform::RUBY

  s.require_path = 'lib'
  s.files = Dir['{lib,spec}/**/*', 'Gemfile', 'CHANGELOG.md', 'README.md', 'Rakefile', 'docker-remote.gemspec']
end
