# frozen_string_literal: true

RSpec.describe 'register/size' do
  include_context 'clean-up builder'
  include_context 'register map common'

  before(:all) do
    RgGen.enable(:global, [:bus_width, :enable_wide_register])
    RgGen.enable(:register_file, :size)
    RgGen.enable(:register, :size)
    RgGen.enable(:bit_field, :bit_assignment)
  end

  def create_registers(**config_values, &block)
    configuraiton = create_configuration(**config_values)
    create_register_map(configuraiton) { register_block(&block) }.registers
  end

  def create_register(**config_values, &block)
    create_registers(**config_values, &block).first
  end

  describe '#size' do
    it '入力された大きさを返す' do
      register = create_register { register { size 1 } }
      expect(register).to have_property(:size, match([1]))

      register = create_register { register { size [1] } }
      expect(register).to have_property(:size, match([1]))

      register = create_register { register { size [1, 2, 3] } }
      expect(register).to have_property(:size, match([1, 2, 3]))
    end

    context '未入力の場合' do
      it 'nilを返す' do
        register = create_register { register {} }
        expect(register.size).to be_nil

        register = create_register { register { size nil } }
        expect(register.size).to be_nil

        register = create_register { register { size [] } }
        expect(register.size).to be_nil

        register = create_register { register { size '' } }
        expect(register.size).to be_nil
      end
    end
  end

  describe '#width/#byte_width' do
    context 'ビットフィールドを持つ場合' do
      let(:registers) do
        create_registers do
          register do
            bit_field { bit_assignment lsb: 0, width: 1 }
          end
          register do
            bit_field { bit_assignment lsb: 31, width: 1 }
          end
          register do
            bit_field { bit_assignment lsb: 0, width: 32 }
          end
          register do
            bit_field { bit_assignment lsb: 0, width: 8 }
            bit_field { bit_assignment lsb: 24, width: 8 }
          end
          register do
            bit_field { bit_assignment lsb: 32, width: 1 }
          end
          register do
            bit_field { bit_assignment lsb: 63, width: 1 }
          end
          register do
            bit_field { bit_assignment lsb: 31, width: 2 }
          end
          register do
            bit_field { bit_assignment lsb: 0, width: 1 }
            bit_field { bit_assignment lsb: 32, width: 1 }
          end
          register do
            bit_field { bit_assignment lsb: 0, width: 1, sequence_size: 2, step: 31 }
          end
          register do
            bit_field { bit_assignment lsb: 0, width: 1, sequence_size: 2, step: 32 }
          end
        end
      end

      it 'MSBをバス幅に切り上げた値を返す' do
        expect(registers[0]).to have_properties([[:width, 32], [:byte_width, 4]])
        expect(registers[1]).to have_properties([[:width, 32], [:byte_width, 4]])
        expect(registers[2]).to have_properties([[:width, 32], [:byte_width, 4]])
        expect(registers[3]).to have_properties([[:width, 32], [:byte_width, 4]])
        expect(registers[4]).to have_properties([[:width, 64], [:byte_width, 8]])
        expect(registers[5]).to have_properties([[:width, 64], [:byte_width, 8]])
        expect(registers[6]).to have_properties([[:width, 64], [:byte_width, 8]])
        expect(registers[7]).to have_properties([[:width, 64], [:byte_width, 8]])
        expect(registers[8]).to have_properties([[:width, 32], [:byte_width, 4]])
        expect(registers[9]).to have_properties([[:width, 64], [:byte_width, 8]])
      end
    end

    context 'ビットフィールドを持たない場合' do
      let(:register) do
        create_register { register }
      end

      it 'バス幅を返す' do
        expect(register).to have_properties([[:width, 32], [:byte_width, 4]])
      end
    end
  end

  describe '#byte_size' do
    let(:registers) do
      create_registers do
        register do
        end

        register do
          size [2]
        end

        register do
          size [2, 3]
        end

        register do
          bit_field { bit_assignment lsb: 0 }
        end

        register do
          size [2]
          bit_field { bit_assignment lsb: 0 }
        end

        register do
          size [2, 3]
          bit_field { bit_assignment lsb: 0 }
        end

        register do
          bit_field { bit_assignment lsb: 32 }
        end

        register do
          size [2]
          bit_field { bit_assignment lsb: 32 }
        end

        register do
          size [2, 3]
          bit_field { bit_assignment lsb: 32 }
        end

        register_file do
          register do
            bit_field { bit_assignment lsb: 0 }
          end

          register do
            size [2]
            bit_field { bit_assignment lsb: 0 }
          end

          register do
            size [2, 3]
            bit_field { bit_assignment lsb: 0 }
          end
        end

        register_file do
          size [2, 3]

          register_file do
            register do
              bit_field { bit_assignment lsb: 0 }
            end

            register do
              size [2]
              bit_field { bit_assignment lsb: 0 }
            end

            register do
              size [2, 3]
              bit_field { bit_assignment lsb: 0 }
            end
          end
        end
      end
    end

    context 'レジスタの属性にsupport_shared_addressの指定がなく' do
      before do
        registers.each do |register|
          allow(register).to receive(:settings).and_return({})
        end
      end

      context '無引数の場合' do
        it '#byte_widthに#sizeを乗じた値をバイトサイズとして返す' do
          expect(registers[0]).to have_property(:byte_size, 4)
          expect(registers[1]).to have_property(:byte_size, 8)
          expect(registers[2]).to have_property(:byte_size, 24)
          expect(registers[3]).to have_property(:byte_size, 4)
          expect(registers[4]).to have_property(:byte_size, 8)
          expect(registers[5]).to have_property(:byte_size, 24)
          expect(registers[6]).to have_property(:byte_size, 8)
          expect(registers[7]).to have_property(:byte_size, 16)
          expect(registers[8]).to have_property(:byte_size, 48)
          expect(registers[9]).to have_property(:byte_size, 4)
          expect(registers[10]).to have_property(:byte_size, 8)
          expect(registers[11]).to have_property(:byte_size, 24)
          expect(registers[12]).to have_property(:byte_size, 4)
          expect(registers[13]).to have_property(:byte_size, 8)
          expect(registers[14]).to have_property(:byte_size, 24)
        end
      end

      context 'falseが指定された場合' do
        it '#byte_widthを返す' do
          expect(registers[0]).to have_property(:byte_size, [false], 4)
          expect(registers[1]).to have_property(:byte_size, [false], 4)
          expect(registers[2]).to have_property(:byte_size, [false], 4)
          expect(registers[3]).to have_property(:byte_size, [false], 4)
          expect(registers[4]).to have_property(:byte_size, [false], 4)
          expect(registers[5]).to have_property(:byte_size, [false], 4)
          expect(registers[6]).to have_property(:byte_size, [false], 8)
          expect(registers[7]).to have_property(:byte_size, [false], 8)
          expect(registers[8]).to have_property(:byte_size, [false], 8)
          expect(registers[9]).to have_property(:byte_size, [false], 4)
          expect(registers[10]).to have_property(:byte_size, [false], 4)
          expect(registers[11]).to have_property(:byte_size, [false], 4)
          expect(registers[12]).to have_property(:byte_size, [false], 4)
          expect(registers[13]).to have_property(:byte_size, [false], 4)
          expect(registers[14]).to have_property(:byte_size, [false], 4)
        end
      end
    end

    context 'レジスタの属性にsupport_shared_addressの指定がある場合' do
      before do
        registers.each do |register|
          allow(register).to receive(:settings).and_return({ support_shared_address: true })
        end
      end

      it '引数に関わらず、#byte_widthを返す' do
        expect(registers[0]).to have_property(:byte_size, 4)
        expect(registers[0]).to have_property(:byte_size, [false], 4)

        expect(registers[1]).to have_property(:byte_size, 4)
        expect(registers[1]).to have_property(:byte_size, [false], 4)

        expect(registers[2]).to have_property(:byte_size, 4)
        expect(registers[2]).to have_property(:byte_size, [false], 4)

        expect(registers[3]).to have_property(:byte_size, 4)
        expect(registers[3]).to have_property(:byte_size, [false], 4)

        expect(registers[4]).to have_property(:byte_size, 4)
        expect(registers[4]).to have_property(:byte_size, [false], 4)

        expect(registers[5]).to have_property(:byte_size, 4)
        expect(registers[5]).to have_property(:byte_size, [false], 4)

        expect(registers[6]).to have_property(:byte_size, 8)
        expect(registers[6]).to have_property(:byte_size, [false], 8)

        expect(registers[7]).to have_property(:byte_size, 8)
        expect(registers[7]).to have_property(:byte_size, [false], 8)

        expect(registers[8]).to have_property(:byte_size, 8)
        expect(registers[8]).to have_property(:byte_size, [false], 8)

        expect(registers[9]).to have_property(:byte_size, 4)
        expect(registers[9]).to have_property(:byte_size, [false], 4)

        expect(registers[10]).to have_property(:byte_size, 4)
        expect(registers[10]).to have_property(:byte_size, [false], 4)

        expect(registers[11]).to have_property(:byte_size, 4)
        expect(registers[11]).to have_property(:byte_size, [false], 4)

        expect(registers[12]).to have_property(:byte_size, 4)
        expect(registers[12]).to have_property(:byte_size, [false], 4)

        expect(registers[13]).to have_property(:byte_size, 4)
        expect(registers[13]).to have_property(:byte_size, [false], 4)

        expect(registers[14]).to have_property(:byte_size, 4)
        expect(registers[14]).to have_property(:byte_size, [false], 4)
      end
    end

    context '引数hierarchicalにtrueが指定されてた場合' do
      before do
        registers.each do |register|
          value = [true, false].sample
          allow(register).to receive(:settings).and_return({ support_shared_address: value })
        end
      end

      it '上位階層の配列サイズを入れたバイトサイズを返す' do
        byte_size = registers[0].byte_size
        expect(registers[0]).to have_property(:byte_size, { hierarchical: true }, byte_size)

        byte_size = registers[1].byte_size
        expect(registers[1]).to have_property(:byte_size, { hierarchical: true }, byte_size)

        byte_size = registers[2].byte_size
        expect(registers[2]).to have_property(:byte_size, { hierarchical: true }, byte_size)

        byte_size = registers[3].byte_size
        expect(registers[3]).to have_property(:byte_size, { hierarchical: true }, byte_size)

        byte_size = registers[4].byte_size
        expect(registers[4]).to have_property(:byte_size, { hierarchical: true }, byte_size)

        byte_size = registers[5].byte_size
        expect(registers[5]).to have_property(:byte_size, { hierarchical: true }, byte_size)

        byte_size = registers[6].byte_size
        expect(registers[6]).to have_property(:byte_size, { hierarchical: true }, byte_size)

        byte_size = registers[7].byte_size
        expect(registers[7]).to have_property(:byte_size, { hierarchical: true }, byte_size)

        byte_size = registers[8].byte_size
        expect(registers[8]).to have_property(:byte_size, { hierarchical: true }, byte_size)

        byte_size = registers[9].byte_size
        expect(registers[9]).to have_property(:byte_size, { hierarchical: true }, byte_size)

        byte_size = registers[10].byte_size
        expect(registers[10]).to have_property(:byte_size, { hierarchical: true }, byte_size)

        byte_size = registers[11].byte_size
        expect(registers[11]).to have_property(:byte_size, { hierarchical: true }, byte_size)

        byte_size = registers[12].byte_size
        expect(registers[12]).to have_property(:byte_size, { hierarchical: true }, 2 * 3 * byte_size)

        byte_size = registers[13].byte_size
        expect(registers[13]).to have_property(:byte_size, { hierarchical: true }, 2 * 3 * byte_size)

        byte_size = registers[14].byte_size
        expect(registers[14]).to have_property(:byte_size, { hierarchical: true }, 2 * 3 * byte_size)
      end
    end
  end

  describe '#array?' do
    let(:registers) do
      create_registers do
        register { size [2] }
        register { size [2, 3] }
        register {}
        register_file do
          register { size [2] }
          register { size [2, 3] }
          register {}
        end
        register_file do
          size [2, 3]
          register_file do
            register { size [2] }
            register { size [2, 3] }
            register {}
          end
        end
      end
    end

    context 'レジスタが配列に対応していて、#sizeの設定がある場合' do
      it '真を返す' do
        allow(registers[0]).to receive(:settings).and_return(support_array: true)
        expect(registers[0]).to have_property(:array?, true)

        allow(registers[1]).to receive(:settings).and_return(support_array: true)
        expect(registers[1]).to have_property(:array?, true)

        allow(registers[3]).to receive(:settings).and_return(support_array: true)
        expect(registers[3]).to have_property(:array?, true)

        allow(registers[4]).to receive(:settings).and_return(support_array: true)
        expect(registers[4]).to have_property(:array?, true)

        allow(registers[6]).to receive(:settings).and_return(support_array: true)
        expect(registers[6]).to have_property(:array?, true)

        allow(registers[7]).to receive(:settings).and_return(support_array: true)
        expect(registers[7]).to have_property(:array?, true)
      end
    end

    context 'レジスタが配列に対応していて、#sizeの設定がない場合' do
      it '偽を返す' do
        allow(registers[2]).to receive(:settings).and_return(support_array: true)
        expect(registers[2]).to have_property(:array?, false)

        allow(registers[5]).to receive(:settings).and_return(support_array: true)
        expect(registers[5]).to have_property(:array?, false)

        allow(registers[8]).to receive(:settings).and_return(support_array: true)
        expect(registers[8]).to have_property(:array?, false)
      end
    end

    context 'レジスタが配列に対応していない場合' do
      it '偽を返す' do
        allow(registers[0]).to receive(:settings).and_return({})
        expect(registers[0]).to have_property(:array?, false)

        allow(registers[1]).to receive(:settings).and_return({})
        expect(registers[1]).to have_property(:array?, false)

        allow(registers[2]).to receive(:settings).and_return({})
        expect(registers[2]).to have_property(:array?, false)

        allow(registers[3]).to receive(:settings).and_return({})
        expect(registers[3]).to have_property(:array?, false)

        allow(registers[4]).to receive(:settings).and_return({})
        expect(registers[4]).to have_property(:array?, false)

        allow(registers[5]).to receive(:settings).and_return({})
        expect(registers[5]).to have_property(:array?, false)

        allow(registers[6]).to receive(:settings).and_return({})
        expect(registers[6]).to have_property(:array?, false)

        allow(registers[7]).to receive(:settings).and_return({})
        expect(registers[7]).to have_property(:array?, false)

        allow(registers[8]).to receive(:settings).and_return({})
        expect(registers[8]).to have_property(:array?, false)
      end
    end

    context '引数hierarchicalにtrueが指定されて' do
      before do
        registers.each do |register|
          value = [true, false].sample
          allow(register).to receive(:settings).and_return(support_array: value)
        end
      end

      context '上位に配列レジスタファイル階層がない場合' do
        it '引数未指定の場合と同じ結果を返す' do
          expect(registers[0]).to have_property(:array?, { hierarchical: true }, registers[0].array?)
          expect(registers[1]).to have_property(:array?, { hierarchical: true }, registers[1].array?)
          expect(registers[2]).to have_property(:array?, { hierarchical: true }, registers[2].array?)
          expect(registers[3]).to have_property(:array?, { hierarchical: true }, registers[3].array?)
          expect(registers[4]).to have_property(:array?, { hierarchical: true }, registers[4].array?)
          expect(registers[5]).to have_property(:array?, { hierarchical: true }, registers[5].array?)
        end
      end

      context '上位に配列レジスタファイル階層を含む場合' do
        it 'trueを返す' do
          expect(registers[6]).to have_property(:array?, { hierarchical: true }, true)
          expect(registers[7]).to have_property(:array?, { hierarchical: true }, true)
          expect(registers[8]).to have_property(:array?, { hierarchical: true }, true)
        end
      end
    end
  end

  describe '#array_size' do
    let(:registers) do
      create_registers do
        register { size [2] }
        register { size [2, 3] }
        register {}
        register_file do
          register { size [2] }
          register { size [2, 3] }
          register {}
        end
        register_file do
          size [2, 3]
          register_file do
            register { size [2] }
            register { size [2, 3] }
            register {}
          end
        end
      end
    end

    context 'レジスタが配列レジスタの場合' do
      it '#sizeを返す' do
        allow(registers[0]).to receive(:settings).and_return(support_array: true)
        expect(registers[0]).to have_property(:array_size, match([2]))

        allow(registers[1]).to receive(:settings).and_return(support_array: true)
        expect(registers[1]).to have_property(:array_size, match([2, 3]))

        allow(registers[3]).to receive(:settings).and_return(support_array: true)
        expect(registers[3]).to have_property(:array_size, match([2]))

        allow(registers[4]).to receive(:settings).and_return(support_array: true)
        expect(registers[4]).to have_property(:array_size, match([2, 3]))

        allow(registers[6]).to receive(:settings).and_return(support_array: true)
        expect(registers[6]).to have_property(:array_size, match([2]))

        allow(registers[7]).to receive(:settings).and_return(support_array: true)
        expect(registers[7]).to have_property(:array_size, match([2, 3]))
      end
    end

    context 'レジスタが配列レジスタではない場合' do
      it 'nilを返す' do
        allow(registers[0]).to receive(:settings).and_return({})
        expect(registers[0]).to have_property(:array_size, nil)

        allow(registers[1]).to receive(:settings).and_return({})
        expect(registers[1]).to have_property(:array_size, nil)

        allow(registers[2]).to receive(:settings).and_return(support_array: true)
        expect(registers[2]).to have_property(:array_size, nil)

        allow(registers[3]).to receive(:settings).and_return({})
        expect(registers[3]).to have_property(:array_size, nil)

        allow(registers[4]).to receive(:settings).and_return({})
        expect(registers[4]).to have_property(:array_size, nil)

        allow(registers[5]).to receive(:settings).and_return(support_array: true)
        expect(registers[5]).to have_property(:array_size, nil)

        allow(registers[6]).to receive(:settings).and_return({})
        expect(registers[6]).to have_property(:array_size, nil)

        allow(registers[7]).to receive(:settings).and_return({})
        expect(registers[7]).to have_property(:array_size, nil)

        allow(registers[8]).to receive(:settings).and_return(support_array: true)
        expect(registers[8]).to have_property(:array_size, nil)
      end
    end

    context '引数hierarchicalにtrueが指定され' do
      before do
        registers.each do |register|
          value = [true, false].sample
          allow(register).to receive(:settings).and_return(support_array: value)
        end
      end

      context '上位に配列レジスタファイル階層がない場合' do
        it '引数未指定の場合と同じ結果を返す' do
          expect(registers[0]).to have_property(:array_size, { hierarchical: true }, registers[0].array_size)
          expect(registers[1]).to have_property(:array_size, { hierarchical: true }, registers[1].array_size)
          expect(registers[2]).to have_property(:array_size, { hierarchical: true }, registers[2].array_size)
          expect(registers[3]).to have_property(:array_size, { hierarchical: true }, registers[3].array_size)
          expect(registers[4]).to have_property(:array_size, { hierarchical: true }, registers[4].array_size)
          expect(registers[5]).to have_property(:array_size, { hierarchical: true }, registers[5].array_size)
        end
      end

      context '上位に配列レジスタファイル階層を含む場合' do
        it '上位のレジスタファイル階層の配列サイズを含んだ配列サイズを返す' do
          size = registers[6].array_size
          expect(registers[6]).to have_property(:array_size, { hierarchical: true }, [2, 3, *size])

          size = registers[7].array_size
          expect(registers[7]).to have_property(:array_size, { hierarchical: true }, [2, 3, *size])

          size = registers[8].array_size
          expect(registers[8]).to have_property(:array_size, { hierarchical: true }, [2, 3, *size])
        end
      end
    end
  end

  describe '#count' do
    let(:registers) do
      create_registers do
        register {}
        register { size [2] }
        register { size [2] }
        register { size [2, 3] }
        register { size [2, 3] }
      end
    end

    context '無引数の場合' do
      it 'レジスタの総要素数を返す' do
        allow(registers[0]).to receive(:settings).and_return(support_array: true)
        expect(registers[0]).to have_property(:count, 1)

        allow(registers[1]).to receive(:settings).and_return(support_array: true)
        expect(registers[1]).to have_property(:count, 2)

        allow(registers[2]).to receive(:settings).and_return({})
        expect(registers[2]).to have_property(:count, 1)

        allow(registers[3]).to receive(:settings).and_return(support_array: true)
        expect(registers[3]).to have_property(:count, 6)

        allow(registers[4]).to receive(:settings).and_return({})
        expect(registers[4]).to have_property(:count, 1)
      end
    end

    context '引数にfalseが与えられた場合' do
      it '1を返す' do
        allow(registers[0]).to receive(:settings).and_return(support_array: true)
        expect(registers[0]).to have_property(:count, [false], 1)

        allow(registers[1]).to receive(:settings).and_return(support_array: true)
        expect(registers[1]).to have_property(:count, [false], 1)

        allow(registers[2]).to receive(:settings).and_return({})
        expect(registers[2]).to have_property(:count, [false], 1)

        allow(registers[3]).to receive(:settings).and_return(support_array: true)
        expect(registers[3]).to have_property(:count, [false], 1)

        allow(registers[4]).to receive(:settings).and_return({})
        expect(registers[4]).to have_property(:count, [false], 1)
      end
    end
  end

  specify '文字列も入力できる' do
    register = create_register { register { size '1' } }
    expect(register).to have_property(:size, match([1]))

    register = create_register { register { size '[1]' } }
    expect(register).to have_property(:size, match([1]))

    register = create_register { register { size '1, 2' } }
    expect(register).to have_property(:size, match([1, 2]))

    register = create_register { register { size '[1, 2]' } }
    expect(register).to have_property(:size, match([1, 2]))

    register = create_register { register { size '1, 2, 3' } }
    expect(register).to have_property(:size, match([1, 2, 3]))

    register = create_register { register { size '[1, 2, 3]' } }
    expect(register).to have_property(:size, match([1, 2, 3]))
  end

  describe 'エラーチェック' do
    context '入力文字列がパターンに一致しなかった場合' do
      it 'RegisterMapErrorを起こす' do
        [
          'foo',
          '0xef_gh',
          '[1',
          '1]',
          '[1,2',
          '1, 2]',
          '[foo, 2]',
          '[1, foo]',
          '[1:2]'
        ].each do |value|
          expect {
            create_register { register { size value } }
          }.to raise_register_map_error "illegal input value for register size: #{value.inspect}"
        end
      end
    end

    context '大きさの各要素が整数に変換できなかった場合' do
      it 'RegisterMapErrorを起こす' do
        [nil, true, false, 'foo', '0xef_gh', Object.new].each_with_index do |value, i|
          if [1, 2, 5].include?(i)
            expect {
              create_register { register { size value } }
            }.to raise_register_map_error "cannot convert #{value.inspect} into register size"
          end

          expect {
            create_register { register { size [value] } }
          }.to raise_register_map_error "cannot convert #{value.inspect} into register size"

          expect {
            create_register { register { size [1, value] } }
          }.to raise_register_map_error "cannot convert #{value.inspect} into register size"

          expect {
            create_register { register { size [1, 2, value] } }
          }.to raise_register_map_error "cannot convert #{value.inspect} into register size"
        end
      end
    end

    context '大きさに 1 未満の要素が含まれる場合' do
      it 'RegisterMapErrorを起こす' do
        [0, -1, -2, -7].each do |value|
          expect {
            create_register { register { size value } }
          }.to raise_register_map_error "non positive value(s) are not allowed for register size: [#{value}]"

          expect {
            create_register { register { size [value] } }
          }.to raise_register_map_error "non positive value(s) are not allowed for register size: [#{value}]"

          expect {
            create_register { register { size [1, value] } }
          }.to raise_register_map_error "non positive value(s) are not allowed for register size: [1, #{value}]"

          expect {
            create_register { register { size [value, 1] } }
          }.to raise_register_map_error "non positive value(s) are not allowed for register size: [#{value}, 1]"

          expect {
            create_register { register { size [value, value] } }
          }.to raise_register_map_error "non positive value(s) are not allowed for register size: [#{value}, #{value}]"

          expect {
            create_register { register { size [1, value, 2] } }
          }.to raise_register_map_error "non positive value(s) are not allowed for register size: [1, #{value}, 2]"

          expect {
            create_register { register { size [1, 2, value] } }
          }.to raise_register_map_error "non positive value(s) are not allowed for register size: [1, 2, #{value}]"

          expect {
            create_register { register { size [1, value, value] } }
          }.to raise_register_map_error "non positive value(s) are not allowed for register size: [1, #{value}, #{value}]"

          expect {
            create_register { register { size [value, 1, value] } }
          }.to raise_register_map_error "non positive value(s) are not allowed for register size: [#{value}, 1, #{value}]"

          expect {
            create_register { register { size [value, value, 1] } }
          }.to raise_register_map_error "non positive value(s) are not allowed for register size: [#{value}, #{value}, 1]"

          expect {
            create_register { register { size [value, value, value] } }
          }.to raise_register_map_error "non positive value(s) are not allowed for register size: [#{value}, #{value}, #{value}]"
        end
      end
    end

    context '幅広レジスタが許可されておらず、幅が8バイトを超える場合' do
      it 'RegisterMapErrorを起こす' do
        expect {
          create_register(enable_wide_register: false) do
            register { bit_field { bit_assignment lsb: 63 } }
          end
        }.not_to raise_error

        expect {
          create_register(enable_wide_register: false) do
            register { bit_field { bit_assignment lsb: 64 } }
          end
        }.to raise_register_map_error 'register width wider than 8 bytes is not allowed: 12 bytes'

        expect {
          create_register(enable_wide_register: false) do
            register { bit_field { bit_assignment lsb: 127 } }
          end
        }.to raise_register_map_error 'register width wider than 8 bytes is not allowed: 16 bytes'
      end
    end

    context '幅広レジスタが許可されている場合' do
      specify '幅が8バイトを超えるレジスタを定義できる' do
        expect {
          create_register(enable_wide_register: true) do
            register { bit_field { bit_assignment lsb: 64 } }
          end
        }.not_to raise_error

        expect {
          create_register(enable_wide_register: true) do
            register { bit_field { bit_assignment lsb: 127 } }
          end
        }.not_to raise_error
      end
    end
  end
end
