# frozen_string_literal: true

RgGen.define_list_item_feature(:register, :type, :rw) do
  register_map do
    writable? { true }
    readable? { true }
    support_array_register
  end
end
