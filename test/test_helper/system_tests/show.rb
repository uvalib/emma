# test/test_helper/system_tests/show.rb
#
# frozen_string_literal: true
# warn_indent:           true

#require_relative '_common'

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
  # @param [Symbol,nil] model
  # @param [String]     title
  #
  def assert_valid_show_page(model = nil, title: nil)
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
  # @param [Symbol, nil]                  model
  # @param [Capybara::Node::Element, nil] entry
  # @param [Integer, Symbol]              index
  # @param [String]                       entry_class
  #
  # @return [String] title            Title for the entry.
  #
  def visit_show_page(model = nil, entry: nil, index: nil, entry_class: nil)
    entry ||=
      if (entry_class ||= PROPERTY.dig(model, :index, :entry_class))
        case index
          when Integer then all(entry_class).at(index)
          when :last   then all(entry_class).last
          else              find(entry_class, match: :first)
        end
      end
    link  = entry.find('.value.field-Title a')
    title = link.text
    link.click(wait: true)
    #show_url
    assert_valid_show_page(model, title: title)
    title
  end

end
