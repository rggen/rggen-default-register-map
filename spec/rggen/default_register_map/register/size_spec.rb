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

  def create_registers(**kwargs, &block)
    settings = {
      support_array: kwargs.fetch(:support_array, true),
      support_shared_address: kwargs.fetch(:support_shared_address, false)
    }
    allow(RgGen::Core::RegisterMap::Component)
      .to receive(:new)
      .and_wrap_original do |m, *args, &b|
        m.call(*args).tap do |c|
          if c.register?
            allow(c).to receive(:settings).and_return(settings)
          end
          b.call(c)
        end
      end

    config_values = kwargs.reject do |key, _|
      [:support_array, :support_shared_address].include?(key)
    end
    configuration = create_configuration(**config_values)
    create_register_map(configuration) { register_block(&block) }.registers
  end

  def create_register(**kwargs, &block)
    create_registers(**kwargs, &block).first
  end

  describe '#size' do
    it '入力された大きさを返す' do
      register = create_register { register { size 1 } }
      expect(register).to have_property(:size, match([1]))

      register = create_register { register { size [1] } }
      expect(register).to have_property(:size, match([1]))

      register = create_register { register { size [1, 2, 3] } }
      expect(register).to have_property(:size, match([1, 2, 3]))

      register = create_register { register { size [1, step: 4] } }
      expect(register).to have_property(:size, match([1]))

      register = create_register { register { size [1, step: 4] } }
      expect(register).to have_property(:size, match([1]))

      register = create_register { register { size [1, 2, 3, step: 4] } }
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
      it 'MSBをバス幅に切り上げた値を返す' do
        registers = create_registers do
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
      it 'バス幅を返す' do
        register = create_register { register {} }
        expect(register).to have_properties([[:width, 32], [:byte_width, 4]])
      end
    end
  end

  describe '#entry_byte_size' do
    context 'stepが未指定の場合' do
      it '配列一要素あたりのレジスタ幅として、#byte_widthを返す' do
        registers = create_registers do
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
        end

        expect(registers[0]).to have_property(:entry_byte_size, registers[0].byte_width)
        expect(registers[1]).to have_property(:entry_byte_size, registers[1].byte_width)
        expect(registers[2]).to have_property(:entry_byte_size, registers[2].byte_width)
        expect(registers[3]).to have_property(:entry_byte_size, registers[3].byte_width)
        expect(registers[4]).to have_property(:entry_byte_size, registers[4].byte_width)
        expect(registers[5]).to have_property(:entry_byte_size, registers[5].byte_width)
        expect(registers[6]).to have_property(:entry_byte_size, registers[6].byte_width)
        expect(registers[7]).to have_property(:entry_byte_size, registers[7].byte_width)
        expect(registers[8]).to have_property(:entry_byte_size, registers[8].byte_width)
      end
    end

    context 'stepが指定されている場合' do
      it '配列一要素あたりのレジスタ幅として、指定されたstepを返す' do
        registers = create_registers(enable_wide_register: true) do
          register do
            size [2, step: 8]
          end

          register do
            size [2, 3, step: 8]
          end

          register do
            size [2, step: 8]
            bit_field { bit_assignment lsb: 0 }
          end

          register do
            size [2, 3, step: 8]
            bit_field { bit_assignment lsb: 0 }
          end

          register do
            size [2, step: 16]
            bit_field { bit_assignment lsb: 32 }
          end

          register do
            size [2, 3, step: 16]
            bit_field { bit_assignment lsb: 32 }
          end
        end

        expect(registers[0]).to have_property(:entry_byte_size, 8)
        expect(registers[1]).to have_property(:entry_byte_size, 8)
        expect(registers[2]).to have_property(:entry_byte_size, 8)
        expect(registers[3]).to have_property(:entry_byte_size, 8)
        expect(registers[4]).to have_property(:entry_byte_size, 16)
        expect(registers[5]).to have_property(:entry_byte_size, 16)
      end
    end
  end

  describe '#total_byte_size' do
    let(:register_definitions) do
      proc do
        register do
        end

        register do
          size [2]
        end

        register do
          size [2, step: 8]
        end

        register do
          size [2, 3]
        end

        register do
          size [2, 3, step: 8]
        end

        register do
          bit_field { bit_assignment lsb: 0 }
        end

        register do
          size [2]
          bit_field { bit_assignment lsb: 0 }
        end

        register do
          size [2, step: 8]
          bit_field { bit_assignment lsb: 0 }
        end

        register do
          size [2, 3]
          bit_field { bit_assignment lsb: 0 }
        end

        register do
          size [2, 3, step: 8]
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
          size [2, step: 16]
          bit_field { bit_assignment lsb: 32 }
        end

        register do
          size [2, 3]
          bit_field { bit_assignment lsb: 32 }
        end

        register do
          size [2, 3, step: 16]
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
            size [2, step: 8]
            bit_field { bit_assignment lsb: 0 }
          end

          register do
            size [2, 3]
            bit_field { bit_assignment lsb: 0 }
          end

          register do
            size [2, 3, step: 8]
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
              size [2, step: 8]
              bit_field { bit_assignment lsb: 0 }
            end

            register do
              size [2, 3]
              bit_field { bit_assignment lsb: 0 }
            end

            register do
              size [2, 3, step: 8]
              bit_field { bit_assignment lsb: 0 }
            end
          end
        end
      end
    end

    context 'レジスタの属性にsupport_shared_addressの指定がない場合' do
      it '#entry_byte_sizeに#sizeを乗じた値を返す' do
        registers = create_registers(enable_wide_register: true, &register_definitions)

        expect(registers[0]).to have_property(:total_byte_size, 4)
        expect(registers[1]).to have_property(:total_byte_size, 2 * 4)
        expect(registers[2]).to have_property(:total_byte_size, 2 * 8)
        expect(registers[3]).to have_property(:total_byte_size, 2 * 3 * 4)
        expect(registers[4]).to have_property(:total_byte_size, 2 * 3 * 8)
        expect(registers[5]).to have_property(:total_byte_size, 4)
        expect(registers[6]).to have_property(:total_byte_size, 2 * 4)
        expect(registers[7]).to have_property(:total_byte_size, 2 * 8)
        expect(registers[8]).to have_property(:total_byte_size, 2 * 3 * 4)
        expect(registers[9]).to have_property(:total_byte_size, 2 * 3 * 8)
        expect(registers[10]).to have_property(:total_byte_size, 8)
        expect(registers[11]).to have_property(:total_byte_size, 2 * 8)
        expect(registers[12]).to have_property(:total_byte_size, 2 * 16)
        expect(registers[13]).to have_property(:total_byte_size, 2 * 3 * 8)
        expect(registers[14]).to have_property(:total_byte_size, 2 * 3 * 16)
        expect(registers[15]).to have_property(:total_byte_size, 4)
        expect(registers[16]).to have_property(:total_byte_size, 2 * 4)
        expect(registers[17]).to have_property(:total_byte_size, 2 * 8)
        expect(registers[18]).to have_property(:total_byte_size, 24)
        expect(registers[19]).to have_property(:total_byte_size, 48)
        expect(registers[20]).to have_property(:total_byte_size, 4)
        expect(registers[21]).to have_property(:total_byte_size, 2 * 4)
        expect(registers[22]).to have_property(:total_byte_size, 2 * 8)
        expect(registers[23]).to have_property(:total_byte_size, 2 * 3 * 4)
        expect(registers[24]).to have_property(:total_byte_size, 2 * 3 * 8)
      end
    end

    context 'レジスタの属性にsupport_shared_addressの指定がある場合' do
      it '#sizeによらず、#entry_byte_sizeを返す' do
        registers =
          create_registers(
            support_shared_address: true, enable_wide_register: true,
            &register_definitions
          )

        expect(registers[0]).to have_property(:total_byte_size, 4)
        expect(registers[1]).to have_property(:total_byte_size, 4)
        expect(registers[2]).to have_property(:total_byte_size, 8)
        expect(registers[3]).to have_property(:total_byte_size, 4)
        expect(registers[4]).to have_property(:total_byte_size, 8)
        expect(registers[5]).to have_property(:total_byte_size, 4)
        expect(registers[6]).to have_property(:total_byte_size, 4)
        expect(registers[7]).to have_property(:total_byte_size, 8)
        expect(registers[8]).to have_property(:total_byte_size, 4)
        expect(registers[9]).to have_property(:total_byte_size, 8)
        expect(registers[10]).to have_property(:total_byte_size, 8)
        expect(registers[11]).to have_property(:total_byte_size, 8)
        expect(registers[12]).to have_property(:total_byte_size, 16)
        expect(registers[13]).to have_property(:total_byte_size, 8)
        expect(registers[14]).to have_property(:total_byte_size, 16)
        expect(registers[15]).to have_property(:total_byte_size, 4)
        expect(registers[16]).to have_property(:total_byte_size, 4)
        expect(registers[17]).to have_property(:total_byte_size, 8)
        expect(registers[18]).to have_property(:total_byte_size, 4)
        expect(registers[19]).to have_property(:total_byte_size, 8)
        expect(registers[20]).to have_property(:total_byte_size, 4)
        expect(registers[21]).to have_property(:total_byte_size, 4)
        expect(registers[22]).to have_property(:total_byte_size, 8)
        expect(registers[23]).to have_property(:total_byte_size, 4)
        expect(registers[24]).to have_property(:total_byte_size, 8)
      end
    end

    context '引数hierarchicalにtrueが指定された場合' do
      it '上位階層の配列サイズを含めた総バイトサイズを返す' do
        value = [true, false].sample
        registers =
          create_registers(
            support_shared_address: value, enable_wide_register: true,
            &register_definitions
          )

        size = registers[0].total_byte_size
        expect(registers[0]).to have_property(:total_byte_size, { hierarchical: true }, size)

        size = registers[1].total_byte_size
        expect(registers[1]).to have_property(:total_byte_size, { hierarchical: true }, size)

        size = registers[2].total_byte_size
        expect(registers[2]).to have_property(:total_byte_size, { hierarchical: true }, size)

        size = registers[3].total_byte_size
        expect(registers[3]).to have_property(:total_byte_size, { hierarchical: true }, size)

        size = registers[4].total_byte_size
        expect(registers[4]).to have_property(:total_byte_size, { hierarchical: true }, size)

        size = registers[5].total_byte_size
        expect(registers[5]).to have_property(:total_byte_size, { hierarchical: true }, size)

        size = registers[6].total_byte_size
        expect(registers[6]).to have_property(:total_byte_size, { hierarchical: true }, size)

        size = registers[7].total_byte_size
        expect(registers[7]).to have_property(:total_byte_size, { hierarchical: true }, size)

        size = registers[8].total_byte_size
        expect(registers[8]).to have_property(:total_byte_size, { hierarchical: true }, size)

        size = registers[9].total_byte_size
        expect(registers[9]).to have_property(:total_byte_size, { hierarchical: true }, size)

        size = registers[10].total_byte_size
        expect(registers[10]).to have_property(:total_byte_size, { hierarchical: true }, size)

        size = registers[11].total_byte_size
        expect(registers[11]).to have_property(:total_byte_size, { hierarchical: true }, size)

        size = registers[12].total_byte_size
        expect(registers[12]).to have_property(:total_byte_size, { hierarchical: true }, size)

        size = registers[13].total_byte_size
        expect(registers[13]).to have_property(:total_byte_size, { hierarchical: true }, size)

        size = registers[14].total_byte_size
        expect(registers[14]).to have_property(:total_byte_size, { hierarchical: true }, size)

        size = registers[15].total_byte_size
        expect(registers[15]).to have_property(:total_byte_size, { hierarchical: true }, size)

        size = registers[16].total_byte_size
        expect(registers[16]).to have_property(:total_byte_size, { hierarchical: true }, size)

        size = registers[17].total_byte_size
        expect(registers[17]).to have_property(:total_byte_size, { hierarchical: true }, size)

        size = registers[18].total_byte_size
        expect(registers[18]).to have_property(:total_byte_size, { hierarchical: true }, size)

        size = registers[19].total_byte_size
        expect(registers[19]).to have_property(:total_byte_size, { hierarchical: true }, size)

        size = registers[20].total_byte_size
        expect(registers[20]).to have_property(:total_byte_size, { hierarchical: true }, 2 * 3 * size)

        size = registers[21].total_byte_size
        expect(registers[21]).to have_property(:total_byte_size, { hierarchical: true }, 2 * 3 * size)

        size = registers[22].total_byte_size
        expect(registers[22]).to have_property(:total_byte_size, { hierarchical: true }, 2 * 3 * size)

        size = registers[23].total_byte_size
        expect(registers[23]).to have_property(:total_byte_size, { hierarchical: true }, 2 * 3 * size)

        size = registers[24].total_byte_size
        expect(registers[24]).to have_property(:total_byte_size, { hierarchical: true }, 2 * 3 * size)
      end
    end
  end

  describe '#array?' do
    let(:register_definitions) do
      proc do
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
        registers = create_registers(support_array: true, &register_definitions)

        expect(registers[0]).to have_property(:array?, true)
        expect(registers[1]).to have_property(:array?, true)
        expect(registers[3]).to have_property(:array?, true)
        expect(registers[4]).to have_property(:array?, true)
        expect(registers[6]).to have_property(:array?, true)
        expect(registers[7]).to have_property(:array?, true)
      end
    end

    context 'レジスタが配列に対応していて、#sizeの設定がない場合' do
      it '偽を返す' do
        registers = create_registers(support_array: true, &register_definitions)

        expect(registers[2]).to have_property(:array?, false)
        expect(registers[5]).to have_property(:array?, false)
        expect(registers[8]).to have_property(:array?, false)
      end
    end

    context 'レジスタが配列に対応していない場合' do
      it '偽を返す' do
        registers = create_registers(support_array: false, &register_definitions)

        expect(registers[0]).to have_property(:array?, false)
        expect(registers[1]).to have_property(:array?, false)
        expect(registers[2]).to have_property(:array?, false)
        expect(registers[3]).to have_property(:array?, false)
        expect(registers[4]).to have_property(:array?, false)
        expect(registers[5]).to have_property(:array?, false)
        expect(registers[6]).to have_property(:array?, false)
        expect(registers[7]).to have_property(:array?, false)
        expect(registers[8]).to have_property(:array?, false)
      end
    end

    context '引数hierarchicalにtrueが指定されて' do
      context '上位に配列レジスタファイル階層がない場合' do
        it '引数未指定の場合と同じ結果を返す' do
          value = [true, false].sample
          registers = create_registers(support_array: value, &register_definitions)

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
          value = [true, false].sample
          registers = create_registers(support_array: value, &register_definitions)

          expect(registers[6]).to have_property(:array?, { hierarchical: true }, true)
          expect(registers[7]).to have_property(:array?, { hierarchical: true }, true)
          expect(registers[8]).to have_property(:array?, { hierarchical: true }, true)
        end
      end
    end
  end

  describe '#array_size' do
    let(:register_definitions) do
      proc do
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
        registers = create_registers(support_array: true, &register_definitions)

        expect(registers[0]).to have_property(:array_size, match([2]))
        expect(registers[1]).to have_property(:array_size, match([2, 3]))
        expect(registers[3]).to have_property(:array_size, match([2]))
        expect(registers[4]).to have_property(:array_size, match([2, 3]))
        expect(registers[6]).to have_property(:array_size, match([2]))
        expect(registers[7]).to have_property(:array_size, match([2, 3]))
      end
    end

    context 'レジスタが配列レジスタではない場合' do
      it 'nilを返す' do
        registers = create_registers(support_array: false, &register_definitions)

        expect(registers[0]).to have_property(:array_size, nil)
        expect(registers[1]).to have_property(:array_size, nil)
        expect(registers[3]).to have_property(:array_size, nil)
        expect(registers[4]).to have_property(:array_size, nil)
        expect(registers[6]).to have_property(:array_size, nil)
        expect(registers[7]).to have_property(:array_size, nil)

        registers = create_registers(support_array: true, &register_definitions)

        expect(registers[2]).to have_property(:array_size, nil)
        expect(registers[5]).to have_property(:array_size, nil)
        expect(registers[8]).to have_property(:array_size, nil)

      end
    end

    context '引数hierarchicalにtrueが指定され' do
      context '上位に配列レジスタファイル階層がない場合' do
        it '引数未指定の場合と同じ結果を返す' do
          value = [true, false].sample
          registers = create_registers(support_array: value, &register_definitions)

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
          value = [true, false].sample
          registers = create_registers(support_array: value, &register_definitions)

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
    let(:register_definitions) do
      proc do
        register {}
        register { size [2] }
        register { size [2] }
        register { size [2, 3] }
        register { size [2, 3] }
      end
    end

    context '無引数の場合' do
      it 'レジスタの総要素数を返す' do
        registers = create_registers(support_array: true, &register_definitions)

        expect(registers[0]).to have_property(:count, 1)
        expect(registers[1]).to have_property(:count, 2)
        expect(registers[3]).to have_property(:count, 6)

        registers = create_registers(support_array: false, &register_definitions)

        expect(registers[2]).to have_property(:count, 1)
        expect(registers[4]).to have_property(:count, 1)
      end
    end

    context '引数にfalseが与えられた場合' do
      it '1を返す' do
        value = [true, false].sample
        registers = create_registers(support_array: value, &register_definitions)

        expect(registers[0]).to have_property(:count, [false], 1)
        expect(registers[1]).to have_property(:count, [false], 1)
        expect(registers[2]).to have_property(:count, [false], 1)
        expect(registers[3]).to have_property(:count, [false], 1)
        expect(registers[4]).to have_property(:count, [false], 1)
      end
    end
  end

  specify '文字列も入力できる' do
    register = create_register { register { size '1' } }
    expect(register).to have_property(:size, match([1]))

    register = create_register { register { size '1, 2' } }
    expect(register).to have_property(:size, match([1, 2]))

    register = create_register { register { size '1, 2, 3' } }
    expect(register).to have_property(:size, match([1, 2, 3]))

    register = create_register { register { size '1, 2, 3: step: 8' } }
    expect(register).to have_property(:size, match([1, 2, 3]))
    expect(register).to have_property(:entry_byte_size, 8)
  end

  describe 'エラーチェック' do
    context '大きさの各要素が整数に変換できなかった場合' do
      it 'RegisterMapErrorを起こす' do
        [nil, true, false, '', 'foo', '0xef_gh', Object.new].each_with_index do |value, i|
          if [1, 2, 4, 5, 6].include?(i)
            expect {
              create_register { register { size value } }
            }.to raise_register_map_error "cannot convert #{value.inspect} into register size"
          end

          expect {
            create_register { register { size [value] } }
          }.to raise_register_map_error "cannot convert #{value.inspect} into register size"

          expect {
            create_register { register { size [value, step: 4] } }
          }.to raise_register_map_error "cannot convert #{value.inspect} into register size"

          expect {
            create_register { register { size [1, value] } }
          }.to raise_register_map_error "cannot convert #{value.inspect} into register size"

          expect {
            create_register { register { size [1, value, step: 4] } }
          }.to raise_register_map_error "cannot convert #{value.inspect} into register size"

          expect {
            create_register { register { size [1, 2, value] } }
          }.to raise_register_map_error "cannot convert #{value.inspect} into register size"

          expect {
            create_register { register { size [1, 2, value, step: 4] } }
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
            create_register { register { size [value, step: 4] } }
          }.to raise_register_map_error "non positive value(s) are not allowed for register size: [#{value}]"

          expect {
            create_register { register { size [1, value] } }
          }.to raise_register_map_error "non positive value(s) are not allowed for register size: [1, #{value}]"

          expect {
            create_register { register { size [1, value, step: 4] } }
          }.to raise_register_map_error "non positive value(s) are not allowed for register size: [1, #{value}]"

          expect {
            create_register { register { size [value, 1] } }
          }.to raise_register_map_error "non positive value(s) are not allowed for register size: [#{value}, 1]"

          expect {
            create_register { register { size [value, 1, step: 4] } }
          }.to raise_register_map_error "non positive value(s) are not allowed for register size: [#{value}, 1]"

          expect {
            create_register { register { size [value, value] } }
          }.to raise_register_map_error "non positive value(s) are not allowed for register size: [#{value}, #{value}]"

          expect {
            create_register { register { size [value, value, step: 4] } }
          }.to raise_register_map_error "non positive value(s) are not allowed for register size: [#{value}, #{value}]"

          expect {
            create_register { register { size [1, value, 2] } }
          }.to raise_register_map_error "non positive value(s) are not allowed for register size: [1, #{value}, 2]"

          expect {
            create_register { register { size [1, value, 2, step: 4] } }
          }.to raise_register_map_error "non positive value(s) are not allowed for register size: [1, #{value}, 2]"

          expect {
            create_register { register { size [1, 2, value] } }
          }.to raise_register_map_error "non positive value(s) are not allowed for register size: [1, 2, #{value}]"

          expect {
            create_register { register { size [1, 2, value, step: 4] } }
          }.to raise_register_map_error "non positive value(s) are not allowed for register size: [1, 2, #{value}]"

          expect {
            create_register { register { size [1, value, value] } }
          }.to raise_register_map_error "non positive value(s) are not allowed for register size: [1, #{value}, #{value}]"

          expect {
            create_register { register { size [1, value, value, step: 4] } }
          }.to raise_register_map_error "non positive value(s) are not allowed for register size: [1, #{value}, #{value}]"

          expect {
            create_register { register { size [value, 1, value] } }
          }.to raise_register_map_error "non positive value(s) are not allowed for register size: [#{value}, 1, #{value}]"

          expect {
            create_register { register { size [value, 1, value, step: 4] } }
          }.to raise_register_map_error "non positive value(s) are not allowed for register size: [#{value}, 1, #{value}]"

          expect {
            create_register { register { size [value, value, 1] } }
          }.to raise_register_map_error "non positive value(s) are not allowed for register size: [#{value}, #{value}, 1]"

          expect {
            create_register { register { size [value, value, 1, step: 4] } }
          }.to raise_register_map_error "non positive value(s) are not allowed for register size: [#{value}, #{value}, 1]"

          expect {
            create_register { register { size [value, value, value] } }
          }.to raise_register_map_error "non positive value(s) are not allowed for register size: [#{value}, #{value}, #{value}]"

          expect {
            create_register { register { size [value, value, value, step: 4] } }
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

        expect {
          create_register(enable_wide_register: false) do
            register { size [1, step: 8]; bit_field { bit_assignment lsb: 0 } }
          end
        }.not_to raise_error

        expect {
          create_register(enable_wide_register: false) do
            register { size [1, step: 12]; bit_field { bit_assignment lsb: 0 } }
          end
        }.to raise_register_map_error 'register width wider than 8 bytes is not allowed: 12 bytes'
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

        expect {
          create_register(enable_wide_register: true) do
            register { size [1, step: 12]; bit_field { bit_assignment lsb: 0 } }
          end
        }.not_to raise_error
      end
    end

    context '指定されたstepが整数に変換できなかった場合' do
      it 'RegisterMapErrorを起こす' do
        [nil, true, false, 'foo', '0xef_gh', Object.new].each do |value|
          expect {
            create_register do
              register { size [1, step: value]; bit_field { bit_assignment lsb: 0 } }
            end
          }.to raise_register_map_error "cannot convert #{value.inspect} into step size"
        end
      end
    end

    context '配列未対応なレジスタに対してstepが指定された場合' do
      it 'RegisterMapErrorを起こす' do
        expect {
          create_register(support_array: false) do
            register { size [1, step: 4]; bit_field { bit_assignment lsb: 0 } }
          end
        }.to raise_register_map_error 'step size cannot be specified for non-array register'
      end
    end

    context '指定されたstepがレジスタ幅未満の場合' do
      it 'RegisterMapErrorを起こす' do
        [7, 4, 3, 2, 1, 0, -1].each do |step|
          expect {
            create_register do
              register { size [1, step: step]; bit_field { bit_assignment lsb: 32 } }
            end
          }.to raise_register_map_error "step size is less than register width: #{step}"
        end
      end
    end

    context '指定されたstepがバス幅の倍数になっていない場合' do
      it 'RegisterMapErrorを起こす' do
        [5, 6, 7, 9, 10, 11].each do |step|
          expect {
            create_register do
              register { size [1, step: step]; bit_field { bit_assignment lsb: 0 } }
            end
          }.to raise_register_map_error "step size is not multiple of bus width: #{step}"
        end
      end
    end
  end
end
