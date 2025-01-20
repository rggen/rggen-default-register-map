# frozen_string_literal: true

RSpec.describe 'register_block/byte_size' do
  include_context 'clean-up builder'
  include_context 'register map common'

  before(:all) do
    RgGen.enable(:global, :address_width)
    RgGen.enable(:register_block, [:byte_size, :bus_width])
  end

  def create_register_block(configuration = nil, &block)
    create_register_map(configuration) { register_block(&block) }
      .register_blocks.first
  end

  describe '#byte_size' do
    let(:address_width) { 16 }

    let(:max_byte_size) { 2**(address_width - 3) }

    it '入力されたバイトサイズを返す' do
      [16, 32, 64].each do |bus_width|
        configuration = create_configuration(bus_width: bus_width, address_width: address_width)

        register_block = create_register_block(configuration) { byte_size bus_width / 8 }
        expect(register_block).to have_property(:byte_size, bus_width / 8)

        register_block = create_register_block(configuration) { byte_size 2 * (bus_width / 8) }
        expect(register_block).to have_property(:byte_size, 2 * (bus_width / 8))

        register_block = create_register_block(configuration) { byte_size max_byte_size / 2 }
        expect(register_block).to have_property(:byte_size, max_byte_size / 2)

        register_block = create_register_block(configuration) { byte_size max_byte_size - bus_width / 8}
        expect(register_block).to have_property(:byte_size, max_byte_size - bus_width / 8)

        register_block = create_register_block(configuration) { byte_size max_byte_size }
        expect(register_block).to have_property(:byte_size, max_byte_size)
      end
    end
  end

  describe '#local_address_width' do
    let(:bus_width) { 32 }

    it 'レジスタブロック側で必要なアドレス幅を返す' do
      configuration = create_configuration(bus_width: bus_width)

      { 4 => 2, 8 => 3, 12 => 4, 16 => 4, 256 => 8 }.each do |size, address_width|
        register_block = create_register_block(configuration) { byte_size size }
        expect(register_block).to have_property(:local_address_width, address_width)
      end
    end
  end

  it '表示可能オブジェクトとして、バイトサイズを返す' do
    configuration = create_configuration(bus_width: 32, address_width: 16)
    register_block = create_register_block(configuration) { byte_size 256 }
    expect(register_block.printables[:byte_size]).to eq 256
  end

  describe 'エラーチェック' do
    context 'バイトサイズが未指定の場合' do
      it 'RegisterMapErrorを起こす' do
        expect {
          create_register_block {}
        }.to raise_register_map_error 'no byte size is given'

        expect {
          create_register_block { byte_size nil }
        }.to raise_register_map_error 'no byte size is given'

        expect {
          create_register_block { byte_size '' }
        }.to raise_register_map_error 'no byte size is given'
      end
    end

    context '入力値が整数に変換できない場合' do
      it 'RegisterMapErrorを起こす' do
        [true, false, '0xef_gc', Object.new].each do |value|
          expect {
            create_register_block { byte_size value }
          }.to raise_register_map_error "cannot convert #{value.inspect} into byte size"
        end
      end
    end

    context '入力値が 0 以下の場合' do
      it 'RegisterMapErrorを起こす' do
        [0, -1, -2, rand(-10..-3)].each do |value|
          expect {
            create_register_block { byte_size value }
          }.to raise_register_map_error "non positive value is not allowed for byte size: #{value}"
        end
      end
    end

    context '入力値がアドレス幅を超える場合' do
      let(:address_width) { 10 }

      let(:configuration) { create_configuration(address_width: address_width) }

      it 'RegisterMapErrorを起こす' do
        [1025, 1028, 2048].each do |value|
          expect {
            create_register_block(configuration) { byte_size value }
          }.to raise_register_map_error 'input byte size is greater than maximum byte size: ' \
                                        "input byte size #{value} maximum byte size 1024"
        end
      end
    end

    context '入力値がバス幅に揃っていない場合' do
      let(:address_width) { 10 }

      it 'RegisterMapErrorを起こす' do
        {
          16 => [1,    3,    5,    7, 9, 127, 1023],
          32 => [1, 2, 3,    5, 6, 7, 9, 127, 1023],
          64 => [1, 2, 3, 4, 5, 6, 7, 9, 127, 1023]
        }.each do |input_bus_width, values|
          configuration = create_configuration(address_width:)
          values.each do |value|
            expect {
              create_register_block(configuration) { byte_size value; bus_width input_bus_width }
            }.to raise_register_map_error "byte size is not aligned with bus width(#{input_bus_width}): #{value}"
          end
        end
      end
    end
  end
end
