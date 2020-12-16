# frozen_string_literal: true

require 'rggen/default_register_map'

RgGen.register_plugin RgGen::DefaultRegisterMap do |builder|
  builder.enable :global, [:bus_width, :address_width]
  builder.enable :register_block, [
    :name, :byte_size, :comment
  ]
  builder.enable :register_file, [
    :name, :offset_address, :size, :comment
  ]
  builder.enable :register, [
    :name, :offset_address, :size, :type, :comment
  ]
  builder.enable :register, :type, [:external, :indirect]
  builder.enable :bit_field, [
    :name, :bit_assignment, :type, :initial_value, :reference, :comment
  ]
  builder.enable :bit_field, :type, [
    :rc, :reserved, :ro, :rof, :rs,
    :rw, :rwc, :rwe, :rwl, :rws,
    :w0c, :w0crs, :w0s, :w0src, :w0t, :w0trg,
    :w1, :w1c, :w1crs, :w1s, :w1src, :w1t, :w1trg, :wo, :wo1,
    :woc, :wos, :wc, :wcrs, :wrc, :wrs, :ws, :wsrc
  ]
end
