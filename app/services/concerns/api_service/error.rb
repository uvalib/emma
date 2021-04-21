# app/services/concerns/api_service/error.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Base exception for external API service problems.
#
class ApiService::Error < Api::Error

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Initialize a new instance.
  #
  # @param [Array<Faraday::Response, Exception, Integer, String, true, nil>] args
  # @param [String, nil] default      Default message.
  #
  def initialize(*args, default: nil)
    if args.none? { |a| a.is_a?(String) }
      error = args.find { |arg| arg.is_a?(Faraday::Error) }
      args += extract_message(error) if error.present?
    end
    super(*args, default: default)
  end

  # ===========================================================================
  # :section: Api::Error overrides
  # ===========================================================================

  public

  # Enhance Faraday::Error messages.
  #
  # @param [Array<String>] messages
  #
  # @return [Array<String>]
  #
  def faraday_error(*messages)
    super.map do |m|
      m.sub(/the server/, "The #{service_name}")
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Methods to be included in related subclasses.
  #
  module Methods

    # @private
    def self.included(base)
      base.send(:extend, self)
    end

    # Non-functional hints for RubyMine type checking.
    # :nocov:
    include Api::Error::Methods unless ONLY_FOR_DOCUMENTATION
    # :nocov:

    # =========================================================================
    # :section: Api::Error::Methods overrides
    # =========================================================================

    public

    # Name of the service and key into config/locales/error.en.yml.
    #
    # If the class (or the class of the instance) defines 'SERVICE_NAME', that
    # is returned; otherwise the name is derived from the class name.
    #
    # @return [Symbol]
    #
    # == Examples
    #
    # @example BookshareService::EmptyResultError
    #   => :bookshare
    #
    # @example SearchSearch::TimeoutError
    #   => :timeout
    #
    def service
      @service ||=
        if (c = is_a?(Class) ? self : self.class)
          name = c.safe_const_get(:SERVICE_NAME)
          name ||= c.module_parent_name.underscore.remove(/_service$/)
          name&.to_sym || super
        end
    end

    # Name of the error and subkey into config/locales/error.en.yml.
    #
    # If the class (or the class of the instance) defines 'ERROR_TYPE', that
    # is returned; otherwise the type is derived from the class name.
    #
    # @return [Symbol, nil]
    #
    # == Examples
    #
    # @example BookshareService::EmptyResultError
    #   => :empty_result
    #
    # @example SearchSearch::TimeoutError
    #   => :timeout
    #
    def error_type
      @error_type ||=
        if (c = is_a?(Class) ? self : self.class)
          type = c.safe_const_get(:ERROR_TYPE)
          type ||= c.name.demodulize.to_s.underscore.remove(/_error$/)
          type&.to_sym || super
        end
    end

    # Default error message for the current instance.
    #
    # @return [String, nil]
    #
    def default_message
      @default_message ||= super
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Error types extracted from "config/locales/error.en.yml".
    #
    # @return [Hash{Symbol=>String}]
    #
    def error_config
      @error_config ||=
        [:api, service].uniq.reduce({}) { |result, config_section|
          i18n_path = "emma.error.#{config_section}"
          result.merge!(I18n.t(i18n_path, default: {}))
        }.except!(:_name, :default)
    end

    # Error types extracted from "config/locales/error.en.yml".
    #
    # @return [Array<Symbol>]
    #
    def error_types
      error_config.keys
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Prefix seen in Bookshare error messages.
    #
    # @type [String]
    #
    ERROR_TAG = 'error_description'

    # Get the message from within the response body of a Faraday exception.
    #
    # @param [Faraday::Error] error
    #
    # @return [Array<String>]
    #
    def extract_message(error)
      body = error.response[:body]
      return [] if body.blank?
      json = json_parse(body, symbolize_keys: false).presence || {}
      json = json.first       if json.is_a?(Array) && (json.size <= 1)
      return json.compact     if json.is_a?(Array)
      return Array.wrap(body) unless json.is_a?(Hash)
      desc = json[ERROR_TAG].presence
      desc ||=
        Array.wrap(json['messages']).map { |msg|
          msg = msg.to_s.strip
          if msg =~ /^[a-z0-9_]+=/i
            next unless msg.delete_prefix!("#{ERROR_TAG}=")
          end
          msg.remove(/\\"/)
        }.reject(&:blank?).presence
      desc ||= json['message'].presence
      desc ||= json.values.flat_map { |v| v if v.is_a?(Array) }.compact
      Array.wrap(desc.presence || body)
    end

  end

  include ApiService::Error::Methods

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Produce a family of error subclasses based on the error types specified by
  # the union of 'en.emma.error.api' and "en.emma.error.#{service}".
  #
  # For example, for `service` == :search, given type == :empty_result
  # this method will define
  #
  #   class SearchService::EmptyResultError < ApiService::EmptyResultError
  #     include SearchService::Error::Methods
  #   end
  #
  # @return [Hash{Symbol=>Class}]     The value of @error_subclass.
  #
  def self.generate_error_subclasses
    error_class   = self
    is_base_class = (error_class == ApiService::Error)
    service_class = error_class.module_parent
    @error_subclass =
      error_types.map { |type|
        sub_class  = "#{type}_error".camelize
        base_class =
          if !is_base_class && ApiService.const_defined?(sub_class, false)
            "ApiService::#{sub_class}"
          end
        base_class ||= error_class
        service_class.class_eval <<~HERE_DOC
          class #{sub_class} < #{base_class}
            include #{error_class}::Methods
          end
        HERE_DOC
        [type, service_class.const_get(sub_class)]
      }.to_h
  end

  # A table of error types mapped on to error subclasses.
  #
  # @return [Hash{Symbol=>Class}]
  #
  # @see ApiService::Error#generate_error_subclasses
  #
  def self.error_subclass
    @error_subclass ||= generate_error_subclasses
  end

  # ===========================================================================
  # :section: Error subclasses
  # ===========================================================================

  generate_error_subclasses

end

# Non-functional hints for RubyMine type checking.
# :nocov:
unless ONLY_FOR_DOCUMENTATION

  # ===========================================================================
  # :section: Transmission errors
  # ===========================================================================

  public

  # Exception raised to indicate that the user was not authorized to perform
  # the requested remote service action.
  #
  # @see file:config/locales/error.en.yml *en.emma.error.api.auth*
  #
  class ApiService::AuthError < ApiService::Error
    include ApiService::Error::Methods
  end

  # Exception raised to indicate that there was a (transient) network error
  # when communicating with the remote service.
  #
  # @see file:config/locales/error.en.yml *en.emma.error.api.comm*
  #
  class ApiService::CommError < ApiService::Error
    include ApiService::Error::Methods
  end

  # Exception raised to indicate that there was a session error in
  # communication with the remote service.
  #
  # @see file:config/locales/error.en.yml *en.emma.error.api.session*
  #
  class ApiService::SessionError < ApiService::Error
    include ApiService::Error::Methods
  end

  # Exception raised to indicate that there was a problem establishing a
  # connection to the remote service.
  #
  # @see file:config/locales/error.en.yml *en.emma.error.api.connect*
  #
  class ApiService::ConnectError < ApiService::Error
    include ApiService::Error::Methods
  end

  # Exception raised to indicate that the connection to the remote service
  # timed out.
  #
  # @see file:config/locales/error.en.yml *en.emma.error.api.timeout*
  #
  class ApiService::TimeoutError < ApiService::Error
    include ApiService::Error::Methods
  end

  # Exception raised to indicate that there was network error while sending to
  # the remote service.
  #
  # @see file:config/locales/error.en.yml *en.emma.error.api.xmit*
  #
  class ApiService::XmitError < ApiService::Error
    include ApiService::Error::Methods
  end

  # Exception raised to indicate that there was network error while receiving
  # from the remote service.
  #
  # @see file:config/locales/error.en.yml *en.emma.error.api.recv*
  #
  class ApiService::RecvError < ApiService::Error
    include ApiService::Error::Methods
  end

  # Exception raised to indicate that the remote service returned malformed
  # data.
  #
  # @see file:config/locales/error.en.yml *en.emma.error.api.parse*
  #
  class ApiService::ParseError < ApiService::Error
    include ApiService::Error::Methods
  end

  # ===========================================================================
  # :section: Request errors
  # ===========================================================================

  public

  # Exception raised to indicate a generic or unique issue with the request to
  # the remote service API.
  #
  # @see file:config/locales/error.en.yml *en.emma.error.api.request*
  #
  class ApiService::RequestError < ApiService::Error
    include ApiService::Error::Methods
  end

  # Exception raised to indicate that no (valid) inputs were provided so no
  # service request was made.
  #
  # @see file:config/locales/error.en.yml *en.emma.error.api.no_input*
  #
  class ApiService::NoInputError < ApiService::Error
    include ApiService::Error::Methods
  end

  # ===========================================================================
  # :section: Response errors
  # ===========================================================================

  public

  # Exception raised to indicate a generic or unique issue with the response
  # from the remote service API.
  #
  # @see file:config/locales/error.en.yml *en.emma.error.api.response*
  #
  class ApiService::ResponseError < ApiService::Error
    include ApiService::Error::Methods
  end

  # Exception raised to indicate that a valid message was received but it had
  # no body or its body was empty.
  #
  # @see file:config/locales/error.en.yml *en.emma.error.api.empty_result*
  #
  class ApiService::EmptyResultError < ApiService::Error
    include ApiService::Error::Methods
  end

  # Exception raised to indicate that a message with an HTML body was received
  # when HTML was not expected.
  #
  # @see file:config/locales/error.en.yml *en.emma.error.api.html_result*
  #
  class ApiService::HtmlResultError < ApiService::Error
    include ApiService::Error::Methods
  end

  # Exception raised to indicate a invalid redirect destination.
  #
  # @see file:config/locales/error.en.yml *en.emma.error.api.redirection*
  #
  class ApiService::RedirectionError < ApiService::Error
    include ApiService::Error::Methods
  end

  # Exception raised to indicate that there were too many redirects.
  #
  # @see file:config/locales/error.en.yml *en.emma.error.api.redirect_limit*
  #
  class ApiService::RedirectLimitError < ApiService::Error
    include ApiService::Error::Methods
  end

end
# :nocov:

__loading_end(__FILE__)
