require 'spec_helper'

RSpec.describe PageObject do
  describe 'define_memoized_method' do
    it 'can define public method' do
      klass = Class.new(PageObject) do
        def initialize
          @count = 0
        end

        # ブロックが評価されるたびにカウントアップされるが、
        # memoizeされているので、ブロックは最初の１回だけ評価されて常に１が返されるのが期待値のメソッド。
        define_memoized_method(:memo_count) do
          @count += 1
        end
      end
      instance = klass.new

      expect(instance.memo_count).to eq(1) # 初回はカウントアップされて1
      expect(instance.memo_count).to eq(1) # 2回呼んでも1
    end

    it 'can define private method' do
      klass = Class.new(PageObject) do
        def initialize
          @default_value = 123
        end

        define_memoized_method(:memo_count) do
          @default_value
        end
        private :memo_count
      end
      instance = klass.new

      expect{ instance.memo_count }.to raise_error(NoMethodError)
      expect(instance.send(:memo_count)).to eq(123)
    end
  end

  describe 'element_with_text' do
    prepare_page do
      <<~HTML
      <html>
        <body>
          <li>foo</li>
          <li> bar<span>
          </span></li>
          <p><i>foo</i></p>
        </body>
      </html>
      HTML
    end

    it 'can pick an first element with text' do
      klass = Class.new(PageObject) do
        element_with_text :el_foo, "foo"
      end
      page_obj = klass.new(page)

      expect(page_obj.el_foo.evaluate('(el) => el.outerHTML')).to eq('<li>foo</li>')
    end

    it 'can pick an element with text surrounding blank spaces' do
      klass = Class.new(PageObject) do
        element_with_text :el_bar, "bar"
      end
      page_obj = klass.new(page)

      expect(page_obj.el_bar.evaluate('(el) => el.outerHTML')).to eq("<li> bar<span>\n    </span></li>")
    end

    it 'doesnt pick elements outside root element' do
      klass = Class.new(PageObject) do
        element_with_text :el_foo, "foo"
      end
      page_obj = klass.new(page.S("p"))

      expect(page_obj.el_foo.evaluate('(el) => el.outerHTML')).to eq('<i>foo</i>')
    end
  end
end
