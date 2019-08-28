# frozen_string_literal: true

RSpec.describe RgGen::DefaultRegisterMap do
  include_context 'clean-up builder'

  let(:builder) { RgGen.builder }

  describe '.default_setup' do
    it '.load_featuresを呼び出す' do
      expect(RgGen::DefaultRegisterMap).to receive(:load_features).and_call_original
      RgGen::DefaultRegisterMap.default_setup(builder)
    end
  end

  describe '既定セットアップ' do
    it 'フィーチャーの読み出しと有効化を行う' do
      expect(RgGen::DefaultRegisterMap).to receive(:load_features).and_call_original
      expect(builder).to receive(:enable).with(:global, [:bus_width, :address_width]).and_call_original
      expect(builder).to receive(:enable).with(:register_block, [:name, :byte_size]).and_call_original
      expect(builder).to receive(:enable).with(:register, [:name, :offset_address, :size, :type]).and_call_original
      expect(builder).to receive(:enable).with(:register, :type, [:external, :indirect]).and_call_original
      expect(builder).to receive(:enable).with(:bit_field, [:name, :bit_assignment, :type, :initial_value, :reference, :comment]).and_call_original
      expect(builder).to receive(:enable).with(:bit_field, :type, [:rc, :reserved, :ro, :rof, :rs, :rw, :rwc, :rwe, :rwl, :w0c, :w0s, :w0trg, :w1c, :w1s, :w1trg, :wo]).and_call_original
      require 'rggen/default_register_map/setup'
      builder.activate_plugins
    end
  end
end
