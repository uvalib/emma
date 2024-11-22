# test/test_helper/system_tests/show.rb
#
# frozen_string_literal: true
# warn_indent:           true

# Support for item details pages.
#
module TestHelper::SystemTests::Show

  include TestHelper::SystemTests::Common

  SHOW_HEADING_CLASS    = '.heading'
  SHOW_HEADING_SELECTOR = "h1#{SHOW_HEADING_CLASS}"
  COVER_IMAGE_CLASS     = '.cover-image'

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Assert that the current page is a valid index page.
  #
  # @param [Symbol,String,Class,Model,nil] ctrlr
  # @param [String]                        title
  #
  # @raise [Minitest::Assertion]
  #
  # @return [true]
  #
  # @note Currently unused.
  #
  def assert_valid_show_page(ctrlr, title: nil)
    ctrlr    = controller_name(ctrlr)
    title    = title ? sanitized_string(title) : property(ctrlr, :show, :title)
    heading  = title ? { text: title } : {}
    body_css = property(ctrlr, :show, :body_css)
    assert_selector "body#{body_css}"
    assert_selector property(ctrlr, :show, :entry_css)
    assert_selector SHOW_HEADING_SELECTOR, **heading
    assert_title title if title
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Visit an entry on an index page.
  #
  # @param [Symbol,String,Class,Model,nil] ctrlr
  # @param [Capybara::Node::Element, nil]  entry
  # @param [Integer, Symbol]               index
  # @param [String]                        entry_css
  #
  # @raise [Minitest::Assertion]
  #
  # @return [true]
  #
  # @yield Test code to run while on the page.
  # @yieldparam [String] title
  # @yieldreturn [void]
  #
  # @note Currently unused.
  #
  def visit_show_page(ctrlr, entry: nil, index: nil, entry_css: nil)
    ctrlr = controller_name(ctrlr)
    entry ||=
      if (entry_css ||= property(ctrlr, :index, :entry_css))
        case index
          when Integer then all(entry_css).at(index)
          when :last   then all(entry_css).last
          else              find(entry_css, match: :first)
        end
      end
    link  = entry&.find('.value.field-Title a')
    title = link&.text&.html_safe || 'NO TITLE'
    link&.click
    if block_given?
      yield(title)
    else
      show_url
    end
    assert_valid_show_page(ctrlr, title: title)
  end

end
