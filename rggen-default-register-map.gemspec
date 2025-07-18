# frozen_string_literal: true

require File.expand_path('lib/rggen/default_register_map/version', __dir__)

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
    'bug_tracker_uri' => 'https://github.com/rggen/rggen/issues',
    'mailing_list_uri' => 'https://groups.google.com/d/forum/rggen',
    'rubygems_mfa_required' => 'true',
    'source_code_uri' => 'https://github.com/rggen/rggen-default-register-map',
    'wiki_uri' => 'https://github.com/rggen/rggen/wiki'
  }

  spec.files =
    `git ls-files lib LICENSE CODE_OF_CONDUCT.md README.md`.split($RS)
  spec.require_paths = ['lib']

  spec.required_ruby_version = Gem::Requirement.new('>= 3.1')

  spec.add_dependency 'erubi', '>= 1.7'
  spec.add_dependency 'facets', '>= 3.0'
end
