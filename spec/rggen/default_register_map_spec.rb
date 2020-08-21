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
      expect(builder).to receive(:enable).with(:register_block, [:name, :byte_size, :comment]).and_call_original
      expect(builder).to receive(:enable).with(:register_file, [:name, :offset_address, :size, :comment]).and_call_original
      expect(builder).to receive(:enable).with(:register, [:name, :offset_address, :size, :type, :comment]).and_call_original
      expect(builder).to receive(:enable).with(:register, :type, [:external, :indirect]).and_call_original
      expect(builder).to receive(:enable).with(:bit_field, [:name, :bit_assignment, :type, :initial_value, :reference, :comment]).and_call_original
      expect(builder).to receive(:enable).with(:bit_field, :type, [
        :rc, :reserved, :ro, :rof, :rs, :rw, :rwc, :rwe, :rwl, :rws,
        :w0c, :w0crs, :w0s, :w0src, :w0t, :w0trg, :w1, :w1c, :w1crs, :w1s, :w1src, :w1t, :w1trg,
        :wo, :wo1, :woc, :wos, :wc, :wcrs, :wrc, :wrs, :ws, :wsrc]
      ).and_call_original
      builder.load_plugins(['rggen/default_register_map/setup'], true)
    end
  end
end
