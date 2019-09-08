# test/models/artifact_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'test_helper'

class ArtifactTest < ActiveSupport::TestCase

  test 'valid artifact' do
    run_test(__method__) do
      item = sample_artifact
      show item
      assert item.valid?
    end
  end

end
