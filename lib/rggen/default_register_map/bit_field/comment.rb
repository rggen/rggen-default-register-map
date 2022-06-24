# frozen_string_literal: true

RgGen.define_simple_feature(:bit_field, :comment) do
  register_map(&RgGen::DefaultRegisterMap::COMMENT)
end
