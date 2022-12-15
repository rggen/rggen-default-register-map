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

      build do |type, _option|
        @type = type
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
      value_format :value_with_options

      convert_value do |value|
        find_type(value)
      end

      def target_feature_key(value)
        (!value.empty_value? && value) || nil
      end

      private

      def find_type(value)
        types = target_features.keys
        types.find(&value.to_sym.method(:casecmp?)) || value
      end
    end
  end
end
