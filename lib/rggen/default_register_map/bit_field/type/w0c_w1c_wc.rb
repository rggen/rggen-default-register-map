# frozen_string_literal: true

RgGen.define_list_item_feature(:bit_field, :type, [:w0c, :w1c, :wc]) do
  register_map do
    read_write
    reference use: true
    initial_value require: true
  end
end
