# frozen_string_literal: true

RgGen.define_list_item_feature(:bit_field, :type, [:row0trg, :row1trg]) do
  register_map do
    read_write
    reference use: true
  end
end
