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
  # @return [void]
  #
  def assert_valid_show_page(model, title: nil)
    body_class = PROPERTY.dig(model, :show, :body_class)
    assert_selector "body#{body_class}"

    content_class = PROPERTY.dig(model, :show, :content_class)
    assert_selector content_class

    title ||= PROPERTY.dig(model, :show, :title)
    if title.present?
      # Remove extra edition information for catalog title.
      title = title.sub(/\s*\(.*$/, '') if model == :title
      assert_title    "#{title} |"
      assert_selector SHOW_HEADING_SELECTOR, text: title
    else
      assert_selector SHOW_HEADING_SELECTOR
    end

    assert_selector COVER_IMAGE_CLASS if model == :title
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
  # @param [String]                       entry_class
  #
  # @return [void]
  #
  # @yield Test code to run while on the page.
  # @yieldreturn [void]
  #
  def visit_show_page(model, entry: nil, index: nil, entry_class: nil)
    entry ||=
      if (entry_class ||= PROPERTY.dig(model, :index, :entry_class))
        case index
          when Integer then all(entry_class).at(index)
          when :last   then all(entry_class).last
          else              find(entry_class, match: :first)
        end
      end
    link  = entry&.find('.value.field-Title a')
    title = link&.text || 'NO TITLE'
    link&.click(wait: true)
    if block_given?
      yield(title)
    else
      show_url
    end
    assert_valid_show_page(model, title: title)
  end

end
