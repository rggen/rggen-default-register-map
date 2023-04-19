# frozen_string_literal: true

RgGen.define_simple_feature(:register_file, :offset_address) do
  register_map do
    property :offset_address, initial: -> { defalt_offset_address }
    property :expanded_offset_addresses, forward_to: :expand_addresses
    property :address_range, initial: -> { start_address..end_address }

    build do |value|
      @offset_address =
        to_int(value) { |v| "cannot convert #{v.inspect} into offset address" }
    end

    verify(:feature) do
      error_condition { offset_address.negative? }
      message { "offset address is less than 0: #{offset_address}" }
    end

    verify(:feature) do
      error_condition { (offset_address % byte_width).nonzero? }
      message do
        "offset address is not aligned with bus width(#{bus_width}): " \
        "0x#{offset_address.to_s(16)}"
      end
    end

    verify(:component) do
      error_condition do
        register_file.parent.register_block? &&
          end_address > register_block.byte_size
      end
      message do
        'offset address range exceeds byte size of register block' \
        "(#{register_block.byte_size}): " \
        "0x#{start_address.to_s(16)}-0x#{end_address.to_s(16)}"
      end
    end

    verify(:component) do
      error_condition do
        files_and_registers.any?(&method(:overlap_address_range?))
      end
      message do
        'offset address range overlaps with other offset address range: ' \
        "0x#{start_address(true).to_s(16)}-0x#{end_address(true).to_s(16)}"
      end
    end

    printable(:offset_address) do
      expand_addresses.map(&method(:format_address))
    end

    private

    def defalt_offset_address
      register_file.component_index.zero? && 0 ||
        (previous_component.offset_address + previous_component.total_byte_size)
    end

    def previous_component
      index = register_file.component_index - 1
      block_or_file.files_and_registers[index]
    end

    def start_address(full = false)
      full && expand_addresses.first || offset_address
    end

    def end_address(full = false)
      start_address(full) + register_file.total_byte_size - 1
    end

    def expand_addresses
      (register_file(:upper)&.expanded_offset_addresses || [0])
        .product(expand_local_addresses).map(&:sum)
    end

    def expand_local_addresses
      Array.new(register_file.array_size&.inject(:*) || 1) do |i|
        offset_address + register_file.entry_byte_size * i
      end
    end

    def overlap_address_range?(other)
      self_range = address_range
      other_range = other.address_range
      self_range.include?(other_range.first) || other_range.include?(self_range.first)
    end

    def bus_width
      configuration.bus_width
    end

    def byte_width
      configuration.byte_width
    end

    def format_address(address)
      print_width = (register_block.local_address_width.to_f / 4.0).ceil
      format('0x%0*x', print_width, address)
    end
  end
end
