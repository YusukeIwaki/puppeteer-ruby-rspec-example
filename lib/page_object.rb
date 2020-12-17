class PageObject
  # @param root [Page|Frame|ElementHandle]
  def initialize(root)
    @root = root
  end

  class FuzzyTextFinder
    # @param root [Page|Frame|ElementHandle]
    # @param text [String]
    def initialize(root, text)
      @root = root
      @text = text
    end

    # @returns [ElementHandle]
    def find
      find_by_exact_text || find_by_fuzzy_text
    end

    private

    def find_by_exact_text
      @root.Sx(".//*[text() = '#{@text}']").first
    end

    def find_by_fuzzy_text
      @root.Sx(".//*[contains(text(), '#{@text}')]").find do |el|
        el.evaluate('(el) => el.textContent.trim()') == @text
      end
    end
  end

  module ClassMethods
    # define_memoized_method :hoge do
    #   something
    # end
    #
    # defines a method below:
    #
    # def hoge
    #   @hoge ||= something
    # end
    def define_memoized_method(name, &block)
      define_method(name) do
        value = instance_variable_get(:"@#{name}")
        unless value
          value = instance_eval(&block)
          instance_variable_set(:"@#{name}", value)
        end
        value
      end
    end

    # define element accessor
    #
    # `element :hoge, "#something"` defines
    #
    #  def hoge
    #    @hoge ||= @root.S("#something")
    #  end
    #
    def element(name, locator)
      define_memoized_method(name) do
        @root.S(locator)
      end
    end

    # define element finder using XPath (text() = xxx)
    #
    # `element_with_text :hoge, "Setting"` defines
    #
    #  def hoge
    #    @hoge ||= @root.Sx("//*[text() = 'Setting']").first
    #  end
    #
    def element_with_text(name, text)
      define_memoized_method(name) do
        ::PageObject::FuzzyTextFinder.new(@root, text).find
      end
    end

    # define element array accessor
    #
    # `elements :hoges, "#something"` defines
    #
    #  def hoges
    #    @hoges ||= @root.SS("#something")
    #  end
    #
    def elements(name, locator)
      define_memoized_method(name) do
        @root.SS(locator)
      end
    end

    # define nested PageObject.
    #
    # example:
    # ----------
    # class SomePage < PageObject
    #   fragment :side_bar, SideBar, "#sidebar"
    #   fragment :main_content, MainContent, "#main-container"
    #
    def fragment(name, page_object_class, locator)
      define_memoized_method(name) do
        page_object_class.new(@root.S(locator))
      end
    end

    # define nested PageObject.
    #
    # example:
    # ----------
    # class SomeList < PageObject
    #   fragments :items, SomeListItem, ".list-item"
    #
    def fragments(name, page_object_class, locator)
      define_memoized_method(name) do
        page_object_class.new(@root.SS(locator))
      end
    end
  end
  self.extend ClassMethods
end
