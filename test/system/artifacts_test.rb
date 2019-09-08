# test/system/artifacts_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'application_system_test_case'

class ArtifactsTest < ApplicationSystemTestCase

=begin
  test 'artifacts - visit artifact list' do
    run_test(__method__) do
      visit artifact_index_path
      show_url
      assert_valid_index_page(:artifact)
    end
  end
=end

end
