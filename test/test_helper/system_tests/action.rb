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
  # @param [Symbol,String,Class,Model,nil] model
  # @param [Hash]                          opt    Passed to #assert_valid_page.
  #
  # @raise [Minitest::Assertion]
  #
  # @return [true]
  #
  # @note Currently unused
  #
  def assert_valid_create_page(model, **opt)
    assert_valid_action_page(model, :new, **opt)
  end

  # Assert that the current page is for modifying a model instance.
  #
  # @param [Symbol,String,Class,Model,nil] model
  # @param [Hash]                          opt    Passed to #assert_valid_page.
  #
  # @option opt [String] :id          If missing, expect :edit_select.
  #
  # @raise [Minitest::Assertion]
  #
  # @return [true]
  #
  # @note Currently unused
  #
  def assert_valid_update_page(model, **opt)
    action = opt[:id] ? :edit : :edit_select
    assert_valid_action_page(model, action, **opt)
  end

  # Assert that the current page is for removing a model instance.
  #
  # @param [Symbol,String,Class,Model,nil] model
  # @param [Hash]                          opt    Passed to #assert_valid_page.
  #
  # @option opt [String] :id          If missing, expect :delete_select.
  #
  # @raise [Minitest::Assertion]
  #
  # @return [true]
  #
  # @note Currently unused
  #
  def assert_valid_delete_page(model, **opt)
    action = opt[:id] ? :delete : :delete_select
    assert_valid_action_page(model, action, **opt)
  end

  # Assert that the current page is a valid page for the given operation.
  #
  # @param [Symbol,String,Class,Model,nil] model
  # @param [Symbol]                        action
  # @param [Hash]                          opt    Passed to #assert_valid_page.
  #
  # @raise [Minitest::Assertion]
  #
  # @return [true]
  #
  def assert_valid_action_page(model, action, **opt)
    prop = property(model, action)&.slice(:title, :heading)
    opt.reverse_merge!(prop) if prop.present?
    assert_valid_page(**opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Visit the page for creating a new model instance.
  #
  # @param [Symbol,String,Class,Model,nil] model
  # @param [Hash]                          opt
  # @param [Proc]                          block
  #
  # @raise [Minitest::Assertion]
  #
  # @return [true]
  #
  # @note Currently unused
  #
  def visit_new_page(model, **opt, &block)
    visit_action_page(model, :new, **opt, &block)
  end

  # Visit the page for modifying an existing model instance.
  #
  # @param [Symbol,String,Class,Model,nil] model
  # @param [Hash]                          opt
  # @param [Proc]                          block
  #
  # @option opt [String] :id          If missing, visit :edit_select.
  #
  # @raise [Minitest::Assertion]
  #
  # @return [true]
  #
  # @note Currently unused
  #
  def visit_edit_page(model, **opt, &block)
    action = opt[:id] ? :edit : :edit_select
    visit_action_page(model, action, **opt, &block)
  end

  # Visit the page for removing an existing model instance.
  #
  # @param [Symbol,String,Class,Model,nil] model
  # @param [Hash]                          opt
  # @param [Proc]                          block
  #
  # @option opt [String] :id          If missing, visit :delete_select.
  #
  # @raise [Minitest::Assertion]
  #
  # @return [true]
  #
  # @note Currently unused
  #
  def visit_delete_page(model, **opt, &block)
    action = opt[:id] ? :delete : :delete_select
    visit_action_page(model, action, **opt, &block)
  end

  # Visit the page for an action on a model.
  #
  # @param [Symbol,String,Class,Model,nil] model
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
  def visit_action_page(model, action, **opt)
    terms = opt[:terms] || {}
    url   = url_for(controller: model, action: action, **terms)
    visit url
    if block_given?
      yield
    else
      show_url
    end
    if respond_to?((assert = :"assert_valid_#{action}_page"))
      send(assert, model, **opt)
    else
      assert_valid_action_page(model, action, **opt)
    end
  end

end
