# frozen_string_literal: true

RSpec.describe 'register_file/comment' do
  include_context 'clean-up builder'
  include_context 'register map common'

  before(:all) do
    RgGen.enable(:register_file, :comment)
  end

  def create_register_file(&block)
    create_register_map { register_block { register_file(&block) } }.register_files.first
  end

  describe '#comment' do
    it '入力されたコメントを返す' do
      register_file = create_register_file { comment :foo }
      expect(register_file).to have_property(:comment, 'foo')

      register_file = create_register_file { comment 'foo' }
      expect(register_file).to have_property(:comment, 'foo')

      register_file = create_register_file { comment "foo\nbar\nbaz" }
      expect(register_file).to have_property(:comment, "foo\nbar\nbaz")

      register_file = create_register_file { comment ['foo', 'bar', 'baz'] }
      expect(register_file).to have_property(:comment, "foo\nbar\nbaz")
    end

    it '末尾の空白は削除される' do
      register_file = create_register_file { comment 'foo  ' }
      expect(register_file).to have_property(:comment, 'foo')

      register_file = create_register_file { comment "foo\nbar\nbaz\n  " }
      expect(register_file).to have_property(:comment, "foo\nbar\nbaz")

      register_file = create_register_file { comment '  ' }
      expect(register_file).to have_property(:comment, '')
    end

    context 'コメントが未入力の場合' do
      it '空文字を返す' do
        register_file = create_register_file {}
        expect(register_file).to have_property(:comment, '')

        register_file = create_register_file { comment nil }
        expect(register_file).to have_property(:comment, '')
      end
    end
  end

  describe '#printables[:comment]' do
    context 'コメントが入力された場合' do
      it '入力されたコメントを表示可能オブジェクトとして返す' do
        register_file = create_register_file { comment "foo\nbar\nbaz" }
        expect(register_file.printables[:comment]).to eq "foo\nbar\nbaz"
      end
    end

    context '#commentが空文字を返す場合' do
      it 'nilを返す' do
        register_file = create_register_file {}
        expect(register_file.printables[:comment]).to be_nil

        register_file = create_register_file { comment '' }
        expect(register_file.printables[:comment]).to be_nil

        register_file = create_register_file { comment '  ' }
        expect(register_file.printables[:comment]).to be_nil
      end
    end
  end
end
