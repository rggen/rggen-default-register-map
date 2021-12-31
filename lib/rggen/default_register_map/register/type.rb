# frozen_string_literal: true

RgGen.define_list_feature(:register, :type) do
  register_map do
    base_feature do
      define_helpers do
        def writable?(&block)
          @writability = block
        end

        def readable?(&block)
          @readability = block
        end

        attr_reader :writability
        attr_reader :readability

        def no_bit_fields
          @no_bit_fields = true
        end

        def need_bit_fields?
          !@no_bit_fields
        end

        def settings
          @settings ||= {}
        end

        def support_array_register
          settings[:support_array] = true
        end

        def support_shared_address
          settings[:support_shared_address] = true
        end
      end

      property :type, default: :default
      property :match_type?, body: ->(register) { register.type == type }
      property :writable?, initial: -> { writability }
      property :readable?, initial: -> { readability }
      property :reserved?, initial: -> { !(writable? || readable?) }
      property :settings, forward_to_helper: true

      build do |value|
        @type = value[:type]
        @options = value[:options]
        helper.need_bit_fields? || register.need_no_children
      end

      post_build do
        reserved? && register.document_only
      end

      verify(:component) do
        error_condition do
          helper.need_bit_fields? && register.bit_fields.empty?
        end
        message { 'no bit fields are given' }
      end

      printable :type

      private

      attr_reader :options

      def writability
        block = helper.writability || -> { register.bit_fields.any?(&:writable?) }
        instance_exec(&block)
      end

      def readability
        block = helper.readability || -> { register.bit_fields.any?(&:readable?) }
        instance_exec(&block)
      end
    end

    default_feature do
      support_array_register

      verify(:feature) do
        error_condition { @type }
        message { "unknown register type: #{@type.inspect}" }
      end
    end

    factory do
      convert_value do |value|
        type, options = split_input_value(value)
        { type: find_type(type), options: Array(options) }
      end

      def target_feature_key(cell)
        (!cell.empty_value? && cell.value[:type]) || nil
      end

      private

      def split_input_value(value)
        if value.is_a?(String)
          split_string_value(value)
        else
          input_value = Array(value)
          [input_value[0], input_value[1..]]
        end
      end

      def split_string_value(value)
        type, options = split_string(value, ':', 2)
        [type, split_string(options, /[,\n]/, 0)]
      end

      def split_string(value, separator, limit)
        value&.split(separator, limit)&.map(&:strip)
      end

      def find_type(type)
        types = target_features.keys
        types.find(&type.to_sym.method(:casecmp?)) || type
      end
    end
  end
end
