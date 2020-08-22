# frozen_string_literal: true

RgGen.define_list_item_feature(:bit_field, :type, :woc) do
  register_map do
    write_only
    reference use: true
    initial_value require: true
  end
end
