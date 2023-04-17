# frozen_string_literal: true

RSpec.describe 'register_file/size' do
  include_context 'clean-up builder'
  include_context 'register map common'

  before(:all) do
    RgGen.define_list_item_feature(:register, :type, :foo) do
      register_map do
        no_bit_fields
        support_array_register
      end
    end

    RgGen.enable(:global, [:bus_width, :address_width, :enable_wide_register])
    RgGen.enable(:register_block, :byte_size)
    RgGen.enable(:register_file, [:offset_address, :size])
    RgGen.enable(:register, [:offset_address, :size, :type])
    RgGen.enable(:register, :type, [:foo])
  end

  after(:all) do
    RgGen.delete(:register, :type, [:foo])
  end

  let(:bus_width) { 32 }

  let(:address_width) { 16 }

  let(:block_byte_size) { 1024 }

  def create_register_files(&block)
    configuration =
      create_configuration(bus_width: bus_width, address_width: address_width)
    register_map = create_register_map(configuration) do
      register_block do
        byte_size block_byte_size
        instance_eval(&block)
      end
    end
    register_map.register_files
  end

  def create_register_file(&block)
    create_register_files(&block).first
  end

  describe '#size/array_size' do
    it '入力された大きさを返す' do
      register_files = create_register_files do
        register_file do
          offset_address 0x00; size [1]
          register { offset_address 0x00; type :foo }
        end

        register_file do
          offset_address 0x10; size [2]
          register { offset_address 0x00; type :foo }
        end

        register_file do
          offset_address 0x20; size [3, 4, 5]
          register { offset_address 0x00; type :foo }
        end
      end

      expect(register_files[0]).to have_property(:size, match([1]))
      expect(register_files[1]).to have_property(:size, match([2]))
      expect(register_files[2]).to have_property(:size, match([3, 4, 5]))

      expect(register_files[0]).to have_property(:array_size, match([1]))
      expect(register_files[1]).to have_property(:array_size, match([2]))
      expect(register_files[2]).to have_property(:array_size, match([3, 4, 5]))
    end

    context '未入力の場合' do
      it 'nilを返す' do
        register_files = create_register_files do
          register_file do
            offset_address 0x00; size nil
            register { offset_address 0x00; type :foo }
          end

          register_file do
            offset_address 0x10; size []
            register { offset_address 0x00; type :foo }
          end

          register_file do
            offset_address 0x20; size ''
            register { offset_address 0x00; type :foo }
          end
        end

        expect(register_files[0].size).to be_nil
        expect(register_files[1].size).to be_nil
        expect(register_files[2].size).to be_nil

        expect(register_files[0].array_size).to be_nil
        expect(register_files[1].array_size).to be_nil
        expect(register_files[2].array_size).to be_nil
      end
    end
  end

  describe '#entry_byte_size' do
    context 'stepが未指定の場合' do
      it '一レジスタファイル当たりの総バイト数を返す' do
        register_file = create_register_file do
          register_file do
            offset_address 0x00
            register { offset_address 0x00; type :foo }
          end
        end
        expect(register_file).to have_property(:entry_byte_size, 4)

        register_file = create_register_file do
          register_file do
            offset_address 0x00
            register { offset_address 0x00; type :foo; size [2] }
          end
        end
        expect(register_file).to have_property(:entry_byte_size, 8)

        register_file = create_register_file do
          register_file do
            offset_address 0x00
            register { offset_address 0x00; type :foo; size [2, step: 8] }
          end
        end
        expect(register_file).to have_property(:entry_byte_size, 16)

        register_file = create_register_file do
          register_file do
            offset_address 0x00
            register { offset_address 0x04; type :foo }
          end
        end
        expect(register_file).to have_property(:entry_byte_size, 8)

        register_file = create_register_file do
          register_file do
            offset_address 0x00
            register_file do
              offset_address 0x00
              register { offset_address 0x00; type :foo }
            end
          end
        end
        expect(register_file).to have_property(:entry_byte_size, 4)

        register_file = create_register_file do
          register_file do
            offset_address 0x00
            register_file do
              offset_address 0x00
              register { offset_address 0x00; type :foo }
            end
            register_file do
              offset_address 0x04
              register { offset_address 0x00; type :foo }
            end
            register { offset_address 0x08; type :foo }
          end
        end
        expect(register_file).to have_property(:entry_byte_size, 12)

        register_file = create_register_file do
          register_file do
            offset_address 0x04
            register_file do
              offset_address 0x04
              register_file do
                offset_address 0x04
                register { offset_address 0x04; type :foo }
              end
            end
          end
        end
        expect(register_file).to have_property(:entry_byte_size, 16)

        register_file = create_register_file do
          register_file do
            offset_address 0x00
            size [2]
            register { offset_address 0x04; type :foo }
          end
        end
        expect(register_file).to have_property(:entry_byte_size, 8)

        register_file = create_register_file do
          register_file do
            offset_address 0x00
            size [2, 4]
            register { offset_address 0x04; type :foo }
          end
        end
        expect(register_file).to have_property(:entry_byte_size, 8)

        register_file = create_register_file do
          register_file do
            offset_address 0x00
            register_file do
              offset_address 0x04
              size [2, 4]
              register { offset_address 0x00; type :foo }
            end
          end
        end
        expect(register_file).to have_property(:entry_byte_size, 36)
      end
    end

    context 'stepが指定されている場合' do
      it '1レジスタファイルあたりのサイズとしてstepを返す' do
        register_file = create_register_file do
          register_file do
            offset_address 0x00
            size [2, step: 16]
            register { offset_address 0x04; type :foo }
          end
        end
        expect(register_file).to have_property(:entry_byte_size, 16)

        register_file = create_register_file do
          register_file do
            offset_address 0x00
            size [2, 4, step: 16]
            register { offset_address 0x04; type :foo }
          end
        end
        expect(register_file).to have_property(:entry_byte_size, 16)

        register_file = create_register_file do
          register_file do
            offset_address 0x00
            size [1, step: 256]
            register_file do
              offset_address 0x04
              size [2, 4, step: 16]
              register { offset_address 0x00; type :foo }
            end
          end
        end
        expect(register_file).to have_property(:entry_byte_size, 256)
      end
    end
  end

  describe '#total_byte_size' do
    it 'レジスタファイルが占める総バイト数を返す' do
      register_file = create_register_file do
        register_file do
          offset_address 0x00
          register { offset_address 0x00; type :foo }
        end
      end
      expect(register_file).to have_property(:total_byte_size, 4)

      register_file = create_register_file do
        register_file do
          offset_address 0x00
          register { offset_address 0x00; type :foo; size [2] }
        end
      end
      expect(register_file).to have_property(:total_byte_size, 8)

      register_file = create_register_file do
        register_file do
          offset_address 0x00
          register { offset_address 0x00; type :foo; size [2, step: 8] }
        end
      end
      expect(register_file).to have_property(:total_byte_size, 16)

      register_file = create_register_file do
        register_file do
          offset_address 0x00
          register { offset_address 0x04; type :foo }
        end
      end
      expect(register_file).to have_property(:total_byte_size, 8)

      register_file = create_register_file do
        register_file do
          offset_address 0x00
          register_file do
            offset_address 0x00
            register { offset_address 0x00; type :foo }
          end
        end
      end
      expect(register_file).to have_property(:total_byte_size, 4)

      register_file = create_register_file do
        register_file do
          offset_address 0x00
          register_file do
            offset_address 0x00
            register { offset_address 0x00; type :foo }
          end
          register_file do
            offset_address 0x04
            register { offset_address 0x00; type :foo }
          end
          register { offset_address 0x08; type :foo }
        end
      end
      expect(register_file).to have_property(:total_byte_size, 12)

      register_file = create_register_file do
        register_file do
          offset_address 0x04
          register_file do
            offset_address 0x04
            register_file do
              offset_address 0x04
              register { offset_address 0x04; type :foo }
            end
          end
        end
      end
      expect(register_file).to have_property(:total_byte_size, 16)

      register_file = create_register_file do
        register_file do
          offset_address 0x00
          size [2]
          register { offset_address 0x04; type :foo }
        end
      end
      expect(register_file).to have_property(:total_byte_size, 16)

      register_file = create_register_file do
        register_file do
          offset_address 0x00
          size [2, step: 32]
          register { offset_address 0x04; type :foo }
        end
      end
      expect(register_file).to have_property(:total_byte_size, 64)

      register_file = create_register_file do
        register_file do
          offset_address 0x00
          size [2, 4]
          register { offset_address 0x04; type :foo }
        end
      end
      expect(register_file).to have_property(:total_byte_size, 64)

      register_file = create_register_file do
        register_file do
          offset_address 0x00
          size [2, 4, step: 16]
          register { offset_address 0x04; type :foo }
        end
      end
      expect(register_file).to have_property(:total_byte_size, 128)

      register_file = create_register_file do
        register_file do
          offset_address 0x00
          size [1, step: 128]
          register_file do
            offset_address 0x0
            size [2, 4, step: 8]
            register { offset_address 0x00; type :foo }
          end
        end
      end
      expect(register_file).to have_property(:entry_byte_size, 128)
    end
  end

  describe '#array?' do
    context '#sizeの指定がある場合' do
      specify '配列レジスタファイルである' do
        register_file = create_register_file do
          register_file { offset_address 0x00; size [1]; register { type :foo } }
        end
        expect(register_file).to have_property(:array?, true)
      end
    end

    context '#sizeの指定がない場合' do
      specify '配列レジスタファイルではない' do
        register_file = create_register_file do
          register_file { offset_address 0x00; register { type :foo } }
        end
        expect(register_file).to have_property(:array?, false)
      end
    end

    specify '上位レジスタファイルが配列状になっているかは影響しない' do
      register_files = create_register_files do
        register_file do
          offset_address 0x00
          size [2]
          register_file do
            offset_address 0x00
            register { type :foo }
          end
        end
      end
      expect(register_files[1]).to have_property(:array?, false)

      register_files = create_register_files do
        register_file do
          offset_address 0x00
          register_file do
            offset_address 0x00
            size [2]
            register { type :foo }
          end
        end
      end
      expect(register_files[1]).to have_property(:array?, true)
    end
  end

  describe '#count' do
    context '無引数の場合' do
      it 'レジスタファイル内の総レジスタ数を返す' do
        register_file = create_register_file do
          register_file do
            offset_address 0x00
            register { offset_address 0x00; type :foo }
          end
        end
        expect(register_file).to have_property(:count, 1)

        register_file = create_register_file do
          register_file do
            offset_address 0x00
            register { offset_address 0x00; type :foo }
            register { offset_address 0x04; type :foo }
          end
        end
        expect(register_file).to have_property(:count, 2)

        register_file = create_register_file do
          register_file do
            offset_address 0x00
            register { offset_address 0x00; size [2]; type :foo }
            register { offset_address 0x10; size [4]; type :foo }
          end
        end
        expect(register_file).to have_property(:count, 6)

        register_file = create_register_file do
          register_file do
            offset_address 0x00
            size [2, 3]
            register { offset_address 0x00; size [2]; type :foo }
            register { offset_address 0x10; size [4]; type :foo }
          end
        end
        expect(register_file).to have_property(:count, 36)

        register_file = create_register_file do
          register_file do
            offset_address 0x00
            register_file do
              offset_address 0x00
              register { offset_address 0x00; type :foo }
              register { offset_address 0x04; type :foo }
            end
            register { offset_address 0x10; size [4]; type :foo }
          end
        end
        expect(register_file).to have_property(:count, 6)

        register_file = create_register_file do
          register_file do
            offset_address 0x00
            size [2]
            register_file do
              offset_address 0x00
              size [3]
              register_file do
                offset_address 0x00
                size [4]
                register { offset_address 0x00; type :foo }
              end
            end
          end
        end
        expect(register_file).to have_property(:count, 24)
      end
    end

    context 'falseが与えられた場合' do
      it '1レジスタファイル当たりの総レジスタ数を返す' do
        register_file = create_register_file do
          register_file do
            offset_address 0x00
            register { offset_address 0x00; type :foo }
          end
        end
        expect(register_file).to have_property(:count, [false], 1)

        register_file = create_register_file do
          register_file do
            offset_address 0x00
            register { offset_address 0x00; type :foo }
            register { offset_address 0x04; type :foo }
          end
        end
        expect(register_file).to have_property(:count, [false], 2)

        register_file = create_register_file do
          register_file do
            offset_address 0x00
            register { offset_address 0x00; size [2]; type :foo }
            register { offset_address 0x10; size [4]; type :foo }
          end
        end
        expect(register_file).to have_property(:count, [false], 6)

        register_file = create_register_file do
          register_file do
            offset_address 0x00
            size [2, 3]
            register { offset_address 0x00; size [2]; type :foo }
            register { offset_address 0x10; size [4]; type :foo }
          end
        end
        expect(register_file).to have_property(:count, [false], 6)

        register_file = create_register_file do
          register_file do
            offset_address 0x00
            register_file do
              offset_address 0x00
              register { offset_address 0x00; type :foo }
              register { offset_address 0x04; type :foo }
            end
            register { offset_address 0x10; size [4]; type :foo }
          end
        end
        expect(register_file).to have_property(:count, [false], 6)

        register_file = create_register_file do
          register_file do
            offset_address 0x00
            size [2]
            register_file do
              offset_address 0x00
              size [3]
              register_file do
                offset_address 0x00
                size [4]
                register { offset_address 0x00; type :foo }
              end
            end
          end
        end
        expect(register_file).to have_property(:count, [false], 12)
      end
    end
  end

  specify '文字列でも入力できる' do
    register_file = create_register_file do
      register_file { offset_address 0x00; size '1'; register { type :foo } }
    end
    expect(register_file).to have_property(:size, match([1]))

    register_file = create_register_file do
      register_file { offset_address 0x00; size '1, 2'; register { type :foo } }
    end
    expect(register_file).to have_property(:size, match([1, 2]))

    register_file = create_register_file do
      register_file { offset_address 0x00; size '1, 2, 3'; register { type :foo } }
    end
    expect(register_file).to have_property(:size, match([1, 2, 3]))

    register_file = create_register_file do
      register_file { offset_address 0x00; size '1, 2, 3: step: 8'; register { type :foo } }
    end
    expect(register_file).to have_property(:size, match([1, 2, 3]))
    expect(register_file).to have_property(:entry_byte_size, 8)
  end

  describe 'エラーチェック' do
    context '入力値が整数に変換できなかった場合' do
      it 'RegisterMapErrorを起こす' do
        [nil, true, false, 'foo', '0xef_gh', Object.new].each_with_index do |value, i|
          if [1, 2, 5].include?(i)
            expect {
              create_register_file do
                register_file { offset_address 0x00; size value }
              end
            }.to raise_register_map_error "cannot convert #{value.inspect} into register file size"
          end

          expect {
            create_register_file do
              register_file { offset_address 0x00; size [value] }
            end
          }.to raise_register_map_error "cannot convert #{value.inspect} into register file size"

          expect {
            create_register_file do
              register_file { offset_address 0x00; size [value, step: 8] }
            end
          }.to raise_register_map_error "cannot convert #{value.inspect} into register file size"
        end
      end
    end

    context '入力値に１未満の要素が含まれる場合' do
      it 'RegisterMapErrorを起こす' do
        [0, -1, -2, -7].each do |value|
          expect {
            create_register_file do
              register_file { offset_address 0x00; size value }
            end
          }.to raise_register_map_error "non positive value(s) are not allowed for register file size: [#{value}]"

          expect {
            create_register_file do
              register_file { offset_address 0x00; size [value] }
            end
          }.to raise_register_map_error "non positive value(s) are not allowed for register file size: [#{value}]"

          expect {
            create_register_file do
              register_file { offset_address 0x00; size [1, value] }
            end
          }.to raise_register_map_error "non positive value(s) are not allowed for register file size: [1, #{value}]"

          expect {
            create_register_file do
              register_file { offset_address 0x00; size [value, value] }
            end
          }.to raise_register_map_error "non positive value(s) are not allowed for register file size: [#{value}, #{value}]"

          expect {
            create_register_file do
              register_file { offset_address 0x00; size [1, value, 2] }
            end
          }.to raise_register_map_error "non positive value(s) are not allowed for register file size: [1, #{value}, 2]"

          expect {
            create_register_file do
              register_file { offset_address 0x00; size [1, 2, value] }
            end
          }.to raise_register_map_error "non positive value(s) are not allowed for register file size: [1, 2, #{value}]"

          expect {
            create_register_file do
              register_file { offset_address 0x00; size [1, value, value] }
            end
          }.to raise_register_map_error "non positive value(s) are not allowed for register file size: [1, #{value}, #{value}]"

          expect {
            create_register_file do
              register_file { offset_address 0x00; size [value, 1, value] }
            end
          }.to raise_register_map_error "non positive value(s) are not allowed for register file size: [#{value}, 1, #{value}]"

          expect {
            create_register_file do
              register_file { offset_address 0x00; size [value, value, 1] }
            end
          }.to raise_register_map_error "non positive value(s) are not allowed for register file size: [#{value}, #{value}, 1]"

          expect {
            create_register_file do
              register_file { offset_address 0x00; size [value, value, value] }
            end
          }.to raise_register_map_error "non positive value(s) are not allowed for register file size: [#{value}, #{value}, #{value}]"
        end
      end
    end

    context '指定されたstepが実際のバイト数未満の場合' do
      it 'RegisterMapErrorを起こす' do
        [15, 8, 4, 3, 2, 1, 0, -1].each do |step|
          expect {
            create_register_file do
              register_file do
                size [1, step: step]
                register { offset_address 0x00; type :foo }
                register { offset_address 0x04; type :foo; size [3] }
              end
            end
          }.to raise_register_map_error "step size is less than actual byte size: #{step}"
        end

        [7, 4, 3, 2, 1, 0, -1].each do |step|
          expect {
            create_register_file do
              register_file do
                size [1, step: step]
                register_file do
                  offset_address 0x00
                  register { offset_address 0x00; type :foo }
                end
                register_file do
                  offset_address 0x04
                  register { offset_address 0x00; type :foo }
                end
              end
            end
          }.to raise_register_map_error "step size is less than actual byte size: #{step}"
        end

        [15, 8, 4, 3, 2, 1, 0, -1].each do |step|
          expect {
            create_register_file do
              register_file do
                size [1, step: step]
                register_file do
                  size [2, step: 8]
                  register { offset_address 0x00; type :foo }
                end
              end
            end
          }.to raise_register_map_error "step size is less than actual byte size: #{step}"
        end
      end
    end

    context '指定されたstepがバス幅の倍数になっていない場合' do
      it 'RegisterMapErrorを起こす' do
        [5, 6, 7, 9, 10, 11].each do |step|
          expect {
            create_register_file do
              register_file do
                size [1, step: step]
                register { offset_address 0x00; type :foo }
              end
            end
          }.to raise_register_map_error "step size is not multiple of bus width: #{step}"
        end
      end
    end
  end
end
