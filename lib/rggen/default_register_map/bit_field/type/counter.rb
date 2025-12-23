# frozen_string_literal: true

RgGen.define_list_item_feature(:bit_field, :type, :counter) do
  register_map do
    read_write
    reference use: true, width: 1
    initial_value require: true
  end
end
