# test/test_helper/integration_tests/format.rb
#
# frozen_string_literal: true
# warn_indent:           true

# Support for sign-in.
#
module TestHelper::IntegrationTests::Format

  # Table of formats and associated MIME media types.
  #
  # @type [Hash{Symbol=>String}]
  #
  MEDIA_TYPE = {
    html: 'text/html',
    json: 'application/json',
    text: 'text/plain',
    xml:  'application/xml',
  }.freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether *type* matches the given *format*.
  #
  # @param [Symbol, String] type
  # @param [Symbol]         format
  #
  def format?(type, format)
    type = type.to_sym if type.is_a?(String) && !type.include?('/')
    (type == format) || (type == MEDIA_TYPE[format])
  end

  # Indicate whether *type* is HTML.
  #
  # @param [Symbol, String] type
  #
  def html?(type)
    format?(type, :html)
  end

  # Indicate whether *type* is JSON.
  #
  # @param [Symbol, String] type
  #
  def json?(type)
    format?(type, :json)
  end

  # Indicate whether *type* is XML.
  #
  # @param [Symbol, String] type
  #
  def xml?(type)
    format?(type, :xml)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Assert that the response is 'text/html'.
  #
  # @param [Symbol] status
  # @param [Hash]   opt               Passed to #assert_result.
  #
  # @see #assert_result
  #
  def assert_html_result(status, **opt)
    opt[:format] = :html unless opt.key?(:format)
    assert_result(status, **opt)
  end

  # Assert that the response is 'application/json'.
  #
  # @param [Symbol] status
  # @param [Hash]   opt               Passed to #assert_result.
  #
  # @see #assert_result
  #
  def assert_json_result(status, **opt)
    opt[:format] = :json unless opt.key?(:format)
    assert_result(status, **opt)
  end

  # Assert that the response is 'application/xml'.
  #
  # @param [Symbol] status
  # @param [Hash]   opt               Passed to #assert_result.
  #
  # @see #assert_result
  #
  def assert_xml_result(status, **opt)
    opt[:format] = :xml unless opt.key?(:format)
    assert_result(status, **opt)
  end

  # Assert that the response is 'text/plain'.
  #
  # @param [Symbol] status
  # @param [Hash]   opt               Passed to #assert_result.
  #
  # @see #assert_result
  #
  def assert_text_result(status, **opt)
    opt[:format] = :text unless opt.key?(:format)
    assert_result(status, **opt)
  end

  # Assert that the response matches the given criteria.
  #
  # @param [Symbol, nil] status       Status :any is treated the same as *nil*.
  # @param [Hash]        opt
  #
  # @option opt [String]        :from
  # @option opt [String,Symbol] :controller
  # @option opt [String,Symbol] :action
  # @option opt [String,Symbol] :format
  # @option opt [String,Symbol] :media_type   If present, trumps :format.
  #
  # @raise [Minitest::Assertion]      If one or more criteria don't match.
  #
  # @return [void]                    If all criteria match.
  #
  def assert_result(status, **opt)

    assert_response status if status && (status != :any)

    action, controller = (opt[:from].split('#').reverse if opt[:from])
    controller = opt[:controller]&.to_s || controller
    action     = opt[:action]&.to_s     || action
    media_type = opt.key?(:media_type) ? opt[:media_type] : opt[:format]
    media_type = MEDIA_TYPE[media_type] if media_type.is_a?(Symbol)

    assert_equal controller, @controller.controller_path if controller.present?
    assert_equal action,     @controller.action_name     if action.present?
    assert_equal media_type, @response.media_type        if media_type.present?

  end

end
