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

  # Click on the form submit button after setting up a screenshot to show
  # invalid field(s) if the submit fails.
  #
  # @param [String, nil] label
  # @param [Hash]        opt          Passed to #click_on.
  #
  # @return [Capybara::Node::Element] The element clicked.
  #
  def form_submit(label = nil, **opt)
    # At this point, a flash message would only be present if there was an
    # issue that would prevent completion of the form submission.
    if flash?
      screenshot
      flunk 'Failed with flash error message'
    end

    # Take a screenshot showing problematic fields (which also avoids the
    # debounce delay to ensure that the submit button is enabled).
    find(:radio_button, id: 'field-group_invalid').click
    screenshot

    # If all required fields have been filled then submit will be visible.
    click_on label, class: 'submit-button', match: :first, exact: true, **opt
  end

end
