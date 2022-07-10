# test/models/periodical_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'test_helper'

class PeriodicalTest < ActiveSupport::TestCase

  test 'model - valid periodical' do
    run_test(__method__) do
      item = sample_periodical
      show item
      assert item.valid?
    end
  end

  test 'model - add edition to periodical' do
    run_test(__method__) do
      item = sample_periodical
      item.editions << sample_edition
      show item
      assert item.valid?
    end
  end

end
