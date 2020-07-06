# frozen_string_literal: true

RgGen.define_simple_feature(:register_file, :size) do
  register_map do
    property :size
    property :byte_size, forward_to: :calc_byte_size
    property :array?, body: -> { !@size.nil? }
    property :array_size, forward_to: :size
    property :count, forward_to: :calc_count

    input_pattern [
      /(#{integer}(:?,#{integer})*)/,
      /\[(#{integer}(:?,#{integer})*)\]/
    ], match_automatically: false

    build do |values|
      @size =
        (values.is_a?(String) && parse_string_value(values) || Array(values))
          .map(&method(:convert_value))
    end

    verify(:feature) do
      error_condition { array? && !size.all?(&:positive?) }
      message do
        "non positive value(s) are not allowed for register file size: #{size}"
      end
    end

    private

    def parse_string_value(value)
      match_pattern(value) && match_data.captures.first.split(',') ||
        (error "illegal input value for register file size: #{value.inspect}")
    end

    def convert_value(value)
      Integer(value)
    rescue ArgumentError, TypeError
      error "cannot convert #{value.inspect} into register file size"
    end

    def calc_byte_size(whole_size = true)
      (whole_size ? total_entries : 1) * entry_byte_size
    end

    def entry_byte_size
      register_file.files_and_registers
        .map { |r| r.offset_address + r.byte_size }.max
    end

    def calc_count(whole_count = true)
      (whole_count ? total_entries : 1) *
        register_file.files_and_registers.sum(&:count)
    end

    def total_entries
      size&.inject(:*) || 1
    end
  end
end
