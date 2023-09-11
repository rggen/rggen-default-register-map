# frozen_string_literal: true

RSpec.describe 'register/type/rw' do
  include_context 'clean-up builder'
  include_context 'register map common'

  before(:all) do
    RgGen.enable(:global, [:bus_width, :address_width, :enable_wide_register, :array_port_format])
    RgGen.enable(:register_block, [:byte_size])
    RgGen.enable(:register_file, [:name, :offset_address, :size])
    RgGen.enable(:register, [:name, :offset_address, :size, :type])
    RgGen.enable(:register, :type, [:rw])
    RgGen.enable(:bit_field, [:name, :bit_assignment, :initial_value, :reference, :type])
    RgGen.enable(:bit_field, :type, [:ro, :rw, :wo, :reserved])
  end

  def create_registers(&block)
    register_map = create_register_map do
      register_block do
        byte_size 256
        instance_eval(&block)
      end
    end
    register_map.registers
  end

  specify 'レジスタ型は:rw' do
    registers = create_registers do
      register do
        name 'foo'; type :rw
        bit_field { name 'foo'; bit_assignment lsb: 0; type :rw; initial_value 0 }
      end
    end

    expect(registers[0]).to have_property(:type, :rw)
  end

  specify '配下のビットフィールドに依らず、アクセス属性は読み書き可能' do
    registers = create_registers do
      register do
        name 'foo'; type :rw
        bit_field { name 'foo'; bit_assignment lsb: 0; type :rw; initial_value 0 }
      end

      register do
        name 'bar'; type :rw
        bit_field { name 'bar'; bit_assignment lsb: 0; type :ro }
      end

      register do
        name 'buz'; type :rw
        bit_field { name 'buz'; bit_assignment lsb: 0; type :wo; initial_value 0 }
      end
    end

    expect(registers[0]).to be_readable.and be_writable
    expect(registers[1]).to be_readable.and be_writable
    expect(registers[2]).to be_readable.and be_writable
  end

  specify '配列レジスタに対応する' do
    registers = create_registers do
      register do
        name 'foo'; type :rw;
        bit_field { name 'foo'; bit_assignment lsb: 0; type :rw; initial_value 0 }
      end

      register do
        name 'bar'; type :rw; size [4]
        bit_field { name 'bar'; bit_assignment lsb: 0; type :rw; initial_value 0 }
      end

      register do
        name 'buz'; type :rw; size [2, 2]
        bit_field { name 'buz'; bit_assignment lsb: 0; type :rw; initial_value 0 }
      end
    end

    expect(registers[0]).not_to be_array
    expect(registers[1]).to be_array
    expect(registers[2]).to be_array
  end
end
