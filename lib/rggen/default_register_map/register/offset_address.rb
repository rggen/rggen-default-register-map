# frozen_string_literal: true

RgGen.define_simple_feature(:register, :offset_address) do
  register_map do
    property :offset_address, initial: -> { default_offset_address }
    property :address_range, initial: -> { start_address..end_address }
    property :overlap?, forward_to: :overlap_address_range?

    build do |value|
      @offset_address =
        begin
          Integer(value)
        rescue ArgumentError, TypeError
          error "cannot convert #{value.inspect} into offset address"
        end
    end

    verify(:feature) do
      error_condition { offset_address.negative? }
      message { "offset address is less than 0: #{offset_address}" }
    end

    verify(:feature) do
      error_condition { (offset_address % byte_width).nonzero? }
      message do
        "offset address is not aligned with bus width(#{bus_width}): "\
        "0x#{offset_address.to_s(16)}"
      end
    end

    verify(:component) do
      error_condition { end_address > register_block.byte_size }
      message do
        'offset address range exceeds byte size of register block' \
        "(#{register_block.byte_size}): " \
        "0x#{start_address.to_s(16)}-0x#{end_address.to_s(16)}"
      end
    end

    verify(:component) do
      error_condition do
        files_and_registers.any? do |file_or_register|
          overlap_address_range?(file_or_register) &&
            support_unique_range_only?(file_or_register)
        end
      end
      message do
        'offset address range overlaps with other offset address range: ' \
        "0x#{start_address.to_s(16)}-0x#{end_address.to_s(16)}"
      end
    end

    printable(:offset_address) do
      [start_address, end_address]
        .map(&method(:printable_address)).join(' - ')
    end

    private

    def default_offset_address
      register.component_index.zero? && 0 ||
        (previous_register.offset_address + previous_register.byte_size)
    end

    def previous_register
      index = register.component_index - 1
      register_block.registers[index]
    end

    def bus_width
      configuration.bus_width
    end

    def byte_width
      configuration.byte_width
    end

    def start_address
      offset_address
    end

    def end_address
      start_address + register.byte_size - 1
    end

    def overlap_address_range?(file_or_register)
      overlap_range?(file_or_register) && match_access?(file_or_register)
    end

    def overlap_range?(file_or_register)
      own = address_range
      other = file_or_register.address_range
      own.include?(other.first) || other.include?(own.first)
    end

    def match_access?(file_or_register)
      (register.writable? && file_or_register.writable?) ||
        (register.readable? && file_or_register.readable?)
    end

    def support_unique_range_only?(file_or_register)
      !(register.settings[:support_overlapped_address] &&
        register.match_type?(file_or_register))
    end

    def printable_address(address)
      print_width = (register_block.local_address_width + 3) / 4
      format('0x%0*x', print_width, address)
    end
  end
end
