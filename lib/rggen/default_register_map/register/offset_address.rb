# frozen_string_literal: true

RgGen.define_simple_feature(:register, :offset_address) do
  register_map do
    property :offset_address, initial: -> { default_offset_address }
    property :expanded_offset_addresses, forward_to: :expand_addresses
    property :address_range, initial: -> { start_address..end_address }
    property :overlap?, body: ->(other) { overlap_address_range?(other, false) }

    build do |value|
      @offset_address = Integer(value)
    rescue ArgumentError, TypeError
      error "cannot convert #{value.inspect} into offset address"
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
        register.parent.register_block? &&
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
        files_and_registers.any? do |other|
          overlap_address_range?(other, true)
        end
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

    def default_offset_address
      register.component_index.zero? && 0 ||
        (previous_component.offset_address + previous_component.byte_size)
    end

    def start_address(full = false)
      full && expand_addresses.first || offset_address
    end

    def end_address(full = false)
      start_address(full) + register.byte_size - 1
    end

    def expand_addresses
      upper_offsets = register_file&.expanded_offset_addresses || [0]
      upper_offsets.product(expand_local_addresses).map(&:sum)
    end

    def expand_local_addresses
      width = shared_address? && 0 || register.byte_width
      Array.new(register.count) { |i| offset_address + width * i }
    end

    def previous_component
      index = register.component_index - 1
      files_and_registers[index]
    end

    def bus_width
      configuration.bus_width
    end

    def byte_width
      configuration.byte_width
    end

    def overlap_address_range?(other, shareable)
      overlap_range?(other) &&
        (exclusive_range?(other) || !shareable_access?(other, shareable))
    end

    def overlap_range?(other)
      self_range = address_range
      othre_range = other.address_range
      self_range.include?(othre_range.first) || othre_range.include?(self_range.first)
    end

    def exclusive_range?(other)
      other.register_file? || other.reserved? || register.reserved?
    end

    def shareable_access?(other, shareable)
      match_range?(other) &&
        (alternate_access?(other) || shareable_range?(other, shareable))
    end

    def match_range?(other)
      address_range == other.address_range
    end

    def alternate_access?(other)
      [:writable?, :readable?].all? { |access| [register, other].one?(&access) }
    end

    def shareable_range?(other, shareable)
      shareable && shared_address? && register.match_type?(other)
    end

    def shared_address?
      register.settings[:support_shared_address]
    end

    def format_address(address)
      print_width = (register_block.local_address_width + 3) / 4
      format('0x%0*x', print_width, address)
    end
  end
end
