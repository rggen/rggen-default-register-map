# frozen_string_literal: true

RSpec.describe 'register_block/bus_width' do
  include_context 'configuration common'
  include_context 'register map common'
  include_context 'clean-up builder'

  before(:all) do
    RgGen.enable(:global, :address_width)
    RgGen.enable(:register_block, :bus_width)
  end

  def create_register_block(configuration = nil, **config_values, &)
    configuration ||= create_configuration(**config_values)
    create_register_map(configuration) { register_block(&) }
      .register_blocks
      .first
  end

  describe 'configurtion' do
    describe '#bus_width' do
      specify 'デフォル値は32である' do
        configuration = create_configuration
        expect(configuration.bus_width).to eq 32
      end

      it '入力されたバス幅を返す' do
        [8, 16, 32, 64, 128].each do |value|
          input_value = value
          configuration = create_configuration { bus_width input_value }
          expect(configuration.bus_width).to eq value

          input_value = value.to_f
          configuration = create_configuration { bus_width input_value }
          expect(configuration.bus_width).to eq value

          input_value = value.to_s
          configuration = create_configuration { bus_width input_value }
          expect(configuration.bus_width).to eq value

          input_value = format('0x%x', value)
          configuration = create_configuration { bus_width input_value }
          expect(configuration.bus_width).to eq value
        end
      end
    end

    it '表示可能オブジェクトとして、入力されたバス幅を返す' do
      width = [8, 16, 32, 64].sample
      configuration = create_configuration(bus_width: width)
      expect(configuration.printables[:bus_width]).to eq width
    end
  end

  describe 'register_map' do
    describe '#bus_width/#byte_width' do
      it 'デフォルト値はコンフィグレーションで指定された値である' do
        register_block = create_register_block {}
        expect(register_block.bus_width).to eq 32
        expect(register_block.byte_width).to eq 4

        config_bus_width = [8, 16, 32, 64, 128].sample
        register_block = create_register_block(bus_width: config_bus_width)
        expect(register_block.bus_width).to eq config_bus_width
        expect(register_block.byte_width).to eq config_bus_width / 8
      end

      it '入力されたバス幅/バイト幅を返す' do
        [8, 16, 32, 64, 128].each do |value|
          config_bus_width = [8, 16, 32, 64, 128].sample

          register_block = create_register_block(bus_width: config_bus_width) { bus_width value }
          expect(register_block.bus_width).to eq value
          expect(register_block.byte_width).to eq value / 8

          register_block = create_register_block(bus_width: config_bus_width) { bus_width value.to_f }
          expect(register_block.bus_width).to eq value
          expect(register_block.byte_width).to eq value / 8

          register_block = create_register_block(bus_width: config_bus_width) { bus_width value.to_s }
          expect(register_block.bus_width).to eq value
          expect(register_block.byte_width).to eq value / 8

          register_block = create_register_block(bus_width: config_bus_width) { bus_width format('0x%x', value) }
          expect(register_block.bus_width).to eq value
          expect(register_block.byte_width).to eq value / 8
        end
      end

      it '表示可能オブジェクトとして、入力されたバス幅を返す' do
        width = [8, 16, 32, 64].sample
        register_block = create_register_block { bus_width width }
        expect(register_block.printables[:bus_width]).to eq width
      end
    end

    describe '#position' do
      context 'レジスタマップ上でバス幅が指定されていない場合' do
        it 'コンフィグレーション上の位置情報を返す' do
          position = double('position')
          configuration = create_configuration(bus_width: 32)
          register_block = create_register_block(configuration)

          allow(configuration.feature(:bus_width)).to receive(:position).and_return(position)
          expect(register_block.feature(:bus_width).position).to equal position
        end
      end
    end
  end

  describe 'エラーチェック' do
    context '入力が整数に変換できない場合' do
      it 'SourceErrorを起こす' do
        [true, false, 'foo', '0xef_gh', Object.new].each do |value|
          expect {
            create_configuration { bus_width value }
          }.to raise_source_error "cannot convert #{value.inspect} into bus width"

          expect {
            create_register_block { bus_width value }
          }.to raise_source_error "cannot convert #{value.inspect} into bus width"
        end
      end
    end

    context '入力が8未満の場合' do
      it 'SourceErrorを起こす' do
        [-1, 0, 1, 7].each do |value|
          expect {
            create_configuration { bus_width value }
          }.to raise_source_error "input bus width is less than 8: #{value}"

          expect {
            create_register_block { bus_width value }
          }.to raise_source_error "input bus width is less than 8: #{value}"
        end
      end
    end

    context '入力が2のべき乗ではない場合' do
      it 'SourceErrorを起こす' do
        [31, 33, 63, 65].each do |value|
          expect {
            create_configuration { bus_width value }
          }.to raise_source_error "input bus width is not power of 2: #{value}"

          expect {
            create_register_block { bus_width value }
          }.to raise_source_error "input bus width is not power of 2: #{value}"
        end
      end
    end

    context 'アドレス幅から求まる最大値を超える場合' do
      it 'SourceErrorを起こす' do
        [
          [32, 1],
          [64, 1],
          [64, 2]
        ].each do |(input_bus_width, address_width)|
          message = 'input bus width is grater than maximum bus width: ' \
                    "bus width #{input_bus_width} maximum bus width #{2**(3 + address_width)}"
          expect {
            create_register_block(bus_width: input_bus_width, address_width:) {}
          }.to raise_source_error message

          expect {
            create_register_block(bus_width: 8, address_width: address_width) { bus_width input_bus_width }
          }.to raise_source_error message
        end

        [
          [8, 1],
          [16, 1],
          [32, 2],
          [64, 3]
        ].each do |(input_bus_width, address_width)|
          expect {
            create_register_block(bus_width: input_bus_width, address_width:) {}
          }.not_to raise_error

          expect {
            create_register_block(bus_width: 8, address_width:) { bus_width input_bus_width }
          }.not_to raise_error
        end
      end
    end
  end
end
