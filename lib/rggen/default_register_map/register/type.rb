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

        def byte_size(&block)
          settings[:byte_size] = block
        end

        def support_overlapped_address
          settings[:support_overlapped_address] = true
        end
      end

      property :type, default: :default
      property :match_type?, body: ->(register) { register.type == type }
      property :writable?, initial: -> { writability }
      property :readable?, initial: -> { readability }
      property :settings, forward_to_helper: true

      build do |value|
        @type = value[:type]
        @options = value[:options]
        helper.need_bit_fields? || register.need_no_children
      end

      verify(:component) do
        error_condition do
          helper.need_bit_fields? && register.bit_fields.empty?
        end
        message { 'no bit fields are given' }
      end

      private

      attr_reader :options

      def writability
        instance_exec(&(helper.writability || default_writability))
      end

      def default_writability
        -> { register.bit_fields.any?(&:writable?) }
      end

      def readability
        instance_exec(&(helper.readability || default_readability))
      end

      def default_readability
        lambda do
          block = ->(bit_field) { bit_field.readable? || bit_field.reserved? }
          register.bit_fields.any?(&block)
        end
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
          [input_value[0], input_value[1..-1]]
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
