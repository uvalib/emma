# test/test_helper/system_tests/form.rb
#
# frozen_string_literal: true
# warn_indent:           true

# Support create/update forms.
#
module TestHelper::SystemTests::Form

  include TestHelper::SystemTests::Common
  include TestHelper::SystemTests::Flash

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Choose an item from a form menu.
  #
  # @param [String]           item
  # @param [Array,String,nil] wait_for  URL(s) expected to result.
  # @param [Hash]             opt       Passed to #item_menu_select.
  #
  # @return [void]
  #
  def select_item(item, wait_for: nil, **opt)
    show_item { "Select item #{item.inspect}..." }
    item_menu_select(item, name: 'id', **opt)
    wait_for_page(wait_for) if wait_for
  end

  # Click on the form submit button after setting up a screenshot to show
  # invalid field(s) if the submit fails.
  #
  # @param [String, nil] label
  # @param [Hash]        opt          Passed to #click_on.
  #
  # @return [Capybara::Node::Element] The element clicked.
  #
  def form_submit(label: nil, **opt)
    # Take screenshot of the fields before submitting.
    screenshot

    # At this point, a flash message would only be present if there was an
    # issue that would prevent completion of the form submission.
    flunk 'Failed with flash error message' if flash?

    # Take a screenshot showing problematic fields (which also avoids the
    # debounce delay to ensure that the submit button is enabled).
    if (filter = all('#field-group_invalid').first)
      filter.click
      screenshot
    end

    # If all required fields have been filled then submit will be visible.
    click_on label, class: 'submit-button', match: :first, exact: true, **opt
  end

end
