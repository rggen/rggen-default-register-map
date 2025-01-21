# frozen_string_literal: true

module RgGen
  module DefaultRegisterMap
    COMMENT = proc do
      property :comment, forward_to: :processed_comment

      build do |value|
        @raw_comment =
          (array?(value) && value.join("\n") || value.to_s).chomp
      end

      printable :comment do
        comment.empty? ? nil : comment
      end

      private

      def processed_comment
        @processed_comment ||=
          if erb_template?
            template = Erubi::Engine.new(@raw_comment)
            instance_eval(template.src, position.to_s, 1)
          elsif @raw_comment
            @raw_comment
          else
            ''
          end
      end

      def erb_template?
        /<%.*%>/.match?(@raw_comment)
      end
    end
  end
end
