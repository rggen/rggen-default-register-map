# frozen_string_literal: true

RgGen.define_simple_feature(:bit_field, :name) do
  register_map do
    property :name, default: -> { register.name }
    property :full_name, forward_to: :get_full_name

    input_pattern variable_name

    build do |value|
      pattern_matched? ||
        (error "illegal input value for bit field name: #{value.inspect}")
      @name = match_data.to_s
    end

    verify(:feature) do
      error_condition { duplicated_name? }
      message { "duplicated bit field name: #{name}" }
    end

    printable :name

    private

    def get_full_name(separator = '.')
      [register.full_name(separator), *@name].join(separator)
    end

    def duplicated_name?
      bit_fields.any? { |bit_field| bit_field.name == name }
    end
  end
end
