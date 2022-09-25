# frozen_string_literal: true

require_relative 'default_register_map/version'
require_relative 'default_register_map/comment'

RgGen.setup_plugin :'rggen-default-register-map' do |plugin|
  plugin.version RgGen::DefaultRegisterMap::VERSION
  plugin.files [
    'default_register_map/global/address_width',
    'default_register_map/global/bus_width',
    'default_register_map/global/enable_wide_register',
    'default_register_map/register_block/name',
    'default_register_map/register_block/byte_size',
    'default_register_map/register_block/comment',
    'default_register_map/register_file/name',
    'default_register_map/register_file/offset_address',
    'default_register_map/register_file/size',
    'default_register_map/register_file/comment',
    'default_register_map/register/name',
    'default_register_map/register/offset_address',
    'default_register_map/register/size',
    'default_register_map/register/type',
    'default_register_map/register/type/external',
    'default_register_map/register/type/indirect',
    'default_register_map/register/type/reserved',
    'default_register_map/register/comment',
    'default_register_map/bit_field/name',
    'default_register_map/bit_field/bit_assignment',
    'default_register_map/bit_field/type',
    'default_register_map/bit_field/type/custom',
    'default_register_map/bit_field/type/rc',
    'default_register_map/bit_field/type/reserved',
    'default_register_map/bit_field/type/ro_rotrg',
    'default_register_map/bit_field/type/rof',
    'default_register_map/bit_field/type/row0trg_row1trg',
    'default_register_map/bit_field/type/rowo_rowotrg',
    'default_register_map/bit_field/type/rs',
    'default_register_map/bit_field/type/rw_rwtrg_w1_wrc_wrs',
    'default_register_map/bit_field/type/rwc_rws',
    'default_register_map/bit_field/type/rwe_rwl',
    'default_register_map/bit_field/type/w0c_w1c_wc',
    'default_register_map/bit_field/type/w0crs_w1crs_wcrs',
    'default_register_map/bit_field/type/w0s_w1s_ws',
    'default_register_map/bit_field/type/w0src_w1src_wsrc',
    'default_register_map/bit_field/type/w0t_w1t',
    'default_register_map/bit_field/type/w0trg_w1trg',
    'default_register_map/bit_field/type/wo_wo1_wotrg',
    'default_register_map/bit_field/type/woc',
    'default_register_map/bit_field/type/wos',
    'default_register_map/bit_field/initial_value',
    'default_register_map/bit_field/reference',
    'default_register_map/bit_field/comment'
  ]
end
