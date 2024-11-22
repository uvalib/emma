# test/models/job_result_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'application_model_test_case'

class JobResultTest < ApplicationModelTestCase

  test 'model - valid job result' do
    run_test(__method__) do
      item = job_results(:example)
      show_item(item)
      assert item.valid?
    end
  end

end
