# frozen_string_literal: true

RgGen.define_simple_feature(:register, :comment) do
  register_map(&RgGen::DefaultRegisterMap::COMMENT)
end
