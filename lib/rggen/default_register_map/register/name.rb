# frozen_string_literal: true

RgGen.define_simple_feature(:register, :name) do
  register_map do
    property :name
    property :full_name, forward_to: :get_full_name

    input_pattern variable_name

    build do |value|
      pattern_matched? ||
        (error "illegal input value for register name: #{value.inspect}")
      @name = match_data.to_s
    end

    verify(:feature) do
      error_condition { !name }
      message { 'no register name is given' }
    end

    verify(:feature) do
      error_condition { duplicated_name? }
      message { "duplicated register name: #{name}" }
    end

    printable(:name) do
      array_name
    end

    printable(:layer_name) do
      [register_file&.printables&.fetch(:layer_name), array_name]
        .compact.join('.')
    end

    private

    def get_full_name(separator = '.')
      [*register_file&.full_name(separator), name].join(separator)
    end

    def duplicated_name?
      files_and_registers
        .any? { |file_or_register| file_or_register.name == name }
    end

    def array_name
      RgGen::Core::Utility::CodeUtility
        .array_name(name, register.array_size)
    end
  end
end
