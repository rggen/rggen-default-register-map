# frozen_string_literal: true

RgGen.define_list_item_feature(:bit_field, :type, [:rw, :w1]) do
  register_map do
    read_write
    non_volatile
    initial_value require: true
  end
end
