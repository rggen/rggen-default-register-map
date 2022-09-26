# frozen_string_literal: true

RSpec.describe 'bit_field/type/custom' do
  include_context 'clean-up builder'
  include_context 'register map common'

  before(:all) do
    RgGen.enable(:global, [:bus_width, :enable_wide_register])
    RgGen.enable(:register, [:name, :size, :type])
    RgGen.enable(:bit_field, [:name, :bit_assignment, :initial_value, :reference, :type])
    RgGen.enable(:bit_field, :type, [:custom])
  end

  def create_bit_fields(&block)
    register_map = create_register_map do
      register_block do
        register do
          name 'register'
          instance_exec(&block)
        end
      end
    end
    register_map.bit_fields
  end

  def random_sw_read(exclude: nil)
    allowed_value = [:none, :default, :set, :clear]
    (allowed_value - Array(exclude)).sample
  end

  def random_sw_write(exclude: nil)
    allowed_value = [:none, :default, :set, :set_0, :set_1, :clear, :clear_0, :clear_1, :toggle_0, :toggle_1]
    (allowed_value - Array(exclude)).sample
  end

  specify 'ビットフィールド型は:custom' do
    bit_fields = create_bit_fields do
      bit_field { name 'bit_field'; bit_assignment width: 1; type :custom; initial_value 0 }
    end

    expect(bit_fields[0]).to have_property(:type, :custom)
  end

  describe '揮発性' do
    context 'SWによる更新がある場合' do
      specify '不揮発性ビットフィールドである' do
        sw_read, sw_write =
          [:none, :default, :set, :clear]
            .product([:none, :default, :set, :set_0, :set_1, :clear, :clear_0, :clear_1, :toggle_0, :toggle_1])
            .delete_if { |(r, w)| r == :none && w == :none }
            .delete_if { |(r, w)| r == :default && w == :none }
            .sample

        bit_fields = create_bit_fields do
          bit_field { name 'bit_field'; bit_assignment width: 1; type [:custom, sw_read: sw_read, sw_write: sw_write]; initial_value 0 }
        end

        expect(bit_fields[0]).to have_property(:volatile?, false)
      end
    end

    context 'SWによる更新がなく、読み出し不可能な場合' do
      specify '不揮発性ビットフィールドである' do
        bit_fields = create_bit_fields do
          bit_field { name 'bit_field'; bit_assignment width: 1; type [:custom, sw_read: :none, sw_write: :none]; initial_value 0 }
        end

        expect(bit_fields[0]).to have_property(:volatile?, false)
      end
    end

    context 'SWによる更新がなく、読み出し可能な場合' do
      specify '揮発性ビットフィールドである' do
        bit_fields = create_bit_fields do
          bit_field { name 'bit_field'; bit_assignment width: 1; type [:custom, sw_read: :default, sw_write: :none]; initial_value 0 }
        end

        expect(bit_fields[0]).to have_property(:volatile?, true)
      end
    end

    context 'hw_write/hw_set/hw_clearいずれか指定がある場合' do
      specify '揮発性ビットフィールドである' do
        sw_read, sw_write =
          [:none, :default, :set, :clear]
            .product([:none, :default, :set, :set_0, :set_1, :clear, :clear_0, :clear_1, :toggle_0, :toggle_1])
            .delete_if { |(r, w)| r == :none && w == :none }
            .sample

        bit_fields = create_bit_fields do
          bit_field { name 'bit_field_0'; bit_assignment width: 1; type [:custom, sw_read: sw_read, sw_write: sw_write, hw_write: true]; initial_value 0 }
          bit_field { name 'bit_field_1'; bit_assignment width: 1; type [:custom, sw_read: sw_read, sw_write: sw_write, hw_set: true]; initial_value 0 }
          bit_field { name 'bit_field_2'; bit_assignment width: 1; type [:custom, sw_read: sw_read, sw_write: sw_write, hw_clear: true]; initial_value 0 }
        end

        expect(bit_fields[0]).to have_property(:volatile?, true)
        expect(bit_fields[1]).to have_property(:volatile?, true)
        expect(bit_fields[2]).to have_property(:volatile?, true)
      end
    end
  end

  describe 'アクセス属性' do
    context 'sw_read/sw_writともにnone以外の場合' do
      specify 'アクセス属性は読み書き可能' do
        bit_fields = create_bit_fields do
          bit_field { name 'bit_field'; bit_assignment width: 1; type [:custom, sw_read: random_sw_read(exclude: :none), sw_write: random_sw_write(exclude: :none)]; initial_value 0 }
        end

        expect(bit_fields[0]).to match_access(:read_write)
      end
    end

    context 'sw_readのみがnone以外の場合' do
      specify 'アクセス属性は書き込みのみ可能' do
        bit_fields = create_bit_fields do
          bit_field { name 'bit_field'; bit_assignment width: 1; type [:custom, sw_read: :none, sw_write: random_sw_write(exclude: :none)]; initial_value 0 }
        end

        expect(bit_fields[0]).to match_access(:write_only)
      end
    end

    context 'sw_writeのみがnone以外の場合' do
      specify 'アクセス属性は読み出しのみ可能' do
        bit_fields = create_bit_fields do
          bit_field { name 'bit_field'; bit_assignment width: 1; type [:custom, sw_read: random_sw_read(exclude: :none), sw_write: :none]; initial_value 0 }
        end

        expect(bit_fields[0]).to match_access(:read_only)
      end
    end

    context 'sw_read/sw_writともにnone以外の場合' do
      specify 'アクセス属性は予約済み' do
        bit_fields = create_bit_fields do
          bit_field { name 'bit_field'; bit_assignment width: 1; type [:custom, sw_read: :none, sw_write: :none]; initial_value 0 }
        end

        expect(bit_fields[0]).to match_access(:reserved)
      end
    end
  end

  describe '初期値の指定' do
    context 'sw_readがset/clearの場合' do
      specify '初期値の指定が必要' do
        expect {
          create_bit_fields do
            bit_field { name 'bit_field'; bit_assignment width: 1; type [:custom, sw_read: :set, sw_write: random_sw_write] }
          end
        }.to raise_register_map_error

        expect {
          create_bit_fields do
            bit_field { name 'bit_field'; bit_assignment width: 1; type [:custom, sw_read: :clear, sw_write: random_sw_write] }
          end
        }.to raise_register_map_error
      end
    end

    context 'sw_writeがnone以外の場合' do
      specify '初期値の指定が必要' do
        expect {
          create_bit_fields do
            bit_field { name 'bit_field'; bit_assignment width: 1; type [:custom, sw_read: random_sw_read, sw_write: random_sw_write(exclude: :none)] }
          end
        }.to raise_register_map_error
      end
    end

    context 'hw_write/hw_set/hw_clearのいずれかの指定がある場合' do
      specify '初期値の指定が必要' do
        expect {
          create_bit_fields do
            bit_field { name 'bit_field'; bit_assignment width: 0; type [:custom, sw_read: random_sw_read, sw_write: random_sw_write, hw_write: true] }
          end
        }.to raise_register_map_error

        expect {
          create_bit_fields do
            bit_field { name 'bit_field'; bit_assignment width: 0; type [:custom, sw_read: random_sw_read, sw_write: random_sw_write, hw_set: true] }
          end
        }.to raise_register_map_error

        expect {
          create_bit_fields do
            bit_field { name 'bit_field'; bit_assignment width: 0; type [:custom, sw_read: random_sw_read, sw_write: random_sw_write, hw_clear: true] }
          end
        }.to raise_register_map_error
      end
    end

    context 'sw_readがnone/default、sw_writeがnone、hw_write/hw_set/hw_clearの指定がない場合' do
      specify '初期値の指定は不要' do
        expect {
          create_bit_fields do
            bit_field { name 'bit_field'; bit_assignment width: 1; type [:custom, sw_read: :none, sw_write: :none] }
          end
        }.not_to raise_error

        expect {
          create_bit_fields do
            bit_field { name 'bit_field'; bit_assignment width: 1; type [:custom, sw_read: :default, sw_write: :none] }
          end
        }.not_to raise_error
      end
    end
  end

  describe 'sw_read' do
    specify '規定値は:default' do
      bit_fields = create_bit_fields do
        bit_field { name 'bit_field'; bit_assignment width: 1; type :custom; initial_value 0 }
      end

      expect(bit_fields[0]).to have_property(:sw_read, :default)
    end

    it 'none/default/set/clearが指定可能' do
      bit_fields = create_bit_fields do
        bit_field { name 'bit_field_0'; bit_assignment width: 1; type [:custom, sw_read: :none]; initial_value 0 }
        bit_field { name 'bit_field_1'; bit_assignment width: 1; type [:custom, sw_read: :default]; initial_value 0 }
        bit_field { name 'bit_field_2'; bit_assignment width: 1; type [:custom, sw_read: :set]; initial_value 0 }
        bit_field { name 'bit_field_3'; bit_assignment width: 1; type [:custom, sw_read: :clear]; initial_value 0 }
      end

      expect(bit_fields[0]).to have_property(:sw_read, :none)
      expect(bit_fields[1]).to have_property(:sw_read, :default)
      expect(bit_fields[2]).to have_property(:sw_read, :set)
      expect(bit_fields[3]).to have_property(:sw_read, :clear)
    end

    context 'none/default/set/clear以外を指定した場合' do
      specify 'RegisterMapErrorを起こす' do
        [:foo, 'foo', '', nil, true, false, 1, Object.new].each do |value|
          expect {
            create_bit_fields do
              bit_field { name 'bit_field'; bit_assignment width: 1; type [:custom, sw_read: value]; initial_value 0 }
            end
          }.to raise_register_map_error "invalid value for sw_read option: #{value.inspect}"
        end
      end
    end
  end

  describe 'sw_write' do
    specify '規定値は:default' do
      bit_fields = create_bit_fields do
        bit_field { name 'bit_field'; bit_assignment width: 1; type :custom; initial_value 0 }
      end

      expect(bit_fields[0]).to have_property(:sw_write, :default)
    end

    specify 'none/default/set/set_0/set_1/clear/clear_0/clear_1/toggle_0/toggle_1が指定可能' do
      bit_fields = create_bit_fields do
        bit_field { name 'bit_field_0'; bit_assignment width: 1; type [:custom, sw_write: :none]; initial_value 0 }
        bit_field { name 'bit_field_1'; bit_assignment width: 1; type [:custom, sw_write: :default]; initial_value 0 }
        bit_field { name 'bit_field_2'; bit_assignment width: 1; type [:custom, sw_write: :set]; initial_value 0 }
        bit_field { name 'bit_field_3'; bit_assignment width: 1; type [:custom, sw_write: :set_0]; initial_value 0 }
        bit_field { name 'bit_field_4'; bit_assignment width: 1; type [:custom, sw_write: :set_1]; initial_value 0 }
        bit_field { name 'bit_field_5'; bit_assignment width: 1; type [:custom, sw_write: :clear]; initial_value 0 }
        bit_field { name 'bit_field_6'; bit_assignment width: 1; type [:custom, sw_write: :clear_0]; initial_value 0 }
        bit_field { name 'bit_field_7'; bit_assignment width: 1; type [:custom, sw_write: :clear_1]; initial_value 0 }
        bit_field { name 'bit_field_8'; bit_assignment width: 1; type [:custom, sw_write: :toggle_0]; initial_value 0 }
        bit_field { name 'bit_field_9'; bit_assignment width: 1; type [:custom, sw_write: :toggle_1]; initial_value 0 }
      end

      expect(bit_fields[0]).to have_property(:sw_write, :none)
      expect(bit_fields[1]).to have_property(:sw_write, :default)
      expect(bit_fields[2]).to have_property(:sw_write, :set)
      expect(bit_fields[3]).to have_property(:sw_write, :set_0)
      expect(bit_fields[4]).to have_property(:sw_write, :set_1)
      expect(bit_fields[5]).to have_property(:sw_write, :clear)
      expect(bit_fields[6]).to have_property(:sw_write, :clear_0)
      expect(bit_fields[7]).to have_property(:sw_write, :clear_1)
      expect(bit_fields[8]).to have_property(:sw_write, :toggle_0)
      expect(bit_fields[9]).to have_property(:sw_write, :toggle_1)
    end

    context 'none/default/set/set_0/set_1/clear/clear_0/clear_1/toggle_0/toggle_1以外を指定した場合' do
      specify 'RegisterMapErrorを起こす' do
        [:foo, 'foo', '', nil, true, false, 1, Object.new].each do |value|
          expect {
            create_bit_fields do
              bit_field { name 'bit_field'; bit_assignment width: 1; type [:custom, sw_write: value]; initial_value 0 }
            end
          }.to raise_register_map_error "invalid value for sw_write option: #{value.inspect}"
        end
      end
    end
  end

  describe 'hw_write' do
    specify '規定値はfalse' do
      bit_fields = create_bit_fields do
        bit_field { name 'bit_field'; bit_assignment width: 1; type :custom; initial_value 0 }
      end

      expect(bit_fields[0]).to have_property(:hw_write?, false)
    end

    specify 'true/on/yes/false/off/noが指定可能' do
      bit_fields = create_bit_fields do
        bit_field { name 'bit_field_0'; bit_assignment width: 1; type [:custom, hw_write: true]; initial_value 0}
        bit_field { name 'bit_field_1'; bit_assignment width: 1; type [:custom, hw_write: :true]; initial_value 0}
        bit_field { name 'bit_field_2'; bit_assignment width: 1; type [:custom, hw_write: :yes]; initial_value 0}
        bit_field { name 'bit_field_3'; bit_assignment width: 1; type [:custom, hw_write: :on]; initial_value 0}
        bit_field { name 'bit_field_4'; bit_assignment width: 1; type [:custom, hw_write: false]; initial_value 0}
        bit_field { name 'bit_field_5'; bit_assignment width: 1; type [:custom, hw_write: :false]; initial_value 0}
        bit_field { name 'bit_field_6'; bit_assignment width: 1; type [:custom, hw_write: :no]; initial_value 0}
        bit_field { name 'bit_field_7'; bit_assignment width: 1; type [:custom, hw_write: :off]; initial_value 0}
      end

      expect(bit_fields[0]).to have_property(:hw_write?, true)
      expect(bit_fields[1]).to have_property(:hw_write?, true)
      expect(bit_fields[2]).to have_property(:hw_write?, true)
      expect(bit_fields[3]).to have_property(:hw_write?, true)
      expect(bit_fields[4]).to have_property(:hw_write?, false)
      expect(bit_fields[5]).to have_property(:hw_write?, false)
      expect(bit_fields[6]).to have_property(:hw_write?, false)
      expect(bit_fields[7]).to have_property(:hw_write?, false)
    end

    context 'true/on/yes/false/off/no以外を指定した場合' do
      specify 'RegisterMapErrorを起こす' do
        [:foo, 'foo', '', nil, 1, Object.new].each do |value|
          expect {
            create_bit_fields do
              bit_field { name 'bit_field'; bit_assignment width: 1; type [:custom, hw_write: value]; initial_value 0 }
            end
          }.to raise_register_map_error "invalid value for hw_write option: #{value.inspect}"
        end
      end
    end
  end

  describe 'hw_set' do
    specify '規定値はfalse' do
      bit_fields = create_bit_fields do
        bit_field { name 'bit_field'; bit_assignment width: 1; type :custom; initial_value 0 }
      end

      expect(bit_fields[0]).to have_property(:hw_set?, false)
    end

    specify 'true/on/yes/false/off/noが指定可能' do
      bit_fields = create_bit_fields do
        bit_field { name 'bit_field_0'; bit_assignment width: 1; type [:custom, hw_set: true]; initial_value 0}
        bit_field { name 'bit_field_1'; bit_assignment width: 1; type [:custom, hw_set: :true]; initial_value 0}
        bit_field { name 'bit_field_2'; bit_assignment width: 1; type [:custom, hw_set: :yes]; initial_value 0}
        bit_field { name 'bit_field_3'; bit_assignment width: 1; type [:custom, hw_set: :on]; initial_value 0}
        bit_field { name 'bit_field_4'; bit_assignment width: 1; type [:custom, hw_set: false]; initial_value 0}
        bit_field { name 'bit_field_5'; bit_assignment width: 1; type [:custom, hw_set: :false]; initial_value 0}
        bit_field { name 'bit_field_6'; bit_assignment width: 1; type [:custom, hw_set: :no]; initial_value 0}
        bit_field { name 'bit_field_7'; bit_assignment width: 1; type [:custom, hw_set: :off]; initial_value 0}
      end

      expect(bit_fields[0]).to have_property(:hw_set?, true)
      expect(bit_fields[1]).to have_property(:hw_set?, true)
      expect(bit_fields[2]).to have_property(:hw_set?, true)
      expect(bit_fields[3]).to have_property(:hw_set?, true)
      expect(bit_fields[4]).to have_property(:hw_set?, false)
      expect(bit_fields[5]).to have_property(:hw_set?, false)
      expect(bit_fields[6]).to have_property(:hw_set?, false)
      expect(bit_fields[7]).to have_property(:hw_set?, false)
    end

    context 'true/on/yes/false/off/no以外を指定した場合' do
      specify 'RegisterMapErrorを起こす' do
        [:foo, 'foo', '', nil, 1, Object.new].each do |value|
          expect {
            create_bit_fields do
              bit_field { name 'bit_field'; bit_assignment width: 1; type [:custom, hw_set: value]; initial_value 0 }
            end
          }.to raise_register_map_error "invalid value for hw_set option: #{value.inspect}"
        end
      end
    end
  end

  describe 'hw_clear' do
    specify '規定値はfalse' do
      bit_fields = create_bit_fields do
        bit_field { name 'bit_field'; bit_assignment width: 1; type :custom; initial_value 0 }
      end

      expect(bit_fields[0]).to have_property(:hw_clear?, false)
    end

    specify 'true/on/yes/false/off/noが指定可能' do
      bit_fields = create_bit_fields do
        bit_field { name 'bit_field_0'; bit_assignment width: 1; type [:custom, hw_clear: true]; initial_value 0}
        bit_field { name 'bit_field_1'; bit_assignment width: 1; type [:custom, hw_clear: :true]; initial_value 0}
        bit_field { name 'bit_field_2'; bit_assignment width: 1; type [:custom, hw_clear: :yes]; initial_value 0}
        bit_field { name 'bit_field_3'; bit_assignment width: 1; type [:custom, hw_clear: :on]; initial_value 0}
        bit_field { name 'bit_field_4'; bit_assignment width: 1; type [:custom, hw_clear: false]; initial_value 0}
        bit_field { name 'bit_field_5'; bit_assignment width: 1; type [:custom, hw_clear: :false]; initial_value 0}
        bit_field { name 'bit_field_6'; bit_assignment width: 1; type [:custom, hw_clear: :no]; initial_value 0}
        bit_field { name 'bit_field_7'; bit_assignment width: 1; type [:custom, hw_clear: :off]; initial_value 0}
      end

      expect(bit_fields[0]).to have_property(:hw_clear?, true)
      expect(bit_fields[1]).to have_property(:hw_clear?, true)
      expect(bit_fields[2]).to have_property(:hw_clear?, true)
      expect(bit_fields[3]).to have_property(:hw_clear?, true)
      expect(bit_fields[4]).to have_property(:hw_clear?, false)
      expect(bit_fields[5]).to have_property(:hw_clear?, false)
      expect(bit_fields[6]).to have_property(:hw_clear?, false)
      expect(bit_fields[7]).to have_property(:hw_clear?, false)
    end

    context 'true/on/yes/false/off/no以外を指定した場合' do
      specify 'RegisterMapErrorを起こす' do
        [:foo, 'foo', '', nil, 1, Object.new].each do |value|
          expect {
            create_bit_fields do
              bit_field { name 'bit_field'; bit_assignment width: 1; type [:custom, hw_clear: value]; initial_value 0 }
            end
          }.to raise_register_map_error "invalid value for hw_clear option: #{value.inspect}"
        end
      end
    end
  end

  describe 'read_trigger' do
    specify '規定値はfalse' do
      bit_fields = create_bit_fields do
        bit_field { name 'bit_field'; bit_assignment width: 1; type :custom; initial_value 0 }
      end

      expect(bit_fields[0]).to have_property(:read_trigger?, false)
    end

    specify 'true/on/yes/false/off/noが指定可能' do
      bit_fields = create_bit_fields do
        bit_field { name 'bit_field_0'; bit_assignment width: 1; type [:custom, read_trigger: true]; initial_value 0}
        bit_field { name 'bit_field_1'; bit_assignment width: 1; type [:custom, read_trigger: :true]; initial_value 0}
        bit_field { name 'bit_field_2'; bit_assignment width: 1; type [:custom, read_trigger: :yes]; initial_value 0}
        bit_field { name 'bit_field_3'; bit_assignment width: 1; type [:custom, read_trigger: :on]; initial_value 0}
        bit_field { name 'bit_field_4'; bit_assignment width: 1; type [:custom, read_trigger: false]; initial_value 0}
        bit_field { name 'bit_field_5'; bit_assignment width: 1; type [:custom, read_trigger: :false]; initial_value 0}
        bit_field { name 'bit_field_6'; bit_assignment width: 1; type [:custom, read_trigger: :no]; initial_value 0}
        bit_field { name 'bit_field_7'; bit_assignment width: 1; type [:custom, read_trigger: :off]; initial_value 0}
      end

      expect(bit_fields[0]).to have_property(:read_trigger?, true)
      expect(bit_fields[1]).to have_property(:read_trigger?, true)
      expect(bit_fields[2]).to have_property(:read_trigger?, true)
      expect(bit_fields[3]).to have_property(:read_trigger?, true)
      expect(bit_fields[4]).to have_property(:read_trigger?, false)
      expect(bit_fields[5]).to have_property(:read_trigger?, false)
      expect(bit_fields[6]).to have_property(:read_trigger?, false)
      expect(bit_fields[7]).to have_property(:read_trigger?, false)
    end

    context 'true/on/yes/false/off/no以外を指定した場合' do
      specify 'RegisterMapErrorを起こす' do
        [:foo, 'foo', '', nil, 1, Object.new].each do |value|
          expect {
            create_bit_fields do
              bit_field { name 'bit_field'; bit_assignment width: 1; type [:custom, read_trigger: value]; initial_value 0 }
            end
          }.to raise_register_map_error "invalid value for read_trigger option: #{value.inspect}"
        end
      end
    end
  end

  describe 'read_trigger' do
    specify '規定値はfalse' do
      bit_fields = create_bit_fields do
        bit_field { name 'bit_field'; bit_assignment width: 1; type :custom; initial_value 0 }
      end

      expect(bit_fields[0]).to have_property(:read_trigger?, false)
    end

    specify 'true/on/yes/false/off/noが指定可能' do
      bit_fields = create_bit_fields do
        bit_field { name 'bit_field_0'; bit_assignment width: 1; type [:custom, read_trigger: true]; initial_value 0}
        bit_field { name 'bit_field_1'; bit_assignment width: 1; type [:custom, read_trigger: :true]; initial_value 0}
        bit_field { name 'bit_field_2'; bit_assignment width: 1; type [:custom, read_trigger: :yes]; initial_value 0}
        bit_field { name 'bit_field_3'; bit_assignment width: 1; type [:custom, read_trigger: :on]; initial_value 0}
        bit_field { name 'bit_field_4'; bit_assignment width: 1; type [:custom, read_trigger: false]; initial_value 0}
        bit_field { name 'bit_field_5'; bit_assignment width: 1; type [:custom, read_trigger: :false]; initial_value 0}
        bit_field { name 'bit_field_6'; bit_assignment width: 1; type [:custom, read_trigger: :no]; initial_value 0}
        bit_field { name 'bit_field_7'; bit_assignment width: 1; type [:custom, read_trigger: :off]; initial_value 0}
      end

      expect(bit_fields[0]).to have_property(:read_trigger?, true)
      expect(bit_fields[1]).to have_property(:read_trigger?, true)
      expect(bit_fields[2]).to have_property(:read_trigger?, true)
      expect(bit_fields[3]).to have_property(:read_trigger?, true)
      expect(bit_fields[4]).to have_property(:read_trigger?, false)
      expect(bit_fields[5]).to have_property(:read_trigger?, false)
      expect(bit_fields[6]).to have_property(:read_trigger?, false)
      expect(bit_fields[7]).to have_property(:read_trigger?, false)
    end

    context 'true/on/yes/false/off/no以外を指定した場合' do
      specify 'RegisterMapErrorを起こす' do
        [:foo, 'foo', '', nil, 1, Object.new].each do |value|
          expect {
            create_bit_fields do
              bit_field { name 'bit_field'; bit_assignment width: 1; type [:custom, read_trigger: value]; initial_value 0 }
            end
          }.to raise_register_map_error "invalid value for read_trigger option: #{value.inspect}"
        end
      end
    end
  end

  describe 'write_trigger' do
    specify '規定値はfalse' do
      bit_fields = create_bit_fields do
        bit_field { name 'bit_field'; bit_assignment width: 1; type :custom; initial_value 0 }
      end

      expect(bit_fields[0]).to have_property(:write_trigger?, false)
    end

    specify 'true/on/yes/false/off/noが指定可能' do
      bit_fields = create_bit_fields do
        bit_field { name 'bit_field_0'; bit_assignment width: 1; type [:custom, write_trigger: true]; initial_value 0}
        bit_field { name 'bit_field_1'; bit_assignment width: 1; type [:custom, write_trigger: :true]; initial_value 0}
        bit_field { name 'bit_field_2'; bit_assignment width: 1; type [:custom, write_trigger: :yes]; initial_value 0}
        bit_field { name 'bit_field_3'; bit_assignment width: 1; type [:custom, write_trigger: :on]; initial_value 0}
        bit_field { name 'bit_field_4'; bit_assignment width: 1; type [:custom, write_trigger: false]; initial_value 0}
        bit_field { name 'bit_field_5'; bit_assignment width: 1; type [:custom, write_trigger: :false]; initial_value 0}
        bit_field { name 'bit_field_6'; bit_assignment width: 1; type [:custom, write_trigger: :no]; initial_value 0}
        bit_field { name 'bit_field_7'; bit_assignment width: 1; type [:custom, write_trigger: :off]; initial_value 0}
      end

      expect(bit_fields[0]).to have_property(:write_trigger?, true)
      expect(bit_fields[1]).to have_property(:write_trigger?, true)
      expect(bit_fields[2]).to have_property(:write_trigger?, true)
      expect(bit_fields[3]).to have_property(:write_trigger?, true)
      expect(bit_fields[4]).to have_property(:write_trigger?, false)
      expect(bit_fields[5]).to have_property(:write_trigger?, false)
      expect(bit_fields[6]).to have_property(:write_trigger?, false)
      expect(bit_fields[7]).to have_property(:write_trigger?, false)
    end

    context 'true/on/yes/false/off/no以外を指定した場合' do
      specify 'RegisterMapErrorを起こす' do
        [:foo, 'foo', '', nil, 1, Object.new].each do |value|
          expect {
            create_bit_fields do
              bit_field { name 'bit_field'; bit_assignment width: 1; type [:custom, write_trigger: value]; initial_value 0 }
            end
          }.to raise_register_map_error "invalid value for write_trigger option: #{value.inspect}"
        end
      end
    end
  end

  describe '#printables[:type]' do
    specify '型名とオプションを配列として返す' do
      sw_read = random_sw_read
      sw_write = random_sw_write
      hw_write = [true, false].sample
      hw_set = [true, false].sample
      hw_clear = [true, false].sample
      read_trigger = [true, false].sample
      write_trigger = [true, false].sample

      bit_fields = create_bit_fields do
        bit_field do
          name 'bit_field_0'
          bit_assignment width: 1
          initial_value 0
          type :custom
        end

        bit_field do
          name 'bit_field_1'
          bit_assignment width: 1
          initial_value 0
          type [
            :custom,
            { sw_read: sw_read, sw_write: sw_write },
            { hw_write: hw_write, hw_set: hw_set, hw_clear: hw_clear},
            read_trigger: read_trigger, write_trigger: write_trigger
          ]
        end
      end

      expect(bit_fields[0].printables[:type]).to match([
        eq(:custom), 'sw_read: default', 'sw_write: default',
        'hw_write: false', 'hw_set: false', 'hw_clear: false'
      ])
      expect(bit_fields[1].printables[:type]).to match([
        eq(:custom), "sw_read: #{sw_read}", "sw_write: #{sw_write}",
        "hw_write: #{hw_write}", "hw_set: #{hw_set}", "hw_clear: #{hw_clear}"
      ])
    end
  end

  specify '複数個のオプションを指定できる' do
    sw_read = random_sw_read
    sw_write = random_sw_write
    hw_write = [true, false].sample
    hw_set = [true, false].sample
    hw_clear = [true, false].sample
    read_trigger = [true, false].sample
    write_trigger = [true, false].sample

    bit_fields = create_bit_fields do
      bit_field do
        name 'bit_field_0'
        bit_assignment width: 1
        initial_value 0
        type [
          :custom,
          { sw_read: sw_read, sw_write: sw_write },
          { hw_write: hw_write, hw_set: hw_set, hw_clear: hw_clear},
          read_trigger: read_trigger, write_trigger: write_trigger
        ]
      end

      bit_field do
        name 'bit_field_1'
        bit_assignment width: 1
        initial_value 0
        type "custom: sw_read: #{sw_read}, sw_write: #{sw_write}, " \
             "hw_write: #{hw_write}, hw_set: #{hw_set}, hw_clear: #{hw_clear}, " \
             "read_trigger: #{read_trigger}, write_trigger: #{write_trigger}"
      end
    end

    expect(bit_fields[0]).to have_properties([
      [:sw_read, sw_read], [:sw_write, sw_write], [:hw_write?, hw_write],
      [:hw_set?, hw_set], [:hw_clear?, hw_clear], [:read_trigger?, read_trigger], [:write_trigger?, write_trigger]
    ])
    expect(bit_fields[1]).to have_properties([
      [:sw_read, sw_read], [:sw_write, sw_write], [:hw_write?, hw_write],
      [:hw_set?, hw_set], [:hw_clear?, hw_clear], [:read_trigger?, read_trigger], [:write_trigger?, write_trigger]
    ])
  end

  context 'Hashにマージできない値がオプションに指定された場合' do
    specify 'RegisterMapErrorを起こす' do
      [
        [nil],
        [:sw_read],
        [[:sw_read]],
        [[:sw_read, :default, :none]],
        [{sw_write: :default}, nil],
        [{sw_write: :default}, :sw_read],
        [{sw_write: :default}, [:sw_read]],
        [{sw_write: :default}, [:sw_read, :default, :none]]
      ].each do |options|
        expect {
          create_bit_fields do
            bit_field { name 'bit_field'; bit_assignment width: 1; type [:custom, *options]}
          end
        }.to raise_register_map_error "invalid options are given: #{options.inspect}"
      end
    end
  end

  context '不明なオプションが指定された場合' do
    specify 'RegisterMapErrorを起こす' do
      [
        nil, true, false, :foo, 'foo', 1, Object.new
      ].each do |option|
        expect {
          create_bit_fields do
            bit_field { name 'bit_field'; bit_assignment width: 1; type [:custom, option => true]; initial_value 0 }
          end
        }.to raise_register_map_error "unknown option is given: #{option.inspect}"

        expect {
          create_bit_fields do
            bit_field { name 'bit_field'; bit_assignment width: 1; type [:custom, sw_read: :default, option => true]; initial_value 0 }
          end
        }.to raise_register_map_error "unknown option is given: #{option.inspect}"
      end
    end
  end
end