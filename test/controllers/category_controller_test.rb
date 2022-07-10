# test/controllers/category_controller_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'test_helper'

class CategoryControllerTest < ActionDispatch::IntegrationTest

  CONTROLLER   = :category
  OPTIONS      = { controller: CONTROLLER }.freeze

  TEST_USERS   = %i[anonymous emmadso].freeze
  TEST_READERS = TEST_USERS

  # noinspection RbsMissingTypeSignature
  setup do
    @readers = find_users(*TEST_READERS)
  end

  # ===========================================================================
  # :section: Read tests
  # ===========================================================================

  test 'category index - list all categories' do
    action  = :index
    options = OPTIONS.merge(action: action, test: __method__, expect: :success)
    @readers.each do |user|
      TEST_FORMATS.each do |fmt|
        url = category_index_url(format: fmt)
        opt = options.merge(format: fmt)
        get_as(user, url, **opt)
      end
    end
  end

end
