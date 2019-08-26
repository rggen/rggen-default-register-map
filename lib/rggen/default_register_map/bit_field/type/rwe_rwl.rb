# frozen_string_literal: true

RgGen.define_list_item_feature(:bit_field, :type, [:rwe, :rwl]) do
  register_map do
    read_write
    volatile? { !bit_field.reference? }
    initial_value require: true
    reference use: true, width: 1
  end
end
