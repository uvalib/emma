# test/test_helper/system_tests/action.rb
#
# frozen_string_literal: true
# warn_indent:           true

# Support for checking CRUD operation pages.
#
module TestHelper::SystemTests::Action

  include TestHelper::SystemTests::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Assert that the current page is for creating a model instance.
  #
  # @param [Symbol,String,Class,Model,nil] ctrlr
  # @param [Hash]                          opt    Passed to #assert_valid_page.
  #
  # @raise [Minitest::Assertion]
  #
  # @return [true]
  #
  # @note Currently unused.
  #
  def assert_valid_create_page(ctrlr, **opt)
    assert_valid_action_page(ctrlr, :new, **opt)
  end

  # Assert that the current page is for modifying a model instance.
  #
  # @param [Symbol,String,Class,Model,nil] ctrlr
  # @param [Hash]                          opt    Passed to #assert_valid_page.
  #
  # @option opt [String] :id          If missing, expect :edit_select.
  #
  # @raise [Minitest::Assertion]
  #
  # @return [true]
  #
  # @note Currently unused.
  #
  def assert_valid_update_page(ctrlr, **opt)
    action = opt[:id] ? :edit : :edit_select
    assert_valid_action_page(ctrlr, action, **opt)
  end

  # Assert that the current page is for removing a model instance.
  #
  # @param [Symbol,String,Class,Model,nil] ctrlr
  # @param [Hash]                          opt    Passed to #assert_valid_page.
  #
  # @option opt [String] :id          If missing, expect :delete_select.
  #
  # @raise [Minitest::Assertion]
  #
  # @return [true]
  #
  # @note Currently unused.
  #
  def assert_valid_delete_page(ctrlr, **opt)
    action = opt[:id] ? :delete : :delete_select
    assert_valid_action_page(ctrlr, action, **opt)
  end

  # Assert that the current page is a valid page for the given operation.
  #
  # @param [Symbol,String,Class,Model,nil] ctrlr
  # @param [Symbol]                        action
  # @param [Hash]                          opt    Passed to #assert_valid_page.
  #
  # @raise [Minitest::Assertion]
  #
  # @return [true]
  #
  def assert_valid_action_page(ctrlr, action, **opt)
    prop = property(ctrlr, action)&.slice(:title, :heading)
    opt.reverse_merge!(prop) if prop.is_a?(Hash)
    assert_valid_page(**opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Visit the page for creating a new model instance.
  #
  # @param [Symbol,String,Class,Model,nil] ctrlr
  # @param [Hash]                          opt
  # @param [Proc]                          blk
  #
  # @raise [Minitest::Assertion]
  #
  # @return [true]
  #
  # @note Currently unused.
  #
  def visit_new_page(ctrlr, **opt, &blk)
    visit_action_page(ctrlr, :new, **opt, &blk)
  end

  # Visit the page for modifying an existing model instance.
  #
  # @param [Symbol,String,Class,Model,nil] ctrlr
  # @param [Hash]                          opt
  # @param [Proc]                          blk
  #
  # @option opt [String] :id          If missing, visit :edit_select.
  #
  # @raise [Minitest::Assertion]
  #
  # @return [true]
  #
  # @note Currently unused.
  #
  def visit_edit_page(ctrlr, **opt, &blk)
    action = opt[:id] ? :edit : :edit_select
    visit_action_page(ctrlr, action, **opt, &blk)
  end

  # Visit the page for removing an existing model instance.
  #
  # @param [Symbol,String,Class,Model,nil] ctrlr
  # @param [Hash]                          opt
  # @param [Proc]                          blk
  #
  # @option opt [String] :id          If missing, visit :delete_select.
  #
  # @raise [Minitest::Assertion]
  #
  # @return [true]
  #
  # @note Currently unused.
  #
  def visit_delete_page(ctrlr, **opt, &blk)
    action = opt[:id] ? :delete : :delete_select
    visit_action_page(ctrlr, action, **opt, &blk)
  end

  # Visit the page for an action on a model.
  #
  # @param [Symbol,String,Class,Model,nil] ctrlr
  # @param [Symbol]                        action
  # @param [Hash]                          opt    To #assert_valid_action_page.
  #
  # @raise [Minitest::Assertion]
  #
  # @return [true]
  #
  # @yield Test code to run while on the page.
  # @yieldreturn [void]
  #
  # @note Currently unused.
  # :nocov:
  def visit_action_page(ctrlr, action, **opt)
    ctrlr = controller_name(ctrlr)
    terms = opt[:terms] || {}
    url   = url_for(controller: ctrlr, action: action, **terms)
    visit url
    if block_given?
      yield
    else
      show_url
    end
    if respond_to?((assert = :"assert_valid_#{action}_page"))
      send(assert, ctrlr, **opt)
    else
      assert_valid_action_page(ctrlr, action, **opt)
    end
  end
  # :nocov:

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Click on a page action menu button.
  #
  # @param [String]           locator   Action button to click.
  # @param [Array,String,nil] wait_for  URL(s) expected to result.
  # @param [Hash]             opt       Passed to #click_on.
  #
  # @return [void]
  #
  def select_action(locator, wait_for: nil, **opt)
    show_item { '%s...' % (locator.presence || opt.inspect) }
    opt[:match] = :first unless opt.key?(:match)
    opt[:exact] = true   unless opt.key?(:exact) || locator.blank?
    click_on locator, **opt
    wait_for_page(wait_for) if wait_for
  end

  # Assert that the page has an action button.
  #
  # @param [String] locator           Action button label.
  # @param [Hash]   opt               Passed to #click_on.
  #
  # @return [void]
  #
  # @note Currently unused.
  # :nocov:
  def assert_action(locator, **opt)
    opt[:match] = :first unless opt.key?(:match)
    opt[:exact] = true   unless opt.key?(:exact) || locator.blank?
    assert has_selector?(:link_or_button, locator, **opt), -> {
      name   = locator.presence
      button = name ? "#{name} button" : "button with #{opt.inspect}"
      found  = find(:link_or_button, locator, **opt)
      label  = found&.text
      label  = "#{label.inspect} in #{found.inspect}"
      "Expected no #{button} for this user; found #{label.inspect}"
    }
  end
  # :nocov:

  # Assert that the page does not have an action button.
  #
  # @param [String] locator           Action button label.
  # @param [Hash]   opt               Passed to #click_on.
  #
  # @return [void]
  #
  # @note Currently unused.
  # :nocov:
  def assert_no_action(locator, **opt)
    opt[:match] = :first unless opt.key?(:match)
    opt[:exact] = true   unless opt.key?(:exact) || locator.blank?
    assert has_no_selector?(:link_or_button, locator, **opt), -> {
      name   = locator.presence
      button = name ? "#{name} button" : "button with #{opt.inspect}"
      found  = find(:link_or_button, locator, **opt)
      label  = found&.text
      label  = "#{label.inspect} in #{found.inspect}"
      "Expected no #{button} for this user; found #{label.inspect}"
    }
  end
  # :nocov:

end
