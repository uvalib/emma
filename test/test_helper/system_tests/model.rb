# test/test_helper/system_tests/model.rb
#
# frozen_string_literal: true
# warn_indent:           true

# Support for checking model values.
#
module TestHelper::SystemTests::Model

  include TestHelper::SystemTests::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Assert that the required number of *model* records meet the *constraints*.
  #
  # @param [any,nil]     model        Symbol,String,Class,Model; def:self_class
  # @param [Integer,nil] total        If given, the current number of records.
  # @param [Integer,nil] expected     If given, the expected number of records.
  # @param [Hash]        constraints  Passed to #get_model_count.
  #
  # @raise [Minitest::Assertion]
  #
  # @return [true]
  #
  def assert_model_count(model = nil, total: nil, expected: nil, **constraints)
    assert (total || expected), 'either :total or :expected must be given'
    total    ||= get_model_count(model, **constraints)
    expected ||= get_model_count(model, **constraints)
    assert (total == expected), "count is #{total} instead of #{expected}"
  end

  # Assert that the required number of *model* records associated with *user*
  # meet the *constraints*.
  #
  # @param [any, nil] model         Symbol,String,Class,Model; def: self_class
  # @param [any, nil] user          Symbol, String, Integer, Hash, Model, User
  # @param [Hash]     constraints   Passed to #assert_model_count.
  #
  # @raise [Minitest::Assertion]
  #
  # @return [true]
  #
  def assert_model_count_for_user(model, user, **constraints)
    constraints.merge!(user_id: user) if (user &&= uid(user))
    assert_model_count(model, **constraints)
  end

  # Assert that the required number of *model* records associated with *org*
  # meet the *constraints*.
  #
  # @param [any, nil] model         Symbol,String,Class,Model; def: self_class
  # @param [any, nil] org           Symbol, String, Integer, Hash, Model, User
  # @param [Hash]     constraints   Passed to #assert_model_count.
  #
  # @raise [Minitest::Assertion]
  #
  # @return [true]
  #
  # @note Currently unused.
  # :nocov:
  def assert_model_count_for_org(model, org, **constraints)
    constraints.merge!(org_id: org) if (org &&= oid(org))
    assert_model_count(model, **constraints)
  end
  # :nocov:

end
