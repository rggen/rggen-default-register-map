# frozen_string_literal: true

RSpec.describe 'register/type/external' do
  include_context 'clean-up builder'
  include_context 'register map common'

  before(:all) do
    RgGen.enable(:global, [:bus_width, :address_width, :enable_wide_register])
    RgGen.enable(:register_block, :byte_size)
    RgGen.enable(:register, [:name, :type, :offset_address, :size])
    RgGen.enable(:register, :type, :external)
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

  specify 'レジスタ型は:external' do
    registers = create_registers do
      register { name 'register_0'; offset_address 0x00; type :external }
    end
    expect(registers[0].type).to eq :external
  end

  specify 'アクセス属性は読み書き可能' do
    registers = create_registers do
      register { name 'register_0'; offset_address 0x00; type :external }
    end
    expect(registers[0]).to be_readable.and be_writable
  end

  it 'ビットフィールドを持たない' do
    registers = create_registers do
      register do
        name 'register_0'
        offset_address 0x00
        type :external
        bit_field { name :foo }
        bit_field { name :bar }
      end
    end
    expect(registers[0].bit_fields).to be_empty
  end

  it '配列レジスタではない' do
    registers = create_registers do
      register { name 'register_0'; offset_address 0x00; type :external }
      register { name 'register_1'; offset_address 0x10; type :external; size [1] }
      register { name 'register_2'; offset_address 0x20; type :external; size [16] }
    end
    expect(registers[0]).not_to be_array
    expect(registers[1]).not_to be_array
    expect(registers[2]).not_to be_array
  end

  describe 'printables[:byte_size]' do
    it '表示可能オブジェクトとして、総バイト数を返す' do
      registers = create_registers do
        register { name 'register_0'; offset_address 0x00; type :external }
        register { name 'register_1'; offset_address 0x10; type :external; size [1] }
        register { name 'register_2'; offset_address 0x20; type :external; size [16] }
      end

      expect(registers[0].printables[:byte_size]).to eq '4 bytes'
      expect(registers[1].printables[:byte_size]).to eq '4 bytes'
      expect(registers[2].printables[:byte_size]).to eq '64 bytes'
    end
  end

  it 'レジスタファイル内では指定できない' do
    expect {
      create_registers do
        register_file do
          register { name 'register_0'; offset_address 0x00; type :external }
        end
      end
    }.to raise_register_map_error 'external register type is not allowed to be put within register file'

    expect {
      create_registers do
        register_file do
          register_file do
            register { name 'register_0'; offset_address 0x00; type :external }
          end
        end
      end
    }.to raise_register_map_error 'external register type is not allowed to be put within register file'
  end

  it '単一サイズ定義のみ対応している' do
    expect {
      create_registers do
        register { name 'register_0'; offset_address 0x00; type :external; size [1, 1] }
      end
    }.to raise_register_map_error 'external register type supports single size definition only'
  end

  specify 'stepの指定には対応しない' do
    expect {
      create_registers do
        register { name 'register_0'; offset_address 0x00; type :external; size [1, step: 8] }
      end
    }.to raise_register_map_error
  end
end
