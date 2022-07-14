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
  # @param [Symbol, String, nil] type
  # @param [Symbol]              format
  #
  def format?(type, format)
    # noinspection RubyNilAnalysis
    type = type.to_sym if type.is_a?(String) && !type.include?('/')
    (type == format) || (type == MEDIA_TYPE[format])
  end

  # Indicate whether *type* is HTML.
  #
  # @param [Symbol, String, nil] type
  #
  def html?(type)
    format?(type, :html)
  end

  # Indicate whether *type* is JSON.
  #
  # @param [Symbol, String, nil] type
  #
  # @note Currently unused
  #
  def json?(type)
    format?(type, :json)
  end

  # Indicate whether *type* is XML.
  #
  # @param [Symbol, String, nil] type
  #
  # @note Currently unused
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
  # @raise [Minitest::Assertion]
  #
  # @return [true]
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
  # @raise [Minitest::Assertion]
  #
  # @return [true]
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
  # @raise [Minitest::Assertion]
  #
  # @return [true]
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
  # @raise [Minitest::Assertion]
  #
  # @return [true]
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
  # @return [true]                    If all criteria match.
  #
  def assert_result(status, **opt)

    assert_response status if status && (status != :any)

    action, ctrlr = (opt[:from].split('#').reverse if opt[:from])
    ctrlr  = (opt[:controller] || ctrlr)&.to_sym
    action = (opt[:action]     || action)&.to_sym
    media  = opt.key?(:media_type) ? opt[:media_type] : opt[:format]
    media  = (media.is_a?(Symbol) ? MEDIA_TYPE[media] : media)&.to_s

    assert_equal ctrlr,  controller_name(@controller.controller_path) if ctrlr
    assert_equal action, @controller.action_name&.to_sym              if action
    assert_equal media,  @response.media_type                         if media

    true

  end

end
