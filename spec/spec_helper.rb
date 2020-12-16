# frozen_string_literal: true

require 'bundler/setup'

require 'rggen/core'
require 'rggen/devtools/spec_helper'

builder = RgGen::Core::Builder.create
RgGen.builder(builder)

RSpec.configure do |config|
  RgGen::Devtools::SpecHelper.setup(config)
end

require 'rggen/default_register_map'
RgGen::DefaultRegisterMap.plugin_spec.activate(builder)
