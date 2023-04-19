# frozen_string_literal: true

RgGen.define_simple_feature(:register_block, :byte_size) do
  register_map do
    property :byte_size
    property :local_address_width

    build do |value|
      @byte_size =
        to_int(value) { |v| "cannot convert #{v.inspect} into byte size" }
      @local_address_width = (@byte_size - 1).bit_length
    end

    verify(:feature) do
      error_condition { !byte_size }
      message { 'no byte size is given' }
    end

    verify(:feature) do
      error_condition { !byte_size.positive? }
      message do
        "non positive value is not allowed for byte size: #{byte_size}"
      end
    end

    verify(:feature) do
      error_condition { byte_size > max_byte_size }
      message do
        'input byte size is greater than maximum byte size: ' \
        "input byte size #{byte_size} maximum byte size #{max_byte_size}"
      end
    end

    verify(:feature) do
      error_condition { (byte_size % byte_width).positive? }
      message do
        "byte size is not aligned with bus width(#{bus_width}): #{byte_size}"
      end
    end

    printable :byte_size

    private

    def max_byte_size
      2**configuration.address_width
    end

    def byte_width
      configuration.byte_width
    end

    def bus_width
      configuration.bus_width
    end
  end
end
