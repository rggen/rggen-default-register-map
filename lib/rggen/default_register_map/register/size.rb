# frozen_string_literal: true

RgGen.define_simple_feature(:register, :size) do
  register_map do
    property :size
    property :width, initial: -> { calc_width }
    property :byte_width, initial: -> { width / 8 }
    property :byte_size, forward_to: :calc_byte_size
    property :array?, forward_to: :array_register?
    property :array_size, forward_to: :array_registers
    property :count, forward_to: :calc_count

    input_pattern [
      /(#{integer}(:?,#{integer})*)/,
      /\[(#{integer}(:?,#{integer})*)\]/
    ], match_automatically: false

    build do |values|
      @size = parse_values(values)
    end

    verify(:feature) do
      error_condition { size && !size.all?(&:positive?) }
      message do
        "non positive value(s) are not allowed for register size: #{size}"
      end
    end

    verify(:component) do
      error_condition do
        !configuration.enable_wide_register? && byte_width > 8
      end
      message do
        "register width wider than 8 bytes is not allowed: #{byte_width} bytes"
      end
    end

    private

    def parse_values(values)
      Array(
        string?(values) && parse_string_values(values) || values
      ).map(&method(:convert_value))
    end

    def parse_string_values(values)
      if match_pattern(values)
        split_match_data(match_data)
      else
        error "illegal input value for register size: #{values.inspect}"
      end
    end

    def split_match_data(match_data)
      match_data.captures.first.split(',')
    end

    def convert_value(value)
      Integer(value)
    rescue ArgumentError, TypeError
      error "cannot convert #{value.inspect} into register size"
    end

    def calc_width
      bus_width = configuration.bus_width
      if register.bit_fields.empty?
        bus_width
      else
        ((max_msb + bus_width) / bus_width) * bus_width
      end
    end

    def max_msb
      register
        .bit_fields
        .map { |bit_field| bit_field.msb((bit_field.sequence_size || 1) - 1) }
        .max
    end

    def calc_byte_size(whole_size = true, hierarchical: false)
      return byte_width unless whole_size

      include_register = !register.settings[:support_shared_address]
      collect_size(hierarchical, include_register, false).reduce(1, :*) * byte_width
    end

    def array_register?(hierarchical: false)
      return true if hierarchical && register_files.any?(&:array?)
      register.settings[:support_array] && !@size.nil? || false
    end

    def array_registers(hierarchical: false)
      size = collect_size(hierarchical, true, true)
      !size.empty? && size || nil
    end

    def calc_count(whole_count = true)
      if whole_count
        @count ||= collect_size(false, true, true).reduce(1, :*)
      else
        1
      end
    end

    def collect_size(inculde_register_file, include_register, array_only)
      size = []
      collect_register_file_size(size, inculde_register_file)
      collect_register_size(size, include_register, array_only)
      size.compact
    end

    def collect_register_file_size(size, inculde_register_file)
      inculde_register_file &&
        size.concat(register_files.flat_map(&:array_size))
    end

    def collect_register_size(size, include_register, array_only)
      @size && include_register && (!array_only || array_register?) &&
        size.concat(@size)
    end
  end
end
