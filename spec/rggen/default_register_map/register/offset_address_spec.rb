# frozen_string_literal: true

RSpec.describe 'register/offset_address' do
  include_context 'clean-up builder'
  include_context 'register map common'

  before(:all) do
    RgGen.define_list_item_feature(:register, :type, :foo) do
      register_map do
        no_bit_fields
        support_array_register
        writable? { true }
        readable? { true }
      end
    end

    RgGen.define_list_item_feature(:register, :type, :bar) do
      register_map do
        no_bit_fields
        support_array_register
        writable? { true  }
        readable? { false }
      end
    end

    RgGen.define_list_item_feature(:register, :type, :baz) do
      register_map do
        no_bit_fields
        support_array_register
        writable? { false }
        readable? { true  }
      end
    end

    RgGen.define_list_item_feature(:register, :type, :qux) do
      register_map do
        support_array_register
        support_shared_address
        writable? { true }
        readable? { true }
      end
    end

    RgGen.define_list_item_feature(:register, :type, :quux) do
      register_map do
        no_bit_fields
        support_array_register
        writable? { false }
        readable? { false }
      end
    end

    RgGen.enable(:global, [:address_width, :enable_wide_register])
    RgGen.enable(:register_block, [:byte_size, :bus_width])
    RgGen.enable(:register_file, [:offset_address, :size])
    RgGen.enable(:register, [:offset_address, :size, :type])
    RgGen.enable(:register, :type, [:foo, :bar, :baz, :qux, :quux])
    RgGen.enable(:bit_field, :bit_assignment)
  end

  after(:all) do
    RgGen.delete(:register, :type, [:foo, :bar, :baz, :qux, :quux])
  end

  let(:address_width) { 16 }

  let(:enable_wide_register) { true }

  let(:block_byte_size) { 256 }

  def create_registers(bus_width, &block)
    configuration =
      create_configuration(
        bus_width: bus_width, address_width: address_width,
        enable_wide_register: enable_wide_register
      )
    register_map = create_register_map(configuration) do
      register_block do
        byte_size block_byte_size
        instance_exec(&block)
      end
    end
    register_map.registers
  end

  describe '#offset_address' do
    it '入力されたオフセットアドレスを返す' do
      offset_address_list = [
        0, 2, 4, 8, 2 * rand(5..10)
      ]
      registers = create_registers(16) do
        register { offset_address offset_address_list[0]; type :foo }
        register { offset_address offset_address_list[1]; type :foo }
        register { offset_address offset_address_list[2]; type :foo }
        register { offset_address offset_address_list[3]; type :foo }
        register { offset_address offset_address_list[4]; type :foo }
      end

      expect(registers[0]).to have_property(:offset_address, offset_address_list[0])
      expect(registers[1]).to have_property(:offset_address, offset_address_list[1])
      expect(registers[2]).to have_property(:offset_address, offset_address_list[2])
      expect(registers[3]).to have_property(:offset_address, offset_address_list[3])
      expect(registers[4]).to have_property(:offset_address, offset_address_list[4])

      offset_address_list = [
        0, 4, 8, 4 * rand(3..10)
      ]
      registers = create_registers(32) do
        register { offset_address offset_address_list[0]; type :foo }
        register { offset_address offset_address_list[1]; type :foo }
        register { offset_address offset_address_list[2]; type :foo }
        register { offset_address offset_address_list[3]; type :foo }
      end

      expect(registers[0]).to have_property(:offset_address, offset_address_list[0])
      expect(registers[1]).to have_property(:offset_address, offset_address_list[1])
      expect(registers[2]).to have_property(:offset_address, offset_address_list[2])
      expect(registers[3]).to have_property(:offset_address, offset_address_list[3])

      offset_address_list = [
        0, 8, 16, 8 * rand(3..10)
      ]
      registers = create_registers(64) do
        register { offset_address offset_address_list[0]; type :foo }
        register { offset_address offset_address_list[1]; type :foo }
        register { offset_address offset_address_list[2]; type :foo }
      end

      expect(registers[0]).to have_property(:offset_address, offset_address_list[0])
      expect(registers[1]).to have_property(:offset_address, offset_address_list[1])
      expect(registers[2]).to have_property(:offset_address, offset_address_list[2])
    end

    context 'オフセットアドレスが省略されて、先頭のレジスタの場合' do
      it '0 を返す' do
        registers = create_registers(32) do
          register { type :foo }
        end
        expect(registers[0]).to have_property(:offset_address, 0)

        registers = create_registers(32) do
          register_file do
            offset_address 0x10
            register { type :foo }
          end
        end
        expect(registers[0]).to have_property(:offset_address, 0)
      end
    end

    context 'オフセットアドレスが省略されて、2番目以降のレジスタの場合' do
      specify '直前のレジスタの offset_address + byte_size が自身の offset_address になる' do
        registers = create_registers(32) do
          register { offset_address 0x04; size [3]; type :foo }
          register { type :foo }
          register { type :foo }
        end
        expect(registers[1]).to have_property(:offset_address, 0x10)
        expect(registers[2]).to have_property(:offset_address, 0x14)

        registers = create_registers(32) do
          register_file do
            offset_address 0x04
            size [3]
            register { offset_address 0x00; type :foo }
          end
          register { type :foo }
          register { type :foo }
        end
        expect(registers[1]).to have_property(:offset_address, 0x10)
        expect(registers[2]).to have_property(:offset_address, 0x14)

        registers = create_registers(32) do
          register_file do
            offset_address 0x10
            register { offset_address 0x04; size [3]; type :foo }
            register { type :foo }
            register { type :foo }
          end
        end
        expect(registers[1]).to have_property(:offset_address, 0x10)
        expect(registers[2]).to have_property(:offset_address, 0x14)

        registers = create_registers(32) do
          register_file do
            offset_address 0x10
            register_file do
              offset_address 0x04
              size [3]
              register { offset_address 0x00; type :foo }
            end
            register { type :foo }
            register { type :foo }
          end
        end
        expect(registers[1]).to have_property(:offset_address, 0x10)
        expect(registers[2]).to have_property(:offset_address, 0x14)
      end
    end
  end

  describe '#expanded_offset_addresses' do
    it '展開済みのアドレス一覧を返す' do
      registers = create_registers(32) do
        register { offset_address 0x00; type :foo }
        register { offset_address 0x10; type :foo; size [2] }
        register { offset_address 0x20; type :foo; size [2, 2] }
        register { offset_address 0x30; type :foo; size [2, step: 8] }
        register { offset_address 0x40; type :foo; size [2, 2, step: 8] }
        register_file do
          offset_address 0x60
          register { offset_address 0x00; type :foo }
        end
        register_file do
          offset_address 0x70
          size [2]
          register_file do
            offset_address 0x10
            register { offset_address 0x10; type :foo; size [2] }
            register { offset_address 0x18; type :qux; size [2]; bit_field { bit_assignment lsb: 0, width: 32 } }
            register { offset_address 0x20; type :foo; size [2, step: 8] }
          end
        end
      end

      expect(registers[0]).to have_property(:expanded_offset_addresses, match([0x00]))
      expect(registers[1]).to have_property(:expanded_offset_addresses, match([0x10, 0x14]))
      expect(registers[2]).to have_property(:expanded_offset_addresses, match([0x20, 0x24, 0x28, 0x2c]))
      expect(registers[3]).to have_property(:expanded_offset_addresses, match([0x30, 0x38]))
      expect(registers[4]).to have_property(:expanded_offset_addresses, match([0x40, 0x48, 0x50, 0x58]))
      expect(registers[5]).to have_property(:expanded_offset_addresses, match([0x60]))
      expect(registers[6]).to have_property(:expanded_offset_addresses, match([0x90, 0x94, 0xd0, 0xd4]))
      expect(registers[7]).to have_property(:expanded_offset_addresses, match([0x98, 0x98, 0xd8, 0xd8]))
      expect(registers[8]).to have_property(:expanded_offset_addresses, match([0xA0, 0xA8, 0xe0, 0xe8]))
    end
  end

  it '展開済みアドレスの一覧を表示可能オブジェクトとして返す' do
    registers = create_registers(32) do
      register { offset_address 0x00; type :foo }
      register { offset_address 0x10; type :foo; size [2] }
      register { offset_address 0x20; type :foo; size [2, 2] }
      register { offset_address 0x30; type :foo; size [2, step: 8] }
      register { offset_address 0x40; type :foo; size [2, 2, step: 8] }
      register_file do
        offset_address 0x60
        register { offset_address 0x00; type :foo }
      end
      register_file do
        offset_address 0x70
        size [2]
        register_file do
          offset_address 0x10
          register { offset_address 0x10; type :foo; size [2] }
          register { offset_address 0x18; type :qux; size [2]; bit_field { bit_assignment lsb: 0, width: 32 } }
          register { offset_address 0x20; type :foo; size [2, step: 8] }
        end
      end
    end

    expect(registers[0].printables[:offset_address]).to match(['0x00'])
    expect(registers[1].printables[:offset_address]).to match(['0x10', '0x14'])
    expect(registers[2].printables[:offset_address]).to match(['0x20', '0x24', '0x28', '0x2c'])
    expect(registers[3].printables[:offset_address]).to match(['0x30', '0x38'])
    expect(registers[4].printables[:offset_address]).to match(['0x40', '0x48', '0x50', '0x58'])
    expect(registers[5].printables[:offset_address]).to match(['0x60'])
    expect(registers[6].printables[:offset_address]).to match(['0x90', '0x94', '0xd0', '0xd4'])
    expect(registers[7].printables[:offset_address]).to match(['0x98', '0x98', '0xd8', '0xd8'])
    expect(registers[8].printables[:offset_address]).to match(['0xa0', '0xa8', '0xe0', '0xe8'])
  end

  describe 'エラーチェック' do
    context '入力値が整数に変換できない場合' do
      it 'SourceErrorを起こす' do
        [true, false, 'foo', '0xef_gh', Object.new].each do |value|
          expect {
            create_registers([16, 32, 64].sample) do
              register { offset_address value }
            end
          }.to raise_source_error "cannot convert #{value.inspect} into offset address"
        end
      end
    end

    context '入力値が 0 未満の場合' do
      it 'SourceErrorを起こす' do
        [-1, -2, rand(-10..-3)].each do |value|
          expect {
            create_registers([16, 32, 64].sample) do
              register { offset_address value }
            end
          }.to raise_source_error "offset address is less than 0: #{value}"
        end
      end
    end

    context 'バス幅に揃っていない場合' do
      it 'SourceErrorを起こす' do
        [1, 3, 7, 9, 15, 17].each do |value|
          expect {
            create_registers(16) do
              register { offset_address value }
            end
          }.to raise_source_error "offset address is not aligned with bus width(16): 0x#{value.to_s(16)}"
        end

        [1, 2, 3, 5, 15, 17].each do |value|
          expect {
            create_registers(32) do
              register { offset_address value }
            end
          }.to raise_source_error "offset address is not aligned with bus width(32): 0x#{value.to_s(16)}"
        end

        [1, 2, 3, 4, 5, 6, 7, 9, 15, 17].each do |value|
          expect {
            create_registers(64) do
              register { offset_address value }
            end
          }.to raise_source_error "offset address is not aligned with bus width(64): 0x#{value.to_s(16)}"
        end
      end
    end

    describe 'アドレス領域の大きさのチェック' do
      context 'アドレス領域がレジスタブロックのバイトサイズを超えない場合' do
        specify 'エラーは起こらない' do
          expect {
            create_registers(32) do
              register { offset_address 0x00; type :foo }
            end
          }.not_to raise_error

          expect {
            create_registers(32) do
              register { offset_address 0xFC; type :foo }
            end
          }.not_to raise_error

          expect {
            create_registers(32) do
              register { offset_address 0xF0; type :foo; size 4 }
            end
          }.not_to raise_error

          expect {
            create_registers(32) do
              register { offset_address 0xF0; type :foo; size [2, step: 8] }
            end
          }.not_to raise_error

          expect {
            create_registers(32) do
              register { offset_address 0x00; type :foo; size 64 }
            end
          }.not_to raise_error
        end
      end

      context 'アドレス領域がレジスタブロックのバイトサイズを超える場合' do
        it 'SourceErrorを起こす' do
          expect {
            create_registers(32) do
              register { offset_address 0x100; type :foo }
            end
          }.to raise_source_error 'offset address range exceeds byte size of register block(256): 0x100-0x103'

          expect {
            create_registers(32) do
              register { offset_address 0xF4; type :foo; size 4 }
            end
          }.to raise_source_error 'offset address range exceeds byte size of register block(256): 0xf4-0x103'

          expect {
            create_registers(32) do
              register { offset_address 0xF4; type :foo; size [2, step: 8] }
            end
          }.to raise_source_error 'offset address range exceeds byte size of register block(256): 0xf4-0x103'
        end
      end
    end

    describe '重複アドレスのチェック' do
      context 'アドレスが重複しない場合' do
        specify 'エラーは起こらない' do
          expect {
            create_registers(32) do
              register { offset_address 0x0; type :foo }
              register { offset_address 0x4; type :foo }
            end
          }.not_to raise_error

          expect {
            create_registers(32) do
              register_file do
                offset_address 0x0
                register { offset_address 0x0; type :foo }
                register { offset_address 0x4; type :foo }
              end
            end
          }.not_to raise_error

          expect {
            create_registers(32) do
              register_file do
                offset_address 0x0
                register { offset_address 0x0; type :foo }
              end
              register { offset_address 0x4; type :foo }
            end
          }.not_to raise_error

          expect {
            create_registers(32) do
              register_file do
                register_file do
                  offset_address 0x0
                  register { offset_address 0x0; type :foo }
                end
                register { offset_address 0x4; type :foo }
              end
            end
          }.not_to raise_error

          expect {
            create_registers(32) do
              register { offset_address 0x0; type :foo }
              register { offset_address 0x4; type :bar }
            end
          }.not_to raise_error

          expect {
            create_registers(32) do
              register_file do
                offset_address 0x0
                register { offset_address 0x0; type :foo }
                register { offset_address 0x4; type :bar }
              end
            end
          }.not_to raise_error

          expect {
            create_registers(32) do
              register_file do
                offset_address 0x0
                register { offset_address 0x0; type :foo }
              end
              register { offset_address 0x4; type :bar }
            end
          }.not_to raise_error

          expect {
            create_registers(32) do
              register_file do
                register_file do
                  offset_address 0x0
                  register { offset_address 0x0; type :foo }
                end
                register { offset_address 0x4; type :bar }
              end
            end
          }.not_to raise_error

          expect {
            create_registers(32) do
              register { offset_address 0x0; type :foo }
              register { offset_address 0x4; type :baz }
            end
          }.not_to raise_error

          expect {
            create_registers(32) do
              register_file do
                register { offset_address 0x0; type :foo }
                register { offset_address 0x4; type :baz }
              end
            end
          }.not_to raise_error

          expect {
            create_registers(32) do
              register_file do
                offset_address 0x0
                register { offset_address 0x0; type :foo }
              end
              register { offset_address 0x4; type :baz }
            end
          }.not_to raise_error

          expect {
            create_registers(32) do
              register_file do
                register_file do
                  offset_address 0x0
                  register { offset_address 0x0; type :foo }
                end
                register { offset_address 0x4; type :baz }
              end
            end
          }.not_to raise_error
        end
      end

      context 'アドレスが重複し、アクセス属性が重複しない場合' do
        specify 'エラーは起こらない' do
          expect {
            create_registers(32) do
              register { offset_address 0x0; type :bar }
              register { offset_address 0x0; type :baz }
            end
          }.not_to raise_error

          expect {
            create_registers(32) do
              register_file do
                register { offset_address 0x0; type :bar }
                register { offset_address 0x0; type :baz }
              end
            end
          }.not_to raise_error

          expect {
            create_registers(32) do
              register { offset_address 0x0; type :bar; size 2 }
              register { offset_address 0x0; type :baz; size 2 }
            end
          }.not_to raise_error

          expect {
            create_registers(32) do
              register { offset_address 0x0; type :bar; size [2, 3] }
              register { offset_address 0x0; type :baz; size 6 }
            end
          }.not_to raise_error

          expect {
            create_registers(32) do
              register_file do
                register { offset_address 0x0; type :bar; size 2 }
                register { offset_address 0x0; type :baz; size 2 }
              end
            end
          }.not_to raise_error

          expect {
            create_registers(32) do
              register_file do
                register { offset_address 0x0; type :bar; size [2, 3] }
                register { offset_address 0x0; type :baz; size 6 }
              end
            end
          }.not_to raise_error
        end
      end

      context 'アドレス、アクセス属性共に重複する場合' do
        it 'SourceErrorを起こす' do
          expect {
            create_registers(32) do
              register { offset_address 0x0; type :foo }
              register { offset_address 0x0; type :foo }
            end
          }.to raise_source_error 'offset address range overlaps with other offset address range: 0x0-0x3'

          expect {
            create_registers(32) do
              register_file do
                offset_address 0x10
                register { offset_address 0x0; type :foo }
                register { offset_address 0x0; type :foo }
              end
            end
          }.to raise_source_error 'offset address range overlaps with other offset address range: 0x10-0x13'

          expect {
            create_registers(32) do
              register { offset_address 0x0; type :foo }
              register { offset_address 0x0; type :bar }
            end
          }.to raise_source_error 'offset address range overlaps with other offset address range: 0x0-0x3'

          expect {
            create_registers(32) do
              register_file do
                offset_address 0x10
                register { offset_address 0x0; type :foo }
                register { offset_address 0x0; type :bar }
              end
            end
          }.to raise_source_error 'offset address range overlaps with other offset address range: 0x10-0x13'

          expect {
            create_registers(32) do
              register { offset_address 0x0; type :foo }
              register { offset_address 0x0; type :baz }
            end
          }.to raise_source_error 'offset address range overlaps with other offset address range: 0x0-0x3'

          expect {
            create_registers(32) do
              register { offset_address 0x00; type :quux }
              register { offset_address 0x00; type :foo }
            end
          }.to raise_source_error 'offset address range overlaps with other offset address range: 0x0-0x3'

          expect {
            create_registers(32) do
              register { offset_address 0x00; type :quux }
              register { offset_address 0x00; type :bar }
            end
          }.to raise_source_error 'offset address range overlaps with other offset address range: 0x0-0x3'

          expect {
            create_registers(32) do
              register { offset_address 0x00; type :quux }
              register { offset_address 0x00; type :baz }
            end
          }.to raise_source_error 'offset address range overlaps with other offset address range: 0x0-0x3'

          expect {
            create_registers(32) do
              register { offset_address 0x00; type :quux }
              register { offset_address 0x00; type :quux }
            end
          }.to raise_source_error 'offset address range overlaps with other offset address range: 0x0-0x3'

          expect {
            create_registers(32) do
              register_file do
                offset_address 0x10
                register { offset_address 0x0; type :foo }
                register { offset_address 0x0; type :baz }
              end
            end
          }.to raise_source_error 'offset address range overlaps with other offset address range: 0x10-0x13'

          expect {
            create_registers(32) do
              register { offset_address 0x4; type :foo }
              register { offset_address 0x0; type [:foo, :bar, :baz, :quux].sample; size 3 }
            end
          }.to raise_source_error 'offset address range overlaps with other offset address range: 0x0-0xb'

          expect {
            create_registers(32) do
              register_file do
                offset_address 0x10
                register { offset_address 0x4; type :foo }
                register { offset_address 0x0; type [:foo, :bar, :baz, :quux].sample; size 3 }
              end
            end
          }.to raise_source_error 'offset address range overlaps with other offset address range: 0x10-0x1b'

          expect {
            create_registers(32) do
              register { offset_address 0x0; type :foo; size 3 }
              register { offset_address 0x4; type [:foo, :bar, :baz, :quux].sample }
            end
          }.to raise_source_error 'offset address range overlaps with other offset address range: 0x4-0x7'

          expect {
            create_registers(32) do
              register_file do
                offset_address 0x10
                register { offset_address 0x0; type :foo; size 3 }
                register { offset_address 0x4; type [:foo, :bar, :baz, :quux].sample }
              end
            end
          }.to raise_source_error 'offset address range overlaps with other offset address range: 0x14-0x17'
        end
      end

      context 'アクセス属性は重複しないが、オフセットアドレス/サイズが異なる場合' do
        it 'SourceErrorを起こす' do
          expect {
            create_registers(32) do
              register { offset_address 0x0; type :bar; size 2 }
              register { offset_address 0x4; type :baz; size 2 }
            end
          }.to raise_source_error 'offset address range overlaps with other offset address range: 0x4-0xb'

          expect {
            create_registers(32) do
              register { offset_address 0x4; type :bar; size 2 }
              register { offset_address 0x0; type :baz; size 2 }
            end
          }.to raise_source_error 'offset address range overlaps with other offset address range: 0x0-0x7'

          expect {
            create_registers(32) do
              register { offset_address 0x0; type :bar; size 4 }
              register { offset_address 0x4; type :baz; size 2 }
            end
          }.to raise_source_error 'offset address range overlaps with other offset address range: 0x4-0xb'

          expect {
            create_registers(32) do
              register { offset_address 0x4; type :bar; size 2 }
              register { offset_address 0x0; type :baz; size 4 }
            end
          }.to raise_source_error 'offset address range overlaps with other offset address range: 0x0-0xf'

          expect {
            create_registers(32) do
              register { offset_address 0x0; type :bar }
              register { offset_address 0x0; type :baz; size 2 }
            end
          }.to raise_source_error 'offset address range overlaps with other offset address range: 0x0-0x7'

          expect {
            create_registers(32) do
              register { offset_address 0x0; type :bar; size 2 }
              register { offset_address 0x0; type :baz }
            end
          }.to raise_source_error 'offset address range overlaps with other offset address range: 0x0-0x3'

          expect {
            create_registers(32) do
              register { offset_address 0x0; type :bar; size 4 }
              register { offset_address 0x0; type :baz; size 2 }
            end
          }.to raise_source_error 'offset address range overlaps with other offset address range: 0x0-0x7'

          expect {
            create_registers(32) do
              register { offset_address 0x0; type :bar; size 2 }
              register { offset_address 0x0; type :baz; size 4 }
            end
          }.to raise_source_error 'offset address range overlaps with other offset address range: 0x0-0xf'
        end
      end

      context 'レジスタの属性に.support_shared_addressがされていて' do
        context 'レジスタ型/サイズが同じ場合' do
          specify 'アドレスが重複していても、エラーは起こらない' do
            expect {
              create_registers(32) do
                register { offset_address 0x0; type :qux; bit_field { bit_assignment lsb: 0, width: 32 } }
                register { offset_address 0x0; type :qux; bit_field { bit_assignment lsb: 0, width: 32 } }
              end
            }.not_to raise_error

            expect {
              create_registers(32) do
                register_file do
                  register { offset_address 0x0; type :qux; bit_field { bit_assignment lsb: 0, width: 32 } }
                  register { offset_address 0x0; type :qux; bit_field { bit_assignment lsb: 0, width: 32 } }
                end
              end
            }.not_to raise_error
          end
        end

        context 'レジスタ型が同じで、オフセットアドレス/サイズが異なる場合' do
          it 'SourceErrorを起こす' do
            expect {
              create_registers(32) do
                register { offset_address 0x0; type :qux; bit_field { bit_assignment lsb: 0, width: 32 } }
                register { offset_address 0x0; type :qux; bit_field { bit_assignment lsb: 0, width: 64 } }
              end
            }.to raise_source_error 'offset address range overlaps with other offset address range: 0x0-0x7'

            expect {
              create_registers(32) do
                register { offset_address 0x0; type :qux; bit_field { bit_assignment lsb: 0, width: 64 } }
                register { offset_address 0x0; type :qux; bit_field { bit_assignment lsb: 0, width: 32 } }
              end
            }.to raise_source_error 'offset address range overlaps with other offset address range: 0x0-0x3'

            expect {
              create_registers(32) do
                register { offset_address 0x0; type :qux; bit_field { bit_assignment lsb: 0, width: 64 } }
                register { offset_address 0x4; type :qux; bit_field { bit_assignment lsb: 0, width: 64 } }
              end
            }.to raise_source_error 'offset address range overlaps with other offset address range: 0x4-0xb'

            expect {
              create_registers(32) do
                register { offset_address 0x4; type :qux; bit_field { bit_assignment lsb: 0, width: 64 } }
                register { offset_address 0x0; type :qux; bit_field { bit_assignment lsb: 0, width: 64 } }
              end
            }.to raise_source_error 'offset address range overlaps with other offset address range: 0x0-0x7'

            expect {
              create_registers(32) do
                register { offset_address 0x0; type :qux; bit_field { bit_assignment lsb: 0, width: 96 } }
                register { offset_address 0x4; type :qux; bit_field { bit_assignment lsb: 0, width: 32 } }
              end
            }.to raise_source_error 'offset address range overlaps with other offset address range: 0x4-0x7'

            expect {
              create_registers(32) do
                register { offset_address 0x4; type :qux; bit_field { bit_assignment lsb: 0, width: 32 } }
                register { offset_address 0x0; type :qux; bit_field { bit_assignment lsb: 0, width: 96 } }
              end
            }.to raise_source_error 'offset address range overlaps with other offset address range: 0x0-0xb'
          end
        end

        context 'レジスタ型が異なり、アドレスが重複する場合' do
          it 'SourceErrorを起こす' do
            expect {
              create_registers(32) do
                register { offset_address 0x0; type [:foo, :bar, :baz, :quux].sample }
                register { offset_address 0x0; type :qux; bit_field { bit_assignment lsb: 0, width: 32 } }
              end
            }.to raise_source_error 'offset address range overlaps with other offset address range: 0x0-0x3'

            expect {
              create_registers(32) do
                register_file do
                  offset_address 0x10
                  register { offset_address 0x0; type [:foo, :bar, :baz, :quux].sample }
                  register { offset_address 0x0; type :qux; bit_field { bit_assignment lsb: 0, width: 32 } }
                end
              end
            }.to raise_source_error 'offset address range overlaps with other offset address range: 0x10-0x13'

            expect {
              create_registers(32) do
                register { offset_address 0x0; type [:foo, :bar, :baz, :quux].sample; size 3 }
                register { offset_address 0x4; type :qux; bit_field { bit_assignment lsb: 0, width: 32 } }
              end
            }.to raise_source_error 'offset address range overlaps with other offset address range: 0x4-0x7'

            expect {
              create_registers(32) do
                register_file do
                  offset_address 0x10
                  register { offset_address 0x0; type [:foo, :bar, :baz, :quux].sample; size 3 }
                  register { offset_address 0x4; type :qux; bit_field { bit_assignment lsb: 0, width: 32 } }
                end
              end
            }.to raise_source_error 'offset address range overlaps with other offset address range: 0x14-0x17'

            expect {
              create_registers(32) do
                register { offset_address 0x4; type [:foo, :bar, :baz, :quux].sample }
                register { offset_address 0x0; type :qux; bit_field { bit_assignment lsb: 0, width: 96 } }
              end
            }.to raise_source_error 'offset address range overlaps with other offset address range: 0x0-0xb'

            expect {
              create_registers(32) do
                register_file do
                  offset_address 0x10
                  register { offset_address 0x4; type [:foo, :bar, :baz, :quux].sample }
                  register { offset_address 0x0; type :qux; bit_field { bit_assignment lsb: 0, width: 96 } }
                end
              end
            }.to raise_source_error 'offset address range overlaps with other offset address range: 0x10-0x1b'
          end
        end
      end

      context 'レジスタファイルとアドレスが重複する場合' do
        it 'SourceErrorを起こす' do
          expect {
            create_registers(32) do
              register_file do
                offset_address 0x0
                register { offset_address 0x0; type [:foo, :bar, :baz].sample }
              end
              register do
                offset_address 0x0; type [:foo, :bar, :baz, :qux, :quux].sample
                bit_field { bit_assignment lsb: 0, width: 32 }
              end
            end
          }.to raise_source_error 'offset address range overlaps with other offset address range: 0x0-0x3'

          expect {
            create_registers(32) do
              register_file do
                offset_address 0x10
                register_file do
                  offset_address 0x0
                  register { offset_address 0x0; type [:foo, :bar, :baz].sample }
                end
                register do
                  offset_address 0x0; type [:foo, :bar, :baz, :qux, :quux].sample
                  bit_field { bit_assignment lsb: 0, width: 32 }
                end
              end
            end
          }.to raise_source_error 'offset address range overlaps with other offset address range: 0x10-0x13'

          expect {
            create_registers(32) do
              register_file do
                offset_address 0x0
                size 3
                register { offset_address 0x0; type [:foo, :bar, :baz].sample }
              end
              register do
                offset_address 0x4; type [:foo, :bar, :baz, :qux, :quux].sample
                bit_field { bit_assignment lsb: 0, width: 32 }
              end
            end
          }.to raise_source_error 'offset address range overlaps with other offset address range: 0x4-0x7'

          expect {
            create_registers(32) do
              register_file do
                offset_address 0x10
                register_file do
                  offset_address 0x0
                  size 3
                  register { offset_address 0x0; type [:foo, :bar, :baz].sample }
                end
                register do
                  offset_address 0x4; type [:foo, :bar, :baz, :qux, :quux].sample
                  bit_field { bit_assignment lsb: 0, width: 32 }
                end
              end
            end
          }.to raise_source_error 'offset address range overlaps with other offset address range: 0x14-0x17'

          expect {
            create_registers(32) do
              register_file do
                offset_address 0x4
                register { offset_address 0x0; type [:foo, :bar, :baz].sample }
              end
              register do
                offset_address 0x0; type [:foo, :bar, :baz, :qux, :quux].sample; size [3]
                bit_field { bit_assignment lsb: 0, width: 96 }
              end
            end
          }.to raise_source_error 'offset address range overlaps with other offset address range: 0x0-0xb'

          expect {
            create_registers(32) do
              register_file do
                offset_address 0x10
                register_file do
                  offset_address 0x4
                  register { offset_address 0x0; type [:foo, :bar, :baz].sample }
                end
                register do
                  offset_address 0x0; type [:foo, :bar, :baz, :qux, :quux].sample; size [3]
                  bit_field { bit_assignment lsb: 0, width: 96 }
                end
              end
            end
          }.to raise_source_error 'offset address range overlaps with other offset address range: 0x10-0x1b'
        end
      end
    end
  end
end
