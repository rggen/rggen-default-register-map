# frozen_string_literal: true

RgGen.define_list_item_feature(:bit_field, :type, [:woc, :wos]) do
  register_map do
    write_only
    initial_value require: true
  end
end
