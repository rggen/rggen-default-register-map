# frozen_string_literal: true

RgGen.define_list_feature(:bit_field, :type) do
  register_map do
    base_feature do
      define_helpers do
        def read_write
          @readable = true
          @writable = true
        end

        def read_only
          @readable = true
          @writable = false
        end

        def write_only
          @readable = false
          @writable = true
        end

        def reserved
          @readable = false
          @writable = false
        end

        def readable?
          @readable.nil? || @readable
        end

        def writable?
          @writable.nil? || @writable
        end

        def read_only?
          readable? && !writable?
        end

        def write_only?
          writable? && !readable?
        end

        def reserved?
          !(readable? || writable?)
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
      property :readable?, forward_to_helper: true
      property :writable?, forward_to_helper: true
      property :read_only?, forward_to_helper: true
      property :write_only?, forward_to_helper: true
      property :reserved?, forward_to_helper: true
      property :volatile?, initial: -> { volatility }

      build { |value| @type = value }

      printable :type

      private

      def volatility
        helper.volatility.nil? || instance_exec(&helper.volatility)
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
      convert_value do |value|
        types = target_features.keys
        types.find(&value.to_sym.method(:casecmp?)) || value
      end

      def target_feature_key(cell)
        cell.value
      end
    end
  end
end
