# frozen_string_literal: true

RgGen.define_list_item_feature(:bit_field, :type, :rc) do
  register_map do
    read_only
    reference use: true
    initial_value require: true
  end
end
