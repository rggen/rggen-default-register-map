# frozen_string_literal: true

RgGen.define_list_feature(:bit_field, :type) do
  register_map do
    base_feature do
      define_helpers do
        def read_write
          accessibility[:read] = -> { true }
          accessibility[:write] = -> { true }
        end

        def read_only
          accessibility[:read] = -> { true }
          accessibility[:write] = -> { false }
        end

        def write_only
          accessibility[:read] = -> { false }
          accessibility[:write] = -> { true }
        end

        def reserved
          accessibility[:read] = -> { false }
          accessibility[:write] = -> { false }
        end

        def readable?(&block)
          accessibility[:read] = block
        end

        def writable?(&block)
          accessibility[:write] = block
        end

        def accessibility
          @accessibility ||= {}
        end

        def volatile
          @volatility = -> { true }
        end

        def non_volatile
          @volatility = -> { false }
        end

        def volatile?(&block)
          @volatility = block
        end

        attr_reader :volatility

        def settings
          @settings ||= {}
        end

        def initial_value(**setting)
          settings[:initial_value] = setting
        end

        def reference(**setting)
          settings[:reference] = setting
        end
      end

      property :type
      property :settings, forward_to_helper: true
      property :readable?, body: -> { accessibility(:read) }
      property :writable?, body: -> { accessibility(:write) }
      property :read_only?, body: -> { readable? && !writable? }
      property :write_only?, body: -> { !readable? && writable? }
      property :reserved?, body: -> { !readable? && !writable? }
      property :volatile?, body: -> { volatility }

      build do |value|
        @type = value
      end

      post_build do
        reserved? && bit_field.document_only
      end

      printable :type

      private

      def accessibility(access)
        body = helper.accessibility[access]
        body.nil? || instance_exec(&body)
      end

      def volatility
        body = helper.volatility
        body.nil? || instance_exec(&body)
      end
    end

    default_feature do
      verify(:feature) do
        error_condition { !type }
        message { 'no bit field type is given' }
      end

      verify(:feature) do
        error_condition { type }
        message { "unknown bit field type: #{type.inspect}" }
      end
    end

    factory do
      allow_options

      convert_value do |value|
        types = target_features.keys
        types.find(&value.to_sym.method(:casecmp?)) || value
      end

      def target_feature_key(cell)
        cell
      end
    end
  end
end
