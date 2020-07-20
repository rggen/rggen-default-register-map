# frozen_string_literal: true

RSpec.describe 'bit_field/comment' do
  include_context 'clean-up builder'
  include_context 'register map common'

  before(:all) do
    RgGen.enable(:bit_field, :comment)
  end

  def create_bit_field(&block)
    create_register_map { register_block { register { bit_field(&block) } } }.bit_fields.first
  end

  describe '#comment' do
    it '入力されたコメントを返す' do
      bit_field = create_bit_field { comment :foo }
      expect(bit_field).to have_property(:comment, 'foo')

      bit_field = create_bit_field { comment 'foo' }
      expect(bit_field).to have_property(:comment, 'foo')

      bit_field = create_bit_field { comment "foo\nbar\nbaz" }
      expect(bit_field).to have_property(:comment, "foo\nbar\nbaz")

      bit_field = create_bit_field { comment ['foo', 'bar', 'baz'] }
      expect(bit_field).to have_property(:comment, "foo\nbar\nbaz")
    end

    it '末尾の空白は削除される' do
      bit_field = create_bit_field { comment 'foo  ' }
      expect(bit_field).to have_property(:comment, 'foo')

      bit_field = create_bit_field { comment "foo\nbar\nbaz\n  " }
      expect(bit_field).to have_property(:comment, "foo\nbar\nbaz")

      bit_field = create_bit_field { comment '  ' }
      expect(bit_field).to have_property(:comment, '')
    end

    context 'コメントが未入力の場合' do
      it '空文字を返す' do
        bit_field = create_bit_field {}
        expect(bit_field).to have_property(:comment, '')

        bit_field = create_bit_field { comment nil }
        expect(bit_field).to have_property(:comment, '')
      end
    end
  end

  describe '#printables[:comment]' do
    context 'コメントが入力された場合' do
      it '入力されたコメントを表示可能オブジェクトとして返す' do
        bit_field = create_bit_field { comment "foo\nbar\nbaz" }
        expect(bit_field.printables[:comment]).to eq "foo\nbar\nbaz"
      end
    end

    context '#commentが空文字を返す場合' do
      it 'nilを返す' do
        bit_field = create_bit_field {}
        expect(bit_field.printables[:comment]).to be_nil

        bit_field = create_bit_field { comment '' }
        expect(bit_field.printables[:comment]).to be_nil

        bit_field = create_bit_field { comment '  ' }
        expect(bit_field.printables[:comment]).to be_nil
      end
    end
  end
end
