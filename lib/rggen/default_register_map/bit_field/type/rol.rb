# frozen_string_literal: true

RgGen.define_list_item_feature(:bit_field, :type, :rol) do
  register_map do
    read_only
    initial_value require: true
    reference use: true, width: 1
  end
end
