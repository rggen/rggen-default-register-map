# frozen_string_literal: true

RgGen.define_simple_feature(:register_block, :comment) do
  register_map(&RgGen::DefaultRegisterMap::COMMENT)
end
