# test/application_mailer_test_case.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'test_helper'

# Common base for mailer tests.
#
class ApplicationMailerTestCase < ActionMailer::TestCase

  # Verify that the given email is queued and is well-formed.
  #
  # @param [Symbol]             type
  # @param [Mail::Message, nil] email
  # @param [Hash]               opt
  #
  # @option opt [String, Array<String>] :to     Required.
  # @option opt [String, Array<String>] :from   Required.
  #
  # @return [void]
  #
  def validate_email(type, email = nil, **opt)
    %i[to from].each { |k| assert opt[k], "Test did not provide :#{k}" }
    email ||= yield
    if email.processed?
      assert_emails(1)
    else
      assert_emails(1) { email.deliver_later }
    end
    conf = I18n.t("emma.mail.#{type}", default: {})
    check_email(email, **conf.slice(:subject, :heading), **opt)
  end

  # Verify that *email* is well-formed.
  #
  # @param [Mail::Message] email
  # @param [Hash]          opt
  #
  # @return [void]
  #
  def check_email(email, **opt)
    to   = Array.wrap(opt[:to])
    from = Array.wrap(opt[:from])
    subj = opt[:subject]
    head = opt[:heading]
    body = opt[:body] || email.body&.encoded
    show_item { "to   = #{email.to.inspect}" }
    show_item { "from = #{email.from.inspect}" }
    show_item { "subj = #{email.subject.inspect}" }
    show_item { 'body = %s' % body.inspect.gsub('\r\n', "\n") }
    assert_equal to,   email.to,      'invalid email.to'
    assert_equal from, email.from,    'invalid email.from'
    assert_match subj, email.subject, 'invalid email.subject'
    assert_match head, body,          'invalid email.body'
  end

end
