# test/controllers/category_controller_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'test_helper'

class CategoryControllerTest < ActionDispatch::IntegrationTest

  CONTROLLER   = :category
  PARAMS       = { controller: CONTROLLER }.freeze
  OPTIONS      = { controller: CONTROLLER, expect: :success }.freeze

  TEST_USERS   = %i[anonymous emmadso].freeze
  TEST_READERS = TEST_USERS

  READ_FORMATS = :all

  setup do
    @readers = find_users(*TEST_READERS)
  end

  # ===========================================================================
  # :section: Read tests
  # ===========================================================================

  test 'category index - list all categories' do
    action  = :index
    params  = PARAMS.merge(action: action)
    options = OPTIONS.merge(action: action, test: __method__)
    @readers.each do |user|
      u_opt = options
      TEST_FORMATS.each do |fmt|
        url = url_for(**params, format: fmt)
        opt = u_opt.merge(format: fmt)
        get_as(user, url, **opt, only: READ_FORMATS)
      end
    end
  end

end
