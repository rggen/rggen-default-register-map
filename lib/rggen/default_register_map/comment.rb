# frozen_string_literal: true

module RgGen
  module DefaultRegisterMap
    COMMENT = proc do
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
