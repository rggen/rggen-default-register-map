# frozen_string_literal: true

RgGen.define_simple_feature(:register, :name) do
  register_map do
    property :name

    input_pattern variable_name

    build do |value|
      @name =
        if pattern_matched?
          match_data.to_s
        else
          error "illegal input value for register name: #{value.inspect}"
        end
    end

    verify(:feature) do
      error_condition { !name }
      message { 'no register name is given' }
    end

    verify(:feature) do
      error_condition { duplicated_name? }
      message { "duplicated register name: #{name}" }
    end

    printable :name

    private

    def duplicated_name?
      files_and_registers
        .any? { |file_or_register| file_or_register.name == name }
    end
  end
end
