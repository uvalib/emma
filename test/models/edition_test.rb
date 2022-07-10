# test/models/edition_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'test_helper'

class EditionTest < ActiveSupport::TestCase

  test 'model - valid periodical edition' do
    run_test(__method__) do
      item = sample_edition
      show item
      assert item.valid?
    end
  end

  test 'model - add artifact to edition' do
    run_test(__method__) do
      item = sample_edition
      item.artifacts.create(format: 'DAISY')
      show item
      assert item.valid?
    end
  end

end
