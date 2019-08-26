# frozen_string_literal: true

RgGen.define_list_item_feature(:bit_field, :type, :rof) do
  register_map do
    read_only
    non_volatile
    initial_value require: true
  end
end
