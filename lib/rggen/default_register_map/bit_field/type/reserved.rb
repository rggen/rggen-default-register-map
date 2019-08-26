# frozen_string_literal: true

RgGen.define_list_item_feature(:bit_field, :type, :reserved) do
  register_map do
    reserved
    non_volatile
  end
end
