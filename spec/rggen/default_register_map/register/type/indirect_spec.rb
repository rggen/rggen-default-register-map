# frozen_string_literal: true

RSpec.describe 'register/type/indirect' do
  include_context 'clean-up builder'
  include_context 'register map common'

  before(:all) do
    RgGen.enable(:global, [:bus_width, :address_width, :enable_wide_register, :array_port_format])
    RgGen.enable(:register_block, [:byte_size])
    RgGen.enable(:register_file, [:name, :offset_address, :size])
    RgGen.enable(:register, [:name, :offset_address, :size, :type])
    RgGen.enable(:register, :type, [:indirect])
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

  specify 'レジスタ型は:indirect' do
    registers = create_registers do
      register do
        name :foo
        offset_address 0x0
        type [:indirect, ['bar.bar_0', 0]]
        bit_field { name :foo_0; bit_assignment lsb: 0; type :rw; initial_value 0 }
      end
      register do
        name :bar
        offset_address 0x04
        bit_field { name :bar_0; bit_assignment lsb: 0; type :rw; initial_value 0 }
      end
    end
    expect(registers.first).to have_property(:type, :indirect)
  end

  specify '#sizeに依らず、#byte_sizeは#byte_widthを示す' do
    registers = create_registers do
      register do
        name :foo
        offset_address 0x0
        type [:indirect, ['baz.baz_0', 0]]
        bit_field { name :foo_0; bit_assignment lsb: 0; type :rw; initial_value 0 }
      end
      register do
        name :bar
        offset_address 0x0
        type [:indirect, ['baz.baz_0', 1]]
        bit_field { name :bar_0; bit_assignment lsb: 0; type :rw; initial_value 0 }
      end
      register do
        name :baz
        offset_address 0x4
        bit_field { name :baz_0; bit_assignment lsb: 0; type :rw; initial_value 0 }
      end
    end
    expect(registers[0]).to have_property(:byte_size, 4)
    expect(registers[1]).to have_property(:byte_size, 4)

    registers = create_registers do
      register do
        name :foo
        offset_address 0x0
        size 2
        type [:indirect, 'baz.baz_0', ['baz.baz_1', 0]]
        bit_field { name :foo_0; bit_assignment lsb: 0; type :rw; initial_value 0 }
      end
      register do
        name :bar
        offset_address 0x0
        size 2
        type [:indirect, 'baz.baz_0', ['baz.baz_1', 1]]
        bit_field { name :bar_0; bit_assignment lsb: 0; type :rw; initial_value 0 }
      end
      register do
        name :baz
        offset_address 0x4
        bit_field { name :baz_0; bit_assignment lsb: 0, width: 2; type :rw; initial_value 0 }
        bit_field { name :baz_1; bit_assignment lsb: 2, width: 1; type :rw; initial_value 0 }
      end
    end
    expect(registers[0]).to have_property(:byte_size, 4)
    expect(registers[1]).to have_property(:byte_size, 4)

    registers = create_registers do
      register do
        name :foo
        offset_address 0x0
        size [2, 3]
        type [:indirect, 'baz.baz_0', 'baz.baz_1', ['baz.baz_2', 0]]
        bit_field { name :foo_0; bit_assignment lsb: 0; type :rw; initial_value 0 }
      end
      register do
        name :bar
        offset_address 0x0
        size [3, 4]
        type [:indirect, 'baz.baz_0', 'baz.baz_1', ['baz.baz_2', 1]]
        bit_field { name :bar_0; bit_assignment lsb: 0; type :rw; initial_value 0 }
      end
      register do
        name :baz
        offset_address 0x4
        bit_field { name :baz_0; bit_assignment lsb: 0, width: 2; type :rw; initial_value 0 }
        bit_field { name :baz_1; bit_assignment lsb: 2, width: 3; type :rw; initial_value 0 }
        bit_field { name :baz_2; bit_assignment lsb: 5, width: 1; type :rw; initial_value 0 }
      end
    end
    expect(registers[0]).to have_property(:byte_size, 4)
    expect(registers[1]).to have_property(:byte_size, 4)
  end

  describe '#index_entries' do
    it 'オプショで指定されたインデックス一覧を返す' do
      registers = create_registers do
        register do
          name :foo
          offset_address 0x0
          type [:indirect, ['fizz.fizz_2', 0]]
          bit_field { name :foo_0; bit_assignment lsb: 0; type :rw; initial_value 0 }
        end
        register do
          name :bar
          offset_address 0x00
          size [2]
          type [:indirect, 'fizz.fizz_1', ['fizz.fizz_2', 1]]
          bit_field { name :bar_0; bit_assignment lsb: 0; type :rw; initial_value 0 }
        end
        register do
          name :baz
          offset_address 0x00
          size [2, 3]
          type [:indirect, 'fizz.fizz_0', 'fizz.fizz_1', ['fizz.fizz_2', 2]]
          bit_field { name :baz_0; bit_assignment lsb: 0; type :rw; initial_value 0 }
        end
        register do
          name :qux
          offset_address 0x04
          size [2]
          type [:indirect, 'buzz.buzz_0.buzz_0', ['buzz.buzz_1.buzz_1.buzz_1', 0], ['fizz_buzz', 1]]
          bit_field { name :qux_0; bit_assignment lsb: 0; type :rw; initial_value 0 }
        end
        register do
          name :fizz
          offset_address 0x20
          bit_field { name :fizz_0; bit_assignment lsb: 0, width: 2; type :rw; initial_value 0 }
          bit_field { name :fizz_1; bit_assignment lsb: 2, width: 2; type :rw; initial_value 0 }
          bit_field { name :fizz_2; bit_assignment lsb: 4, width: 2; type :rw; initial_value 0 }
        end
        register_file do
          name :buzz
          offset_address 0x30
          register do
            name :buzz_0
            offset_address 0x00
            bit_field { name :buzz_0; bit_assignment lsb: 0, with: 2; type :rw; initial_value 0 }
          end
          register_file do
            name :buzz_1
            offset_address 0x04
            register do
              name :buzz_1
              offset_address 0x00
              bit_field { name :buzz_1; bit_assignment lsb: 0, with: 2; type :rw; initial_value 0 }
            end
          end
        end
        register do
          name :fizz_buzz
          offset_address 0x40
          bit_field { bit_assignment lsb: 0, with: 2; type :rw; initial_value 0 }
        end
      end

      expect(registers[0].index_entries.map(&:to_h)).to match([
        { name: 'fizz.fizz_2', value: 0 }
      ])
      expect(registers[1].index_entries.map(&:to_h)).to match([
        { name: 'fizz.fizz_1', value: nil },
        { name: 'fizz.fizz_2', value: 1 }
      ])
      expect(registers[2].index_entries.map(&:to_h)).to match([
        { name: 'fizz.fizz_0', value: nil },
        { name: 'fizz.fizz_1', value: nil },
        { name: 'fizz.fizz_2', value: 2 }
      ])
      expect(registers[3].index_entries.map(&:to_h)).to match([
        { name: 'buzz.buzz_0.buzz_0', value: nil },
        { name: 'buzz.buzz_1.buzz_1.buzz_1', value: 0 },
        { name: 'fizz_buzz', value: 1 }
      ])
    end

    specify '文字列でインデックスを指定することができる' do
      registers = create_registers do
        register do
          name :foo_0
          offset_address 0x0
          type 'indirect: fizz.fizz_2:0'
          bit_field { name :foo_0; bit_assignment lsb: 0; type :rw; initial_value 0 }
        end
        register do
          name :foo_1
          offset_address 0x0
          size [2]
          type 'indirect: fizz.fizz_1, fizz.fizz_2:1'
          bit_field { name :foo_1; bit_assignment lsb: 0; type :rw; initial_value 0 }
        end
        register do
          name :foo_2
          offset_address 0x0
          size [2, 3]
          type 'indirect: fizz.fizz_0, fizz.fizz_1, fizz.fizz_2: 2'
          bit_field { name :foo_2; bit_assignment lsb: 0; type :rw; initial_value 0 }
        end
        register do
          name :bar_0
          offset_address 0x4
          type 'indirect: buzz.buzz.buzz_2:0'
          bit_field { name :bar_0; bit_assignment lsb: 0; type :rw; initial_value 0 }
        end
        register do
          name :bar_1
          offset_address 0x4
          size [2]
          type 'indirect: buzz.buzz.buzz_1, buzz.buzz.buzz_2:1'
          bit_field { name :bar_1; bit_assignment lsb: 0; type :rw; initial_value 0 }
        end
        register do
          name :bar_2
          offset_address 0x4
          size [2, 3]
          type 'indirect: buzz.buzz.buzz_0, buzz.buzz.buzz_1, buzz.buzz.buzz_2: 2'
          bit_field { name :bar_2; bit_assignment lsb: 0; type :rw; initial_value 0 }
        end
        register do
          name :fizz
          offset_address 0x10
          bit_field { name :fizz_0; bit_assignment lsb: 0, width: 2; type :rw; initial_value 0 }
          bit_field { name :fizz_1; bit_assignment lsb: 2, width: 2; type :rw; initial_value 0 }
          bit_field { name :fizz_2; bit_assignment lsb: 4, width: 2; type :rw; initial_value 0 }
        end
        register_file do
          name :buzz
          offset_address 0x14
          register do
            name :buzz
            bit_field { name :buzz_0; bit_assignment lsb: 0, width: 2; type :rw; initial_value 0 }
            bit_field { name :buzz_1; bit_assignment lsb: 2, width: 2; type :rw; initial_value 0 }
            bit_field { name :buzz_2; bit_assignment lsb: 4, width: 2; type :rw; initial_value 0 }
          end
        end
      end

      expect(registers[0].index_entries.map(&:to_h)).to match([
        { name: 'fizz.fizz_2', value: 0 }
      ])
      expect(registers[1].index_entries.map(&:to_h)).to match([
        { name: 'fizz.fizz_1', value: nil },
        { name: 'fizz.fizz_2', value: 1 }
      ])
      expect(registers[2].index_entries.map(&:to_h)).to match([
        { name: 'fizz.fizz_0', value: nil },
        { name: 'fizz.fizz_1', value: nil },
        { name: 'fizz.fizz_2', value: 2 }
      ])
      expect(registers[3].index_entries.map(&:to_h)).to match([
        { name: 'buzz.buzz.buzz_2', value: 0 }
      ])
      expect(registers[4].index_entries.map(&:to_h)).to match([
        { name: 'buzz.buzz.buzz_1', value: nil },
        { name: 'buzz.buzz.buzz_2', value: 1 }
      ])
      expect(registers[5].index_entries.map(&:to_h)).to match([
        { name: 'buzz.buzz.buzz_0', value: nil },
        { name: 'buzz.buzz.buzz_1', value: nil },
        { name: 'buzz.buzz.buzz_2', value: 2 }
      ])
    end
  end

  describe '#printables[:index_bit_fields]' do
    it '表示可能オブジェクトとして、インデックスビットフィールドの一覧を返す' do
      registers = create_registers do
        register do
          name :foo
          offset_address 0x0
          type [:indirect, ['fizz.fizz_2', 0]]
          bit_field { name :foo_0; bit_assignment lsb: 0; type :rw; initial_value 0 }
        end
        register do
          name :bar
          offset_address 0x00
          size [2]
          type [:indirect, 'fizz.fizz_1', ['fizz.fizz_2', 1]]
          bit_field { name :bar_0; bit_assignment lsb: 0; type :rw; initial_value 0 }
        end
        register do
          name :baz
          offset_address 0x00
          size [2, 3]
          type [:indirect, 'fizz.fizz_0', 'fizz.fizz_1', ['fizz.fizz_2', 2]]
          bit_field { name :baz_0; bit_assignment lsb: 0; type :rw; initial_value 0 }
        end
        register do
          name :fizz
          offset_address 0x08
          bit_field { name :fizz_0; bit_assignment lsb: 0, width: 2; type :rw; initial_value 0 }
          bit_field { name :fizz_1; bit_assignment lsb: 2, width: 2; type :rw; initial_value 0 }
          bit_field { name :fizz_2; bit_assignment lsb: 4, width: 2; type :rw; initial_value 0 }
        end
      end

      expect(registers[0].printables[:index_bit_fields]).to match_array(['fizz.fizz_2: 0'])
      expect(registers[1].printables[:index_bit_fields]).to match_array(['fizz.fizz_1', 'fizz.fizz_2: 1'])
      expect(registers[2].printables[:index_bit_fields]).to match_array(['fizz.fizz_0', 'fizz.fizz_1', 'fizz.fizz_2: 2'])
    end
  end

  describe 'エラーチェック' do
    context 'インデックスの指定がない場合' do
      it 'RegisterMapErrorを起こす' do
        expect {
          create_registers do
            register do
              name :foo
              offset_address 0x0
              type :indirect
            end
          end
        }.to raise_register_map_error 'no indirect indices are given'
      end
    end

    context 'インデックス名が文字列、または、シンボルではない場合' do
      it 'RegisterMapErrorを起こす' do
        [nil, true, false, Object.new, []].each do |value|
          expect {
            create_registers do
              register do
                name :foo
                offset_address 0x0
                type [:indirect, value]
              end
            end
          }.to raise_register_map_error "illegal input value for indirect index: #{value.inspect}"
        end
      end
    end

    context 'フィールド名が入力パターンに一致しない場合' do
      it 'RegisterMapErrorを起こす' do
        ['0foo.foo', 'foo.0foo', 'foo.foo.0', 'foo.foo:0xef_gh', '0foo', 'foo:0xef_gh'].each do |value|
          expect {
            create_registers do
              register do
                name :foo
                offset_address 0x0
                type [:indirect, value]
              end
            end
          }.to raise_register_map_error "illegal input value for indirect index: #{value.inspect}"
        end
      end
    end

    context 'インデックス値が整数に変換できない場合' do
      it 'RegisterMapErrorを起こす' do
        [nil, true, false, '', '0xef_gh', Object.new].each do |value|
          expect {
            create_registers do
              register do
                name :foo
                offset_address 0x0
                type [:indirect, ['bar.bar_0', value]]
              end
            end
          }.to raise_register_map_error "cannot convert #{value.inspect} into indirect index value"
        end
      end
    end

    context 'インデックス指定の引数が多すぎる場合' do
      it 'RegisterMapErrorを起こす' do
        value = ['bar.bar_0', 1, nil]
        expect {
          create_registers do
            register do
              name :foo
              offset_address 0x0
              type [:indirect, value]
            end
          end
        }.to raise_register_map_error "too many arguments for indirect index are given: #{value}"

        value = ['bar.bar_0:0', 1]
        expect {
          create_registers do
            register do
              name :foo
              offset_address 0x0
              type [:indirect, value]
            end
          end
        }.to raise_register_map_error "too many arguments for indirect index are given: #{value}"

        value = ['bar.bar_0:0', nil]
        expect {
          create_registers do
            register do
              name :foo
              offset_address 0x0
              type [:indirect, value]
            end
          end
        }.to raise_register_map_error "too many arguments for indirect index are given: #{value}"
      end
    end

    context '同じビットフィールドが複数回使用された場合' do
      it 'RegisterMapErrorを起こす' do
        expect {
          create_registers do
            register do
              name :foo
              offset_address 0x0
              type [:indirect, ['bar.bar_0', 0], ['bar.bar_0', 1]]
              bit_field { name :foo_0; bit_assignment lsb: 0; type :rw; initial_value 0 }
            end
            register do
              name :bar
              offset_address 0x04
              bit_field { name :bar_0; bit_assignment lsb: 0; type :rw; initial_value 0 }
            end
          end
        }.to raise_register_map_error 'same bit field is used as indirect index more than once: bar.bar_0'
      end
    end

    context 'インデックス用のビットフィールドが存在しない場合' do
      it 'RegisterMapErrorを起こす' do
        expect {
          create_registers do
            register do
              name :foo
              offset_address 0x0
              type [:indirect, ['bar.bar_1', 0]]
              bit_field { name :foo_0; bit_assignment lsb: 0; type :rw; initial_value 0 }
            end
            register do
              name :bar
              offset_address 0x04
              bit_field { name :bar_0; bit_assignment lsb: 0; type :rw; initial_value 0 }
            end
          end
        }.to raise_register_map_error 'no such bit field for indirect index is found: bar.bar_1'

        expect {
          create_registers do
            register do
              name :foo
              offset_address 0x0
              type [:indirect, ['baz.bar_0', 0]]
              bit_field { name :foo_0; bit_assignment lsb: 0; type :rw; initial_value 0 }
            end
            register do
              name :bar
              offset_address 0x04
              bit_field { name :bar_0; bit_assignment lsb: 0; type :rw; initial_value 0 }
            end
          end
        }.to raise_register_map_error 'no such bit field for indirect index is found: baz.bar_0'

        expect {
          create_registers do
            register do
              name :foo
              offset_address 0x0
              type [:indirect, ['baz.bar.bar_0', 0]]
              bit_field { name :foo_0; bit_assignment lsb: 0; type :rw; initial_value 0 }
            end
            register_file do
              name :bar
              offset_address 0x4
              register do
                name :bar
                offset_address 0x0
                bit_field { name :bar_0; bit_assignment lsb: 0; type :rw; initial_value 0 }
              end
            end
          end
        }.to raise_register_map_error 'no such bit field for indirect index is found: baz.bar.bar_0'

        expect {
          create_registers do
            register do
              name :foo
              offset_address 0x0
              type [:indirect, ['bar.baz.bar_0', 0]]
              bit_field { name :foo_0; bit_assignment lsb: 0; type :rw; initial_value 0 }
            end
            register_file do
              name :bar
              offset_address 0x4
              register do
                name :bar
                offset_address 0x0
                bit_field { name :bar_0; bit_assignment lsb: 0; type :rw; initial_value 0 }
              end
            end
          end
        }.to raise_register_map_error 'no such bit field for indirect index is found: bar.baz.bar_0'

        expect {
          create_registers do
            register do
              name :foo
              offset_address 0x0
              type [:indirect, ['bar.bar.baz_0', 0]]
              bit_field { name :foo_0; bit_assignment lsb: 0; type :rw; initial_value 0 }
            end
            register_file do
              name :bar
              offset_address 0x4
              register do
                name :bar
                offset_address 0x0
                bit_field { name :bar_0; bit_assignment lsb: 0; type :rw; initial_value 0 }
              end
            end
          end
        }.to raise_register_map_error 'no such bit field for indirect index is found: bar.bar.baz_0'
      end
    end

    context 'インデックスビットフィールドが自身のビットフィールドの場合' do
      it 'RegisterMapErrorを起こす' do
        expect {
          create_registers do
            register do
              name :foo
              offset_address 0x0
              type [:indirect, ['foo.foo_1', 0]]
              bit_field { name :foo_0; bit_assignment lsb: 0; type :rw; initial_value 0 }
              bit_field { name :foo_1; bit_assignment lsb: 1; type :rw; initial_value 0 }
            end
          end
        }.to raise_register_map_error 'own bit field is not allowed for indirect index: foo.foo_1'

        expect {
          create_registers do
            register_file do
              name :foo
              offset_address 0x0
              register do
                name :foo
                offset_address 0x0
                type [:indirect, ['foo.foo.foo_1', 0]]
                bit_field { name :foo_0; bit_assignment lsb: 0; type :rw; initial_value 0 }
                bit_field { name :foo_1; bit_assignment lsb: 1; type :rw; initial_value 0 }
              end
            end
          end
        }.to raise_register_map_error 'own bit field is not allowed for indirect index: foo.foo.foo_1'

        expect {
          create_registers do
            register_file do
              name :foo
              offset_address 0x0
              register do
                name :bar
                offset_address 0x0
                type [:indirect, ['bar.baz', 0]]
                bit_field { name :baz; bit_assignment lsb: 0; type :rw; initial_value 0 }
              end
            end

            register do
              name :bar
              offset_address 0x4
              bit_field { name :baz; bit_assignment lsb: 0; type :rw; initial_value 0 }
            end
          end
        }.not_to raise_error
      end
    end

    context 'インデックスフィードが配列レジスタファイルに属している場合' do
      it 'RegisterMapErrorを起こす' do
        expect {
          create_registers do
            register do
              name :foo
              type [:indirect, ['bar.bar.bar_0', 0]]
              bit_field { name :foo; bit_assignment lsb: 0; type :rw; initial_value 0 }
            end
            register_file do
              name :bar
              offset_address 0x4
              size [2]
              register do
                name :bar
                offset_address 0x0
                bit_field { name :bar_0; bit_assignment lsb: 0; type :rw; initial_value 0 }
              end
            end
          end
        }.to raise_register_map_error 'bit field within array register file is not allowed for indirect index: bar.bar.bar_0'

        expect {
          create_registers do
            register do
              name :foo
              type [:indirect, ['bar.bar.bar.bar_0', 0]]
              bit_field { name :foo; bit_assignment lsb: 0; type :rw; initial_value 0 }
            end
            register_file do
              name :bar
              offset_address 0x4
              size [2]
              register_file do
                name :bar
                offset_address 0x0
                register do
                  name :bar
                  offset_address 0x0
                  bit_field { name :bar_0; bit_assignment lsb: 0; type :rw; initial_value 0 }
                end
              end
            end
          end
        }.to raise_register_map_error 'bit field within array register file is not allowed for indirect index: bar.bar.bar.bar_0'

        expect {
          create_registers do
            register do
              name :foo
              type [:indirect, ['bar.bar.bar.bar_0', 0]]
              bit_field { name :foo; bit_assignment lsb: 0; type :rw; initial_value 0 }
            end
            register_file do
              name :bar
              offset_address 0x4
              register_file do
                name :bar
                offset_address 0x0
                size [2]
                register do
                  name :bar
                  offset_address 0x0
                  bit_field { name :bar_0; bit_assignment lsb: 0; type :rw; initial_value 0 }
                end
              end
            end
          end
        }.to raise_register_map_error 'bit field within array register file is not allowed for indirect index: bar.bar.bar.bar_0'
      end
    end

    context 'インデックスビットフィールドが配列レジスタに属している場合' do
      it 'RegisterMapErrorを起こす' do
        expect {
          create_registers do
            register do
              name :foo
              offset_address 0x0
              type [:indirect, ['bar.bar_0', 0]]
              bit_field { name :foo_0; bit_assignment lsb: 0; type :rw; initial_value 0 }
            end
            register do
              name :bar
              offset_address 0x4
              size [2]
              bit_field { name :bar_0; bit_assignment lsb: 0; type :rw; initial_value 0 }
            end
          end
        }.to raise_register_map_error 'bit field within array register is not allowed for indirect index: bar.bar_0'

        expect {
          create_registers do
            register do
              name :foo
              offset_address 0x0
              type [:indirect, ['bar.bar.bar_0', 0]]
              bit_field { name :foo_0; bit_assignment lsb: 0; type :rw; initial_value 0 }
            end
            register_file do
              name :bar
              offset_address 0x4
              register do
                name :bar
                offset_address 0x0
                size [2]
                bit_field { name :bar_0; bit_assignment lsb: 0; type :rw; initial_value 0 }
              end
            end
          end
        }.to raise_register_map_error 'bit field within array register is not allowed for indirect index: bar.bar.bar_0'
      end
    end

    context 'インデックスビットフィールドが連番ビットフィールドの場合' do
      it 'RegisterMapErrorを起こす' do
        expect {
          create_registers do
            register do
              name :foo
              offset_address 0x0
              type [:indirect, ['bar.bar_0', 0]]
              bit_field { name :foo_0; bit_assignment lsb: 0; type :rw; initial_value 0 }
            end
            register do
              name :bar
              offset_address 0x4
              bit_field { name :bar_0; bit_assignment lsb: 0, sequence_size: 1; type :rw; initial_value 0 }
            end
          end
        }.to raise_register_map_error 'sequential bit field is not allowed for indirect index: bar.bar_0'
      end
    end

    context 'インデックスビットフィールドの属性が予約済みの場合' do
      it 'RegisterMapErrorを起こす' do
        expect {
          create_registers do
            register do
              name :foo
              offset_address 0x0
              type [:indirect, ['bar.bar_0', 0]]
              bit_field { name :foo_0; bit_assignment lsb: 0; type :rw; initial_value 0 }
            end
            register do
              name :bar
              offset_address 0x4
              bit_field { name :bar_0; bit_assignment lsb: 0; type :reserved }
            end
          end
        }.to raise_register_map_error 'reserved bit field is not allowed for indirect index: bar.bar_0'
      end
    end

    context 'インデックス値がインデックスビットフィールドの幅より大きい場合' do
      it 'RegisterMapErrorを起こす' do
        expect {
          create_registers do
            register do
              name :foo
              offset_address 0x0
              type [:indirect, ['bar.bar_0', 2]]
              bit_field { name :foo_0; bit_assignment lsb: 0; type :rw; initial_value 0 }
            end
            register do
              name :bar
              offset_address 0x4
              bit_field { name :bar_0; bit_assignment lsb: 0; type :rw; initial_value 0 }
            end
          end
        }.to raise_register_map_error 'bit width of indirect index is not enough for index value 2: bar.bar_0'
      end
    end

    context '非配列レジスタに配列インデックスが指定された場合' do
      it 'RegisterMapErrorを起こす' do
        expect {
          create_registers do
            register do
              name :foo
              offset_address 0x00
              type [:indirect, 'bar.bar_0', ['bar.bar_1', 0]]
              bit_field { name :foo_0; bit_assignment lsb: 0; type :rw; initial_value 0 }
            end
            register do
              name :bar
              offset_address 0x4
              bit_field { name :bar_0; bit_assignment lsb: 0; type :rw; initial_value 0 }
              bit_field { name :bar_1; bit_assignment lsb: 1; type :rw; initial_value 0 }
            end
          end
        }.to raise_register_map_error 'array indices are given to non-array register'
      end
    end

    context '配列インデックスに過不足がある場合' do
      it 'RegisterMapErrorを起こす' do
        expect {
          create_registers do
            register do
              name :foo
              offset_address 0x0
              size [1]
              type [:indirect, 'bar.bar_0', 'bar.bar_1', ['bar.bar_2', 0]]
              bit_field { name :foo_0; bit_assignment lsb: 0; type :rw; initial_value 0 }
            end
            register do
              name :bar
              offset_address 0x4
              bit_field { name :bar_0; bit_assignment lsb: 0; type :rw; initial_value 0 }
              bit_field { name :bar_1; bit_assignment lsb: 1; type :rw; initial_value 0 }
              bit_field { name :bar_2; bit_assignment lsb: 2; type :rw; initial_value 0 }
            end
          end
        }.to raise_register_map_error 'too many array indices are given'

        expect {
          create_registers do
            register do
              name :foo
              offset_address 0x0
              size [1, 2, 3]
              type [:indirect, 'bar.bar_0', 'bar.bar_1', ['bar.bar_2', 0]]
              bit_field { name :foo_0; bit_assignment lsb: 0; type :rw; initial_value 0 }
            end
            register do
              name :bar
              offset_address 0x4
              bit_field { name :bar_0; bit_assignment lsb: 0; type :rw; initial_value 0 }
              bit_field { name :bar_1; bit_assignment lsb: 1; type :rw; initial_value 0 }
              bit_field { name :bar_2; bit_assignment lsb: 2; type :rw; initial_value 0 }
            end
          end
        }.to raise_register_map_error 'few array indices are given'
      end
    end

    context '配列の大きさがインデックスビットフィールドの幅より大きい場合' do
      it 'RegisterMapErrorを起こす' do
        expect {
          create_registers do
            register do
              name :foo
              offset_address 0x0
              size 3
              type [:indirect, 'bar.bar_0']
              bit_field { name :foo_0; bit_assignment lsb: 0; type :rw; initial_value 0 }
            end
            register do
              name :bar
              offset_address 0x4
              bit_field { name :bar_0; bit_assignment lsb: 0; type :rw; initial_value 0 }
            end
          end
        }.to raise_register_map_error 'bit width of indirect index is not enough for array size 3: bar.bar_0'

        expect {
          create_registers do
            register do
              name :foo
              offset_address 0x0
              size [2, 3]
              type [:indirect, 'bar.bar_0', 'bar.bar_1']
              bit_field { name :foo_0; bit_assignment lsb: 0; type :rw; initial_value 0 }
            end
            register do
              name :bar
              offset_address 0x4
              bit_field { name :bar_0; bit_assignment lsb: 0; type :rw; initial_value 0 }
              bit_field { name :bar_1; bit_assignment lsb: 1; type :rw; initial_value 0 }
            end
          end
        }.to raise_register_map_error 'bit width of indirect index is not enough for array size 3: bar.bar_1'
      end
    end

    describe 'インデックスの区別' do
      context 'インデックスが他のレジスタと区別できる場合' do
        it 'エラーを起こさない' do
          expect {
            create_registers do
              register do
                name :foo
                offset_address 0x0
                type [:indirect, ['baz.baz_0', 0]]
                bit_field { name :foo_0; bit_assignment lsb: 0; type :rw; initial_value 0 }
              end
              register do
                name :bar
                offset_address 0x0
                type [:indirect, ['baz.baz_0', 1]]
                bit_field { name :bar_0; bit_assignment lsb: 0; type :rw; initial_value 0 }
              end
              register do
                name :baz
                offset_address 0x4
                bit_field { name :baz_0; bit_assignment lsb: 0, width: 4; type :rw; initial_value 0 }
                bit_field { name :baz_1; bit_assignment lsb: 4, width: 4; type :rw; initial_value 0 }
                bit_field { name :baz_2; bit_assignment lsb: 8, width: 4; type :rw; initial_value 0 }
              end
            end
          }.not_to raise_error

          expect {
            create_registers do
              register do
                name :foo
                offset_address 0x0
                type [:indirect, ['baz.baz_0', 0]]
                bit_field { name :foo_0; bit_assignment lsb: 0; type :ro }
              end
              register do
                name :bar
                offset_address 0x0
                type [:indirect, ['baz.baz_0', 0]]
                bit_field { name :bar_0; bit_assignment lsb: 0; type :wo; initial_value 0 }
              end
              register do
                name :baz
                offset_address 0x4
                bit_field { name :baz_0; bit_assignment lsb: 0, width: 4; type :rw; initial_value 0 }
                bit_field { name :baz_1; bit_assignment lsb: 4, width: 4; type :rw; initial_value 0 }
                bit_field { name :baz_2; bit_assignment lsb: 8, width: 4; type :rw; initial_value 0 }
              end
            end
          }.not_to raise_error

          expect {
            create_registers do
              register do
                name :foo
                offset_address 0x0
                size [2]
                type [:indirect, 'baz.baz_0', ['baz.baz_2', 0]]
                bit_field { name :foo_0; bit_assignment lsb: 0; type :rw; initial_value 0 }
              end
              register do
                name :bar
                offset_address 0x0
                size [2]
                type [:indirect, 'baz.baz_0', ['baz.baz_2', 1]]
                bit_field { name :bar_0; bit_assignment lsb: 0; type :rw; initial_value 0 }
              end
              register do
                name :baz
                offset_address 0x4
                bit_field { name :baz_0; bit_assignment lsb: 0, width: 4; type :rw; initial_value 0 }
                bit_field { name :baz_1; bit_assignment lsb: 4, width: 4; type :rw; initial_value 0 }
                bit_field { name :baz_2; bit_assignment lsb: 8, width: 4; type :rw; initial_value 0 }
              end
            end
          }.not_to raise_error

          expect {
            create_registers do
              register do
                name :foo
                offset_address 0x0
                size [2]
                type [:indirect, 'baz.baz_0', ['baz.baz_2', 0]]
                bit_field { name :foo_0; bit_assignment lsb: 0; type :rw; initial_value 0 }
              end
              register do
                name :bar
                offset_address 0x0
                size [2, 2]
                type [:indirect, 'baz.baz_0', 'baz.baz_1', ['baz.baz_2', 1]]
                bit_field { name :bar_0; bit_assignment lsb: 0; type :rw; initial_value 0 }
              end
              register do
                name :baz
                offset_address 0x4
                bit_field { name :baz_0; bit_assignment lsb: 0, width: 4; type :rw; initial_value 0 }
                bit_field { name :baz_1; bit_assignment lsb: 4, width: 4; type :rw; initial_value 0 }
                bit_field { name :baz_2; bit_assignment lsb: 8, width: 4; type :rw; initial_value 0 }
              end
            end
          }.not_to raise_error

          expect {
            create_registers do
              register do
                name :foo
                offset_address 0x0
                size [2, 2]
                type [:indirect, 'baz.baz_0', 'baz.baz_1', ['baz.baz_2', 0]]
                bit_field { name :foo_0; bit_assignment lsb: 0; type :rw; initial_value 0 }
              end
              register do
                name :bar
                offset_address 0x0
                size [2, 2]
                type [:indirect, 'baz.baz_0', 'baz.baz_1', ['baz.baz_2', 1]]
                bit_field { name :bar_0; bit_assignment lsb: 0; type :rw; initial_value 0 }
              end
              register do
                name :baz
                offset_address 0x4
                bit_field { name :baz_0; bit_assignment lsb: 0, width: 4; type :rw; initial_value 0 }
                bit_field { name :baz_1; bit_assignment lsb: 4, width: 4; type :rw; initial_value 0 }
                bit_field { name :baz_2; bit_assignment lsb: 8, width: 4; type :rw; initial_value 0 }
              end
            end
          }.not_to raise_error
        end
      end

      context 'インデックスが他のレジスタと区別できない場合' do
        it 'RegisterMapErrorを起こす' do
          expect {
            create_registers do
              register do
                name :foo
                offset_address 0x0
                type [:indirect, ['baz.baz_0', 0]]
                bit_field { name :foo_0; bit_assignment lsb: 0; type :rw; initial_value 0 }
              end
              register do
                name :bar
                offset_address 0x0
                type [:indirect, ['baz.baz_0', 0]]
                bit_field { name :bar_0; bit_assignment lsb: 0; type :rw; initial_value 0 }
              end
              register do
                name :baz
                offset_address 0x4
                bit_field { name :baz_0; bit_assignment lsb: 0, width: 4; type :rw; initial_value 0 }
                bit_field { name :baz_1; bit_assignment lsb: 4, width: 4; type :rw; initial_value 0 }
                bit_field { name :baz_2; bit_assignment lsb: 8, width: 4; type :rw; initial_value 0 }
              end
            end
          }.to raise_register_map_error 'cannot be distinguished from other registers'

          expect {
            create_registers do
              register do
                name :foo
                offset_address 0x0
                type [:indirect, ['baz.baz_0', 0]]
                bit_field { name :foo_0; bit_assignment lsb: 0; type :rw; initial_value 0 }
              end
              register do
                name :bar
                offset_address 0x0
                type [:indirect, ['baz.baz_1', 0]]
                bit_field { name :bar_0; bit_assignment lsb: 0; type :rw; initial_value 0 }
              end
              register do
                name :baz
                offset_address 0x4
                bit_field { name :baz_0; bit_assignment lsb: 0, width: 4; type :rw; initial_value 0 }
                bit_field { name :baz_1; bit_assignment lsb: 4, width: 4; type :rw; initial_value 0 }
                bit_field { name :baz_2; bit_assignment lsb: 8, width: 4; type :rw; initial_value 0 }
              end
            end
          }.to raise_register_map_error 'cannot be distinguished from other registers'

          expect {
            create_registers do
              register do
                name :foo
                offset_address 0x0
                size 2
                type [:indirect, 'baz.baz_0']
                bit_field { name :foo_0; bit_assignment lsb: 0; type :rw; initial_value 0 }
              end
              register do
                name :bar
                offset_address 0x0
                size 2
                type [:indirect, 'baz.baz_1']
                bit_field { name :bar_0; bit_assignment lsb: 0; type :rw; initial_value 0 }
              end
              register do
                name :baz
                offset_address 0x4
                bit_field { name :baz_0; bit_assignment lsb: 0, width: 4; type :rw; initial_value 0 }
                bit_field { name :baz_1; bit_assignment lsb: 4, width: 4; type :rw; initial_value 0 }
                bit_field { name :baz_2; bit_assignment lsb: 8, width: 4; type :rw; initial_value 0 }
              end
            end
          }.to raise_register_map_error 'cannot be distinguished from other registers'

          expect {
            create_registers do
              register do
                name :foo
                offset_address 0x0
                size [2, 2]
                type [:indirect, 'baz.baz_0', 'baz.baz_1']
                bit_field { name :foo_0; bit_assignment lsb: 0; type :rw; initial_value 0 }
              end
              register do
                name :bar
                offset_address 0x0
                size [2, 2]
                type [:indirect, 'baz.baz_0', 'baz.baz_2']
                bit_field { name :bar_0; bit_assignment lsb: 0; type :rw; initial_value 0 }
              end
              register do
                name :baz
                offset_address 0x4
                bit_field { name :baz_0; bit_assignment lsb: 0, width: 4; type :rw; initial_value 0 }
                bit_field { name :baz_1; bit_assignment lsb: 4, width: 4; type :rw; initial_value 0 }
                bit_field { name :baz_2; bit_assignment lsb: 8, width: 4; type :rw; initial_value 0 }
              end
            end
          }.to raise_register_map_error 'cannot be distinguished from other registers'

          expect {
            create_registers do
              register do
                name :foo
                offset_address 0x0
                size [2, 2]
                type [:indirect, 'baz.baz_0', 'baz.baz_1', ['baz.baz_2', 0]]
                bit_field { name :foo_0; bit_assignment lsb: 0; type :rw; initial_value 0 }
              end
              register do
                name :bar
                offset_address 0x0
                size [2, 2]
                type [:indirect, 'baz.baz_0', 'baz.baz_2', ['baz.baz_2', 0]]
                bit_field { name :bar_0; bit_assignment lsb: 0; type :rw; initial_value 0 }
              end
              register do
                name :baz
                offset_address 0x4
                bit_field { name :baz_0; bit_assignment lsb: 0, width: 4; type :rw; initial_value 0 }
                bit_field { name :baz_1; bit_assignment lsb: 4, width: 4; type :rw; initial_value 0 }
                bit_field { name :baz_2; bit_assignment lsb: 8, width: 4; type :rw; initial_value 0 }
              end
            end
          }.to raise_register_map_error 'cannot be distinguished from other registers'

          expect {
            create_registers do
              register do
                name :foo
                offset_address 0x0
                size [2, 2]
                type [:indirect, 'baz.baz_0', 'baz.baz_1', ['baz.baz_2', 0]]
                bit_field { name :foo_0; bit_assignment lsb: 0; type :rw; initial_value 0 }
              end
              register do
                name :bar
                offset_address 0x0
                size [2, 2]
                type [:indirect, 'baz.baz_0', 'baz.baz_2', ['baz.baz_0', 1]]
                bit_field { name :bar_0; bit_assignment lsb: 0; type :rw; initial_value 0 }
              end
              register do
                name :baz
                offset_address 0x4
                bit_field { name :baz_0; bit_assignment lsb: 0, width: 4; type :rw; initial_value 0 }
                bit_field { name :baz_1; bit_assignment lsb: 4, width: 4; type :rw; initial_value 0 }
                bit_field { name :baz_2; bit_assignment lsb: 8, width: 4; type :rw; initial_value 0 }
              end
            end
          }.to raise_register_map_error 'cannot be distinguished from other registers'
        end
      end
    end
  end
end
