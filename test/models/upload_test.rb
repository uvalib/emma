# test/models/upload_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'application_model_test_case'

class UploadTest < ApplicationModelTestCase

  test 'model - valid Upload record' do
    run_test(__method__) do
      item = uploads(:example)
      show_item(item)
      assert item.valid?
    end
  end

end
