# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rggen/default_register_map/version'

Gem::Specification.new do |spec|
  spec.name = 'rggen-default-register-map'
  spec.version = RgGen::DefaultRegisterMap::VERSION
  spec.authors = ['Taichi Ishitani']
  spec.email = ['rggen@googlegroups.com']

  spec.summary =
    "rggen-default-register-map-#{RgGen::DefaultRegisterMap::VERSION}"
  spec.description = 'Default register map implementation for RgGen'
  spec.homepage = 'https://github.com/rggen/rggen-default-register-map'
  spec.license = 'MIT'

  spec.metadata = {
    'bug_tracker_uri' => 'https://github.com/rggen/rggen-default-register-map/issues',
    'mailing_list_uri' => 'https://groups.google.com/d/forum/rggen',
    'source_code_uri' => 'https://github.com/rggen/rggen-default-register-map',
    'wiki_uri' => 'https://github.com/rggen/rggen/wiki'
  }

  spec.files =
    `git ls-files lib LICENSE CODE_OF_CONDUCT.md README.md`.split($RS)
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.3'

  spec.add_development_dependency 'bundler'
end
