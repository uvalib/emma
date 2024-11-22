# test/system/help_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'application_system_test_case'

class HelpTest < ApplicationSystemTestCase

  # ===========================================================================
  # :section: Read tests
  # ===========================================================================

  test 'help - show - search help' do
    help_test(:search)
  end

  test 'help - show - download help' do
    help_test(:download)
  end

  test 'help - show - upload help' do
    help_test(:upload)
  end

  test 'help - show - manifest help' do
    help_test(:manifest)
  end

  test 'help - show - account help' do
    help_test(:account)
  end

  test 'help - show - organization help' do
    help_test(:organization)
  end

  test 'help - show - enrollment help' do
    help_test(:enrollment)
  end

  # ===========================================================================
  # :section: Meta tests
  # ===========================================================================

  test 'help system test coverage' do
    # Endpoints covered by controller tests:
    skipped = %i[index]
    check_system_coverage HelpController, prefix: 'help', except: skipped
  end

  # ===========================================================================
  # :section: Methods
  # ===========================================================================

  # Perform a test to display a help topic.
  #
  # @param [Symbol, String] id
  # @param [String, nil]    topic
  #
  # @return [void]
  #
  def help_test(id, topic: nil)
    topic ||= I18n.t("emma.help.topic.#{id}.Topic", default: nil)
    topic ||= id.to_s.capitalize
    heading = I18n.t('emma.help.topic._template.label', Topic: topic)
    run_test(__method__) do
      visit help_url(id: id)
      screenshot
      assert_equal heading, find('h1').text, 'invalid heading'
    end
  end

end
