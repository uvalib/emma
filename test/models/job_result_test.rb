# test/models/job_result_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'test_helper'

class JobResultTest < ActiveSupport::TestCase

  test 'model - valid job result' do
    run_test(__method__) do
      item = job_results(:example)
      show_item(item)
      assert item.valid?
    end
  end

end
