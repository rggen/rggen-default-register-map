# frozen_string_literal: true

RgGen.define_feature(:register, :size) do
  register_map do
    feature do
      property :size
      property :width, initial: -> { calc_width }
      property :byte_width, initial: -> { width / 8 }
      property :entry_byte_size, body: -> { @step || byte_width }
      property :total_byte_size, forward_to: :calc_total_byte_size
      property :array?, forward_to: :array_register?
      property :array_size, forward_to: :array_registers
      property :count, forward_to: :calc_count

      build do |values, options|
        @size = parse_register_size(values)
        @step = parse_step_size(options)
      end

      verify(:feature) do
        error_condition { size && !size.all?(&:positive?) }
        message do
          "non positive value(s) are not allowed for register size: #{size}"
        end
      end

      verify(:component) do
        error_condition { @step && !array_register? }
        message do
          'step size cannot be specified for non-array register'
        end
      end

      verify(:component) do
        error_condition { @step && @step < byte_width }
        message do
          "step size is less than register width: #{@step}"
        end
      end

      verify(:component) do
        error_condition { @step && (@step % register_block.byte_width).positive? }
        message do
          "step size is not multiple of bus width: #{@step}"
        end
      end

      verify(:component) do
        error_condition do
          !configuration.enable_wide_register? && entry_byte_size > 8
        end
        message do
          "register width wider than 8 bytes is not allowed: #{entry_byte_size} bytes"
        end
      end

      private

      def parse_register_size(values)
        values.map do |value|
          to_int(value) { |v| "cannot convert #{v.inspect} into register size" }
        end
      end

      def parse_step_size(options)
        return unless options.key?(:step)

        to_int(options[:step]) { |v| "cannot convert #{v.inspect} into step size" }
      end

      def calc_width
        bus_width = register_block.bus_width
        if register.bit_fields.empty?
          bus_width
        else
          ((max_msb + bus_width) / bus_width) * bus_width
        end
      end

      def max_msb
        register
          .bit_fields
          .map { |bit_field| bit_field.msb(-1) }
          .max
      end

      def calc_total_byte_size(hierarchical: false)
        include_register = !register.settings[:support_shared_address]
        byte_size = entry_byte_size
        collect_size(hierarchical, include_register, false).reduce(1, :*) * byte_size
      end

      def array_register?(hierarchical: false)
        return true if hierarchical && register_files.any?(&:array?)
        register.settings.fetch(:support_array, false) && !@size.nil?
      end

      def array_registers(hierarchical: false)
        size = collect_size(hierarchical, true, true)
        !size.empty? && size || nil
      end

      def calc_count(whole_count = true)
        whole_count && (@count ||= calc_whole_count) || 1
      end

      def calc_whole_count
        collect_size(false, true, true).reduce(1, :*)
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

    factory do
      value_format :option_hash,
                   multiple_values: true, allowed_options: [:step]
    end
  end
end
