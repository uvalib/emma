# test/system/sys_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'application_system_test_case'

class SysTest < ApplicationSystemTestCase

  # ===========================================================================
  # :section: Mailer preview tests
  # ===========================================================================

  test 'sys - mailers - account new_org preview' do
    mail_preview(:account, :new_org_email)
  end

  test 'sys - mailers - account new_man preview' do
    mail_preview(:account, :new_man_email)
  end

  test 'sys - mailers - account new_user preview' do
    mail_preview(:account, :new_user_email)
  end

  test 'sys - mailers - devise reset preview' do
    mail_preview(:devise, :reset_password_instructions, format: false)
  end

  test 'sys - mailers - enrollment request preview' do
    mail_preview(:enrollment, :request_email)
  end

  # ===========================================================================
  # :section: Meta tests
  # ===========================================================================

  test 'sys test coverage' do
    # Endpoints covered by controller tests:
    skipped = %i[
      index
      analytics
      database
      disk_space
      environment
      files
      headers
      internals
      jobs
      loggers
      processes
      settings
      var
    ]
    check_system_coverage SysController, except: skipped
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Visit an email preview page.
  #
  # @param [Array] arg
  # @param [Hash]  opt                Passed to #check_mail_preview
  #
  # @return [void]
  #
  def mail_preview(*arg, **opt)
    if !arg.many?
      path  = arg.first.split('/')
      email = path.pop
    elsif arg.first.is_a?(String) && arg.first.include?('/')
      path  = arg.first
      email = arg.second
    else
      path  = arg.first
      path  = "#{path}_mailer" unless path.end_with?('_mailer')
      path  = "rails/mailers/#{path}"
      email = arg.second
    end
    visit path.to_s
    click_on email.to_s
    check_mail_preview(**opt)
  end

  # Validate email preview content.
  #
  # @param [Boolean,Symbol] format    Either *true*, *false*, :html, or :text.
  # @param [Integer]        min_size  Minimum expected message size.
  #
  # @return [void]
  #
  def check_mail_preview(format: true, min_size: 100, **)
    formats = {
      html: 'View as HTML email',
      text: 'View as plain-text email',
    }
    case format
      when false then formats = { nil => nil }
      when :html then formats.delete(:text)
      when :text then formats.delete(:html)
    end
    formats.each_pair do |_format, selection|
      select selection, from: 'part' if selection
      within_frame do
        message = find('body').text
        present = (message.size >= min_size)
        assert present, "Inadequate message content: #{message.inspect}"
      end
    end
  end

end
