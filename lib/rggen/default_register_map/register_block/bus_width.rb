# frozen_string_literal: true

RgGen.define_simple_feature(:register_block, :bus_width) do
  [:configuration, :register_map].each do |component_type|
    component(component_type) do
      build do |value|
        @bus_width =
          to_int(value) { |v| "cannot convert #{v.inspect} into bus width" }
      end

      verify(:feature) do
        error_condition { bus_width < 8 }
        message { "input bus width is less than 8: #{bus_width}" }
      end

      verify(:feature) do
        error_condition { !power_of_2?(bus_width) }
        message { "input bus width is not power of 2: #{bus_width}" }
      end

      printable :bus_width

      private

      def power_of_2?(value)
        value.positive? && (value & value.pred).zero?
      end
    end
  end

  configuration do
    property :bus_width, default: 32
  end

  register_map do
    property :bus_width, default: -> { configuration.bus_width }
    property :byte_width, initial: -> { bus_width / 8 }

    verify(:feature) do
      error_condition { bus_width > max_bus_width }
      message do
        'input bus width is grater than maximum bus width: ' \
        "bus width #{bus_width} maximum bus width #{max_bus_width}"
      end
    end

    def position
      super || configuration.feature(:bus_width).position
    end

    private

    def max_bus_width
      2**(configuration.address_width + 3)
    end
  end
end
