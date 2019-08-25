# frozen_string_literal: true

require_relative 'default_register_map/version'

module RgGen
  module DefaultRegisterMap
    FEATURES = [
      'default_register_map/bit_field/name',
      'default_register_map/global/address_width',
      'default_register_map/global/bus_width',
      'default_register_map/register/name',
      'default_register_map/register_block/name'
    ].freeze

    def self.load_features
      FEATURES.each { |file| require_relative file }
    end

    def self.setup(_builder)
      load_features
    end
  end

  setup :'default-register_map', DefaultRegisterMap
end
