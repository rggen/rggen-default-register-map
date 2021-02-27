# frozen_string_literal: true

RgGen.define_list_item_feature(:register, :type, :reserved) do
  register_map do
    writable? { false }
    readable? { false }
    no_bit_fields
    support_array_register
  end
end
