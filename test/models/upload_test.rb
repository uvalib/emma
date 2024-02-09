# test/models/upload_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'test_helper'

class UploadTest < ActiveSupport::TestCase

  test 'model - valid Upload record' do
    run_test(__method__) do
      item = uploads(:example)
      show_item(item)
      assert item.valid?
    end
  end

end
