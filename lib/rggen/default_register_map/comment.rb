# frozen_string_literal: true

module RgGen
  module DefaultRegisterMap
    COMMENT = proc do
      property :comment, initial: -> { '' }

      build do |value|
        @comment =
          (array?(value) && value.join("\n") || value.to_s).chomp
      end

      printable :comment do
        comment.empty? ? nil : comment
      end
    end
  end
end
