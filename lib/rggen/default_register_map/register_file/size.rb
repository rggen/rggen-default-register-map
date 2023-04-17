# frozen_string_literal: true

RgGen.define_feature(:register_file, :size) do
  register_map do
    feature do
      property :size
      property :entry_byte_size, forward_to: :calc_entry_byte_size
      property :total_byte_size, forward_to: :calc_total_byte_size
      property :array?, body: -> { !@size.nil? }
      property :array_size, forward_to: :size
      property :count, forward_to: :calc_count

      build do |values, options|
        @size = parse_register_file_size(values)
        @step = parse_step_size(options)
      end

      verify(:feature) do
        error_condition { array? && !size.all?(&:positive?) }
        message do
          "non positive value(s) are not allowed for register file size: #{size}"
        end
      end

      verify(:component) do
        error_condition { @step && @step < actual_byte_size }
        message do
          "step size is less than actual byte size: #{@step}"
        end
      end

      verify(:component) do
        error_condition { @step && (@step % configuration.byte_width).positive? }
        message do
          "step size is not multiple of bus width: #{@step}"
        end
      end

      private

      def parse_register_file_size(values)
        values.map do |value|
          Integer(value)
        rescue ArgumentError, TypeError
          error "cannot convert #{value.inspect} into register file size"
        end
      end

      def parse_step_size(options)
        options.key?(:step) && Integer(options[:step]) || nil
      rescue ArgumentError, TypeError
        error "cannot convert #{options[:step]} into step size"
      end

      def calc_entry_byte_size
        @step || actual_byte_size
      end

      def actual_byte_size
        register_file.files_and_registers
          .map { |r| r.offset_address + r.total_byte_size }.max
      end

      def calc_total_byte_size
        total_entries * calc_entry_byte_size
      end

      def calc_count(whole_count = true)
        (whole_count ? total_entries : 1) *
          register_file.files_and_registers.sum(&:count)
      end

      def total_entries
        size&.inject(:*) || 1
      end
    end

    factory do
      value_format :option_hash,
                   multiple_values: true, allowed_options: [:step]
    end
  end
end
