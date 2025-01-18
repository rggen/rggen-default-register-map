# frozen_string_literal: true

RSpec.describe 'global/address_width' do
  include_context 'configuration common'
  include_context 'clean-up builder'

  before(:all) do
    RgGen.enable(:global, :address_width)
    RgGen.enable(:register_block, :bus_width)
  end

  describe '#address_width' do
    specify 'デフォルト値は32である' do
      configuration = create_configuration
      expect(configuration.address_width).to eq 32
    end

    it '入力されたアドレス幅を返す' do
      [
        [8, 1],
        [16, 1],
        [32, 2],
        [64, 3]
      ].each do |bus_width, min_address_width|
        [min_address_width, 8, 16, 32, 64, rand(min_address_width..64)].each do |value|
          input_value = value
          configuration = create_configuration(bus_width: bus_width, address_width: input_value)
          expect(configuration.address_width).to eq value

          input_value = value.to_f
          configuration = create_configuration(bus_width: bus_width, address_width: input_value)
          expect(configuration.address_width).to eq value

          input_value = value.to_s
          configuration = create_configuration(bus_width: bus_width, address_width: input_value)
          expect(configuration.address_width).to eq value

          input_value = format('0x%x', value)
          configuration = create_configuration(bus_width: bus_width, address_width: input_value)
          expect(configuration.address_width).to eq value
        end
      end
    end
  end

  it '表示可能オブジェクトとして、入力されたアドレス幅を返す' do
    configuration = create_configuration(bus_width: 32, address_width: 32)
    expect(configuration.printables[:address_width]).to eq 32
  end

  describe 'エラーチェック' do
    context '入力値が整数に変換できない場合' do
      it 'ConfigurationErrorを起こす' do
        [true, false, 'foo', '0x00_gh', Object.new].each do |value|
          expect {
            create_configuration(address_width: value)
          }.to raise_configuration_error "cannot convert #{value.inspect} into address width"
        end
      end
    end

    context '入力値が正数ではない場合' do
      it 'ConfigurationErrorを起こす' do
        expect {
          create_configuration(address_width: -1)
        }.to raise_configuration_error 'non positive value is not allowed for address width: -1'

        expect {
          create_configuration(address_width: 0)
        }.to raise_configuration_error 'non positive value is not allowed for address width: 0'

        expect {
          create_configuration(address_width: 1, bus_width: 8)
        }.not_to raise_error
      end
    end
  end
end
