# frozen_string_literal: true

require 'rggen/default_register_map'

RgGen.setup :'rggen-defualt-register-map', RgGen::DefaultRegisterMap do |builder|
  builder.enable :global, [:bus_width, :address_width]
  builder.enable :register_block, [:name, :byte_size]
  builder.enable :register, [:name, :offset_address, :size, :type]
  builder.enable :register, :type, [:external, :indirect]
  builder.enable :bit_field, [
    :name, :bit_assignment, :type, :initial_value, :reference, :comment
  ]
  builder.enable :bit_field, :type, [
    :rc, :reserved, :ro, :rof, :rs,
    :rw, :rwc, :rwe, :rwl, :rws,
    :w0c, :w0s, :w0trg, :w1c, :w1s, :w1trg, :wo
  ]
end
