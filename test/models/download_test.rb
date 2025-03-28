# test/models/download_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'application_model_test_case'

class DownloadTest < ApplicationModelTestCase

  test 'download - valid download event' do
    run_test(__method__) do
      item = downloads(:example)
      show_item(item)
      assert item.valid?
    end
  end

end
