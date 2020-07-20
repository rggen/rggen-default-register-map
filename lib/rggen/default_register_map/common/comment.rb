# frozen_string_literal: true

[:register_block, :register_file, :register, :bit_field].each do |layer|
  RgGen.define_simple_feature(layer, :comment) do
    register_map do
      property :comment, initial: -> { '' }

      build do |value|
        @comment =
          (value.is_a?(Array) && value.join("\n") || value.to_s).chomp
      end

      printable :comment do
        comment.empty? ? nil : comment
      end
    end
  end
end
