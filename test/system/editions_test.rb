# test/system/editions_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'application_system_test_case'

class EditionsTest < ApplicationSystemTestCase

  CONTROLLER = :edition

  # ===========================================================================
  # :section: Read tests
  # ===========================================================================

  test 'editions - visit edition list' do
    run_test(__method__) do
      visit_index CONTROLLER
    end unless not_applicable 'TODO: visit edition list'
  end

end
