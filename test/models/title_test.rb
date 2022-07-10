# test/models/title_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'test_helper'

class TitleTest < ActiveSupport::TestCase

  test 'model - valid title' do
    run_test(__method__) do
      item = sample_title
      show item
      assert item.valid?
    end
  end

  test 'model - add artifacts to title' do
    run_test(__method__) do
      item = sample_title
      item.artifacts << sample_artifact
      item.artifacts.create(format: 'DAISY')
      show item
      assert item.valid?
    end
  end

end
