# frozen_string_literal: true

RgGen.define_list_item_feature(:bit_field, :type, :rowo) do
  register_map do
    read_write
    volatile
    initial_value require: true
    reference use: true
  end
end
