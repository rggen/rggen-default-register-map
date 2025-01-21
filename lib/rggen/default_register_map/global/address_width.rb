# frozen_string_literal: true

RgGen.define_simple_feature(:global, :address_width) do
  configuration do
    property :address_width, default: 32

    build do |value|
      @address_width =
        to_int(value) { |v| "cannot convert #{v.inspect} into address width" }
    end

    verify(:feature) do
      error_condition { !address_width.positive? }
      message do
        "non positive value is not allowed for address width: #{address_width}"
      end
    end

    printable :address_width
  end
end
