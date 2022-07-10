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
  # @param [Symbol] model
  # @param [String] title
  #
  # @return [true]
  #
  # @raise [Minitest::Assertion]
  #
  def assert_valid_show_page(model, title: nil)
    # Remove extra edition information for Bookshare catalog title.
    bs_cat   = (model == :title)
    title  &&= sanitized_string(title)
    title  &&= bs_cat ? title&.sub(/\s*\(.*$/, '') : title
    title  ||= property(model, :show, :title)
    heading  = title ? { text: title } : {}
    body_css = property(model, :show, :body_css)
    assert_selector "body#{body_css}"
    assert_selector property(model, :show, :entry_css)
    assert_title    title             if title
    assert_selector COVER_IMAGE_CLASS if bs_cat
    assert_selector SHOW_HEADING_SELECTOR, **heading
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Visit an entry on an index page.
  #
  # @param [Symbol]                       model
  # @param [Capybara::Node::Element, nil] entry
  # @param [Integer, Symbol]              index
  # @param [String]                       entry_css
  #
  # @return [true]
  #
  # @raise [Minitest::Assertion]
  #
  # @yield Test code to run while on the page.
  # @yieldparam [String] title
  # @yieldreturn [void]
  #
  def visit_show_page(model, entry: nil, index: nil, entry_css: nil)
    entry ||=
      if (entry_css ||= property(model, :index, :entry_css))
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
    assert_valid_show_page(model, title: title)
  end

end
