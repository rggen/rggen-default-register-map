# frozen_string_literal: true

RSpec.describe 'register_file/offset_address' do
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
        writable? { true }
        readable? { false }
      end
    end

    RgGen.define_list_item_feature(:register, :type, :baz) do
      register_map do
        no_bit_fields
        support_array_register
        writable? { false }
        readable? { true }
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

    RgGen.enable(:global, [:bus_width, :address_width, :enable_wide_register])
    RgGen.enable(:register_block, :byte_size)
    RgGen.enable(:register_file, [:offset_address, :size])
    RgGen.enable(:register, [:offset_address, :size, :type])
    RgGen.enable(:register, :type, [:foo, :bar, :baz, :qux])
    RgGen.enable(:bit_field, [:bit_assignment])
  end

  after(:all) do
    RgGen.delete(:register, :type, [:foo, :bar, :baz, :qux])
  end

  let(:address_width) { 16 }

  let(:enable_wide_register) { true }

  let(:block_byte_size) { 256 }

  def create_register_files(bus_width, &block)
    configuration =
      create_configuration(
        bus_width: bus_width, address_width: address_width,
        enable_wide_register: enable_wide_register
      )
    register_map =
      create_register_map(configuration) do
        register_block do
          byte_size block_byte_size
          instance_eval(&block)
        end
      end
    register_map.register_files
  end

  describe '#offset_address' do
    it '入力されたオフセットアドレスを返す' do
      offset_address_list = [
        0, 2, 4, 2 * rand(3..10)
      ]
      register_files = create_register_files(16) do
        register_file do
          offset_address offset_address_list[0]
          register { offset_address 0; type :foo }
        end
        register_file do
          offset_address offset_address_list[1]
          register { offset_address 0; type :foo }
        end
        register_file do
          offset_address offset_address_list[2]
          register { offset_address 0; type :foo }
        end
        register_file do
          offset_address offset_address_list[3]
          register { offset_address 0; type :foo }
        end
      end
      expect(register_files[0]).to have_property(:offset_address, offset_address_list[0])
      expect(register_files[1]).to have_property(:offset_address, offset_address_list[1])
      expect(register_files[2]).to have_property(:offset_address, offset_address_list[2])
      expect(register_files[3]).to have_property(:offset_address, offset_address_list[3])

      offset_address_list = [
        0, 4, 8, 4 * rand(3..10)
      ]
      register_files = create_register_files(32) do
        register_file do
          offset_address offset_address_list[0]
          register { offset_address 0; type :foo }
        end
        register_file do
          offset_address offset_address_list[1]
          register { offset_address 0; type :foo }
        end
        register_file do
          offset_address offset_address_list[2]
          register { offset_address 0; type :foo }
        end
        register_file do
          offset_address offset_address_list[3]
          register { offset_address 0; type :foo }
        end
      end
      expect(register_files[0]).to have_property(:offset_address, offset_address_list[0])
      expect(register_files[1]).to have_property(:offset_address, offset_address_list[1])
      expect(register_files[2]).to have_property(:offset_address, offset_address_list[2])
      expect(register_files[3]).to have_property(:offset_address, offset_address_list[3])

      offset_address_list = [
        0, 8, 16, 8 * rand(3..10)
      ]
      register_files = create_register_files(64) do
        register_file do
          offset_address offset_address_list[0]
          register { offset_address 0; type :foo }
        end
        register_file do
          offset_address offset_address_list[1]
          register { offset_address 0; type :foo }
        end
        register_file do
          offset_address offset_address_list[2]
          register { offset_address 0; type :foo }
        end
        register_file do
          offset_address offset_address_list[3]
          register { offset_address 0; type :foo }
        end
      end
      expect(register_files[0]).to have_property(:offset_address, offset_address_list[0])
      expect(register_files[1]).to have_property(:offset_address, offset_address_list[1])
      expect(register_files[2]).to have_property(:offset_address, offset_address_list[2])
      expect(register_files[3]).to have_property(:offset_address, offset_address_list[3])
    end

    context 'オフセットアドレスが省略されて、先頭の場合' do
      it '0を返す' do
        register_files = create_register_files(32) do
          register_file do
            register { offset_address 0; type :foo }
          end
        end
        expect(register_files[0]).to have_property(:offset_address, 0)

        register_files = create_register_files(32) do
          register_file do
            offset_address 4
            register_file do
              register { offset_address 0; type :foo }
            end
          end
        end
        expect(register_files[1]).to have_property(:offset_address, 0)
      end
    end

    context 'オフセットアドレスが省略されて、２番目以降の場合' do
      specify '連番になるように、オフセットアドレスが設定される' do
        register_files = create_register_files(32) do
          register { offset_address 4; size [3]; type :foo }
          register_file do
            register { offset_address 0; type :foo }
          end
          register_file do
            register { offset_address 0; type :foo }
          end
        end
        expect(register_files[0]).to have_property(:offset_address, 0x10)
        expect(register_files[1]).to have_property(:offset_address, 0x14)

        register_files = create_register_files(32) do
          register_file do
            offset_address 4
            register { offset_address 0; size [3]; type :foo }
          end
          register_file do
            register { offset_address 0; type :foo }
          end
          register_file do
            register { offset_address 0; type :foo }
          end
        end
        expect(register_files[1]).to have_property(:offset_address, 0x10)
        expect(register_files[2]).to have_property(:offset_address, 0x14)

        register_files = create_register_files(32) do
          register_file do
            offset_address 0
            register { offset_address 4; size [3]; type :foo }
            register_file do
              register { offset_address 0; type :foo }
            end
            register_file do
              register { offset_address 0; type :foo }
            end
          end
        end
        expect(register_files[1]).to have_property(:offset_address, 0x10)
        expect(register_files[2]).to have_property(:offset_address, 0x14)

        register_files = create_register_files(32) do
          register_file do
            offset_address 0
            register_file do
              offset_address 4
              register { offset_address 0; size [3]; type :foo }
            end
            register_file do
              register { offset_address 0; type :foo }
            end
            register_file do
              register { offset_address 0; type :foo }
            end
          end
        end
        expect(register_files[2]).to have_property(:offset_address, 0x10)
        expect(register_files[3]).to have_property(:offset_address, 0x14)
      end
    end
  end

  describe '#expanded_offset_addresses' do
    it '展開済みのオフセットアドレスの一覧を返す' do
      register_files = create_register_files(32) do
        register_file do
          offset_address 0x00
          register { offset_address 0x00; type :foo }
        end
        register_file do
          offset_address 0x10
          size [2]
          register { offset_address 0x4; type :foo }
        end
        register_file do
          offset_address 0x20
          size [2]
          register_file do
            offset_address 0x00
            register_file do
              offset_address 0x10
              size [2]
              register { offset_address 0x04; type :foo }
            end
          end
        end
      end

      expect(register_files[0]).to have_property(:expanded_offset_addresses, match([0x00]))
      expect(register_files[1]).to have_property(:expanded_offset_addresses, match([0x10, 0x18]))
      expect(register_files[2]).to have_property(:expanded_offset_addresses, match([0x20, 0x40]))
      expect(register_files[3]).to have_property(:expanded_offset_addresses, match([0x20, 0x40]))
      expect(register_files[4]).to have_property(:expanded_offset_addresses, match([0x30, 0x38, 0x50, 0x58]))
    end
  end

  it '展開済みアドレスの一覧を表示可能オブジェクトとして返す' do
    register_files = create_register_files(32) do
      register_file do
        offset_address 0x00
        register { offset_address 0x00; type :foo }
      end
      register_file do
        offset_address 0x10
        size [2]
        register { offset_address 0x4; type :foo }
      end
      register_file do
        offset_address 0x20
        size [2]
        register_file do
          offset_address 0x00
          register_file do
            offset_address 0x10
            size [2]
            register { offset_address 0x04; type :foo }
          end
        end
      end
    end

    expect(register_files[0].printables[:offset_address]).to match(['0x00'])
    expect(register_files[1].printables[:offset_address]).to match(['0x10', '0x18'])
    expect(register_files[2].printables[:offset_address]).to match(['0x20', '0x40'])
    expect(register_files[3].printables[:offset_address]).to match(['0x20', '0x40'])
    expect(register_files[4].printables[:offset_address]).to match(['0x30', '0x38', '0x50', '0x58'])
  end

  describe 'エラーチェック' do
    context '入力値が整数に変換できない場合' do
      it 'RegisterMapErrorを起こす' do
        [true, false, 'foo', '0xef_gh', Object.new].each do |value|
          expect {
            create_register_files(32) do
              register_file do
                offset_address value
                register { type :foo }
              end
            end
          }.to raise_register_map_error "cannot convert #{value.inspect} into offset address"
        end
      end
    end

    context '入力値が負数の場合' do
      it 'RegisterMapErrorを起こす' do
        [-1, -2, rand(-10..-3)].each do |value|
          expect {
            create_register_files([16, 32, 64].sample) do
              register_file do
                offset_address value
                register { type :foo }
              end
            end
          }.to raise_register_map_error "offset address is less than 0: #{value}"
        end
      end
    end

    context 'バス幅に揃っていない場合' do
      it 'RegisterMapErrorを起こす' do
        [1, 3, 7, 9, 15, 17].each do |value|
          expect {
            create_register_files(16) do
              register_file do
                offset_address value
                register { type :foo }
              end
            end
          }.to raise_register_map_error "offset address is not aligned with bus width(16): 0x#{value.to_s(16)}"
        end

        [1, 2, 3, 5, 15, 17].each do |value|
          expect {
            create_register_files(32) do
              register_file do
                offset_address value
                register { type :foo }
              end
            end
          }.to raise_register_map_error "offset address is not aligned with bus width(32): 0x#{value.to_s(16)}"
        end

        [1, 2, 3, 4, 5, 6, 7, 9, 15, 17].each do |value|
          expect {
            create_register_files(64) do
              register_file do
                offset_address value
                register { type :foo }
              end
            end
          }.to raise_register_map_error "offset address is not aligned with bus width(64): 0x#{value.to_s(16)}"
        end
      end
    end

    context 'アドレス領域がレジスタブロックのバイトサイズを超える場合' do
      it 'RegisterMapErrorを起こす' do
        expect {
          create_register_files(32) do
            register_file do
              offset_address 0x100
              register { type :foo }
            end
          end
        }.to raise_register_map_error 'offset address range exceeds byte size of register block(256): 0x100-0x103'

        expect {
          create_register_files(32) do
            register_file do
              offset_address 0xfc
              size 2
              register { type :foo }
            end
          end
        }.to raise_register_map_error 'offset address range exceeds byte size of register block(256): 0xfc-0x103'

        expect {
          create_register_files(32) do
            register_file do
              offset_address 0x00
              register { offset_address 0x100; type :foo }
            end
          end
        }.to raise_register_map_error 'offset address range exceeds byte size of register block(256): 0x0-0x103'

        expect {
          create_register_files(32) do
            register_file do
              offset_address 0xfc
              register { size 2; type :foo }
            end
          end
        }.to raise_register_map_error 'offset address range exceeds byte size of register block(256): 0xfc-0x103'

        expect {
          create_register_files(32) do
            register_file do
              offset_address 0x00
              register_file do
                offset_address 0x100
                register { type :foo }
              end
            end
          end
        }.to raise_register_map_error 'offset address range exceeds byte size of register block(256): 0x0-0x103'

        expect {
          create_register_files(32) do
            register_file do
              offset_address 0xfc
              register_file do
                offset_address 0x00
                size [2]
                register { offset_address 0x00; type :foo }
              end
            end
          end
        }.to raise_register_map_error 'offset address range exceeds byte size of register block(256): 0xfc-0x103'

        expect {
          create_register_files(32) do
            register_file do
              offset_address 0x00
              register_file do
                offset_address 0x00
                register { offset_address 0x100; type :foo }
              end
            end
          end
        }.to raise_register_map_error 'offset address range exceeds byte size of register block(256): 0x0-0x103'

        expect {
          create_register_files(32) do
            register_file do
              offset_address 0xfc
              register_file do
                offset_address 0x00
                register { offset_address 0x00; size 2; type :foo }
              end
            end
          end
        }.to raise_register_map_error 'offset address range exceeds byte size of register block(256): 0xfc-0x103'
      end
    end

    context 'アドレス領域が重複する場合' do
      it 'RegisterMapErrorを起こす' do
        expect {
          create_register_files(32) do
            register { offset_address 0x00; type :foo }
            register_file do
              offset_address 0x00
              register { offset_address 0x00; type :foo }
            end
          end
        }.to raise_register_map_error 'offset address range overlaps with other offset address range: 0x0-0x3'

        expect {
          create_register_files(32) do
            register { offset_address 0x00; type :bar }
            register_file do
              offset_address 0x00
              register { offset_address 0x00; type :baz }
            end
          end
        }.to raise_register_map_error 'offset address range overlaps with other offset address range: 0x0-0x3'

        expect {
          create_register_files(32) do
            register { offset_address 0x00; type :baz }
            register_file do
              offset_address 0x00
              register { offset_address 0x00; type :bar }
            end
          end
        }.to raise_register_map_error 'offset address range overlaps with other offset address range: 0x0-0x3'

        expect {
          create_register_files(32) do
            register { offset_address 0x00; type :qux; bit_field { bit_assignment lsb: 0, width: 32 } }
            register_file do
              offset_address 0x00
              register { offset_address 0x00; type :qux; bit_field { bit_assignment lsb: 0, width: 32 } }
            end
          end
        }.to raise_register_map_error 'offset address range overlaps with other offset address range: 0x0-0x3'

        expect {
          create_register_files(32) do
            register_file do
              offset_address 0x00
              register { offset_address 0x00; type :foo }
            end
            register_file do
              offset_address 0x00
              register { offset_address 0x00; type :foo }
            end
          end
        }.to raise_register_map_error 'offset address range overlaps with other offset address range: 0x0-0x3'

        expect {
          create_register_files(32) do
            register_file do
              offset_address 0x00
              register { offset_address 0x00; type :bar }
            end
            register_file do
              offset_address 0x00
              register { offset_address 0x00; type :baz }
            end
          end
        }.to raise_register_map_error 'offset address range overlaps with other offset address range: 0x0-0x3'

        expect {
          create_register_files(32) do
            register_file do
              offset_address 0x00
              register { offset_address 0x00; type :baz }
            end
            register_file do
              offset_address 0x00
              register { offset_address 0x00; type :bar }
            end
          end
        }.to raise_register_map_error 'offset address range overlaps with other offset address range: 0x0-0x3'

        expect {
          create_register_files(32) do
            register_file do
              offset_address 0x00
              register { offset_address 0x00; type :qux; bit_field { bit_assignment lsb: 0, width: 32 } }
            end
            register_file do
              offset_address 0x00
              register { offset_address 0x00; type :qux; bit_field { bit_assignment lsb: 0, width: 32 } }
            end
          end
        }.to raise_register_map_error 'offset address range overlaps with other offset address range: 0x0-0x3'

        expect {
          create_register_files(32) do
            register do
              offset_address 0x4; type [:foo, :bar, :baz, :qux].sample
              bit_field { bit_assignment lsb: 0, width: 32 }
            end
            register_file do
              offset_address 0x0
              size 3
              register { offset_address 0x0; type [:foo, :bar, :baz].sample }
            end
          end
        }.to raise_register_map_error 'offset address range overlaps with other offset address range: 0x0-0xb'

        expect {
          create_register_files(32) do
            register do
              offset_address 0x4; type [:foo, :bar, :baz, :qux].sample
              bit_field { bit_assignment lsb: 0, width: 32 }
            end
            register_file do
              offset_address 0x0
              size 3
              register { offset_address 0x0; type [:foo, :bar, :baz].sample }
            end
          end
        }.to raise_register_map_error 'offset address range overlaps with other offset address range: 0x0-0xb'

        expect {
          create_register_files(32) do
            register do
              offset_address 0x0; type [:foo, :bar, :baz, :qux].sample
              size [3]; bit_field { bit_assignment lsb: 0, width: 96 }
            end
            register_file do
              offset_address 0x4
              register { offset_address 0x0; type [:foo, :bar, :baz].sample }
            end
          end
        }.to raise_register_map_error 'offset address range overlaps with other offset address range: 0x4-0x7'

        expect {
          create_register_files(32) do
            register_file do
              offset_address 0x0
              size 3
              register { offset_address 0x0; type [:foo, :bar, :baz].sample }
            end
            register_file do
              offset_address 0x4
              register { offset_address 0x0; type [:foo, :bar, :baz].sample }
            end
          end
        }.to raise_register_map_error 'offset address range overlaps with other offset address range: 0x4-0x7'

        expect {
          create_register_files(32) do
            register_file do
              offset_address 0x10
              register { offset_address 0x0; type [:foo, :bar, :baz].sample }
              register_file do
                offset_address 0x0
                register { offset_address 0x0; type [:foo, :bar, :baz].sample }
              end
            end
          end
        }.to raise_register_map_error 'offset address range overlaps with other offset address range: 0x10-0x13'

        expect {
          create_register_files(32) do
            register_file do
              offset_address 0x10
              register_file do
                offset_address 0x0
                register { offset_address 0x0; type [:foo, :bar, :baz].sample }
              end
              register_file do
                offset_address 0x0
                register { offset_address 0x0; type [:foo, :bar, :baz].sample }
              end
            end
          end
        }.to raise_register_map_error 'offset address range overlaps with other offset address range: 0x10-0x13'
      end
    end
  end
end
