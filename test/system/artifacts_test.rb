# test/system/artifacts_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'application_system_test_case'

class ArtifactsTest < ApplicationSystemTestCase

  CONTROLLER = :artifact

  # ===========================================================================
  # :section: Read tests
  # ===========================================================================

  test 'artifacts - visit artifact list' do
    run_test(__method__) do
      visit_index CONTROLLER
    end unless not_applicable 'TODO: visit artifact list'
  end

end
