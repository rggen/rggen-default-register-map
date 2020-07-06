# frozen_string_literal: true

RgGen.define_simple_feature(:register_block, :name) do
  register_map do
    property :name

    input_pattern variable_name

    build do |value|
      pattern_matched? ||
        (error "illegal input value for register block name: #{value.inspect}")
      @name = match_data.to_s
    end

    verify(:feature) do
      error_condition { !name }
      message { 'no register block name is given' }
    end

    verify(:feature) do
      error_condition { duplicated_name? }
      message { "duplicated register block name: #{name}" }
    end

    printable :name

    private

    def duplicated_name?
      register_blocks.any? { |register_block| register_block.name == name }
    end
  end
end
