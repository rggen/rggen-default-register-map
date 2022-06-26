# frozen_string_literal: true

RSpec.describe 'register/type/reserved' do
  include_context 'clean-up builder'
  include_context 'register map common'

  before(:all) do
    RgGen.enable(:global, [:bus_width, :address_width, :enable_wide_register])
    RgGen.enable(:register_block, :byte_size)
    RgGen.enable(:register, [:name, :type, :offset_address, :size])
    RgGen.enable(:register, :type, :reserved)
    RgGen.enable(:bit_field, :name)
  end

  def create_registers(&block)
    configuration = create_configuration(bus_width: 32, address_width: 16)
    register_map = create_register_map(configuration) do
      register_block do
        byte_size 256
        instance_exec(&block)
      end
    end
    register_map.registers
  end

  specify 'レジスタ型は:reserved' do
    registers = create_registers do
      register { name 'register_0'; offset_address 0x00; type :reserved }
    end
    expect(registers[0].type).to eq :reserved
  end

  specify 'アクセス属性は予約済み' do
    registers = create_registers do
      register { name 'register_0'; offset_address 0x00; type :reserved }
    end
    expect(registers[0]).to be_reserved
  end

  it 'ビットフィールドを持たない' do
    registers = create_registers do
      register do
        name 'register_0'
        offset_address 0x00
        type :reserved
        bit_field { name :foo }
        bit_field { name :bar }
      end
    end
    expect(registers[0].bit_fields).to be_empty
  end

  it '配列レジスタに対応する' do
    registers = create_registers do
      register { name 'register_0'; offset_address 0x00; type :reserved }
      register { name 'register_1'; offset_address 0x10; type :reserved; size [4] }
      register { name 'register_2'; offset_address 0x20; type :reserved; size [2, 2] }
    end
    expect(registers[0]).not_to be_array
    expect(registers[1]).to be_array
    expect(registers[2]).to be_array
  end
end
