# frozen_string_literal: true

RgGen.define_simple_feature(:global, :enable_wide_register) do
  configuration do
    property :enable_wide_register?, default: false

    input_pattern [/true|on|yes/i, /false|off|no/i],
                  match_automatically: false

    ignore_empty_value false

    build do |value|
      @enable_wide_register =
        if [true, false].include?(value)
          value
        elsif match_pattern(value)
          [true, false][match_index]
        else
          error "cannot convert #{value.inspect} into boolean"
        end
    end

    printable :enable_wide_register do
      enable_wide_register?
    end
  end
end
