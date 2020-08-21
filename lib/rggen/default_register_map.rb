# frozen_string_literal: true

require_relative 'default_register_map/version'

module RgGen
  module DefaultRegisterMap
    PLUGIN_NAME = :'rggen-default-register-map'

    FEATURES = [
      'default_register_map/bit_field/bit_assignment',
      'default_register_map/bit_field/initial_value',
      'default_register_map/bit_field/name',
      'default_register_map/bit_field/reference',
      'default_register_map/bit_field/type',
      'default_register_map/bit_field/type/rc',
      'default_register_map/bit_field/type/reserved',
      'default_register_map/bit_field/type/ro',
      'default_register_map/bit_field/type/rof',
      'default_register_map/bit_field/type/rs',
      'default_register_map/bit_field/type/rw_w1_wc_wcrs_wrc_wrs_ws_wsrc',
      'default_register_map/bit_field/type/rwc_rws',
      'default_register_map/bit_field/type/rwe_rwl',
      'default_register_map/bit_field/type/w0c_w1c',
      'default_register_map/bit_field/type/w0crs_w1crs_w0src_w1src_w0t_w1t',
      'default_register_map/bit_field/type/w0s_w1s',
      'default_register_map/bit_field/type/w0trg_w1trg',
      'default_register_map/bit_field/type/wo_wo1_woc_wos',
      'default_register_map/common/comment',
      'default_register_map/global/address_width',
      'default_register_map/global/bus_width',
      'default_register_map/register/name',
      'default_register_map/register/offset_address',
      'default_register_map/register/size',
      'default_register_map/register/type',
      'default_register_map/register/type/external',
      'default_register_map/register/type/indirect',
      'default_register_map/register_block/byte_size',
      'default_register_map/register_block/name',
      'default_register_map/register_file/name',
      'default_register_map/register_file/offset_address',
      'default_register_map/register_file/size'
    ].freeze

    def self.load_features
      FEATURES.each { |file| require_relative file }
    end

    def self.default_setup(_builder)
      load_features
    end
  end
end
