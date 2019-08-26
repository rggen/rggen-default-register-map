# frozen_string_literal: true

RgGen.define_list_item_feature(:bit_field, :type, [:w0trg, :w1trg]) do
  register_map do
    write_only
    non_volatile
  end
end
