# frozen_string_literal: true

RgGen.define_simple_feature(:register_file, :comment) do
  register_map(&RgGen::DefaultRegisterMap::COMMENT)
end
