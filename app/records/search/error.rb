# app/records/search/error.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Base exception for EMMA Federated Search API errors.
#
class Search::Error < ::Api::Error

  # Default API error message
  #
  # @type [String]
  #
  DEFAULT_ERROR = I18n.t('emma.error.search.default').freeze

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  # Default error message for the current instance based on the name of its
  # class.
  #
  # @param [Boolean] allow_nil
  #
  # @return [String]
  # @return [nil]                     If *allow_nil* is set to *true* and no
  #                                     default message is defined.
  #
  # @see en.emma.error.api in config/locales/en.yml
  # This method overrides:
  # @see Api::Error#default_message
  #
  def self.default_message(allow_nil: false)
    type = self.class.to_s.demodulize.underscore.sub(/_?error$/, '').presence
    fallback = ((type ? "#{type} error" : DEFAULT_ERROR) unless allow_nil)
    type && I18n.t("emma.error.search.#{type}", default: nil) || fallback
  end

end

# =============================================================================
# :section: Authorization errors
# =============================================================================

public

# Base exception for EMMA Federated Search API authorization errors.
#
class Search::AuthError < ::Api::AuthError; end

# Base exception for EMMA Federated Search API communication errors.
#
class Search::CommError < ::Api::CommError; end

# Base exception for EMMA Federated Search API session errors.
#
class Search::SessionError < ::Api::SessionError; end

# Exception raised to indicate that the session token has expired.
#
class Search::TimeoutError < ::Api::TimeoutError; end

# =============================================================================
# :section: Receive errors
# =============================================================================

public

# Base exception for EMMA Federated Search API receive errors.
#
class Search::RecvError < Search::CommError; end

# Exception raised to indicate a problem with received data.
#
class Search::ParseError < Search::RecvError; end

# =============================================================================
# :section: Transmit errors
# =============================================================================

public

# Base exception for EMMA Federated Search API transmit errors.
#
class Search::XmitError < Search::CommError; end

# Base exception for EMMA Federated Search API requests.
#
class Search::RequestError < Search::XmitError; end

__loading_end(__FILE__)
