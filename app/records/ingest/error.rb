# app/records/ingest/error.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Base exception for EMMA Federated Ingest API errors.
#
class Ingest::Error < ::Api::Error

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
  # @see en.emma.error.search in config/locales/en.yml
  #
  # This method overrides:
  # @see Api::Error#default_message
  #
  def self.default_message(allow_nil: false)
    super(allow_nil: allow_nil, source: :ingest)
  end

end

# =============================================================================
# :section: Authorization errors
# =============================================================================

public

# Base exception for EMMA Federated Ingest API authorization errors.
#
class Ingest::AuthError < Ingest::Error; end

# Base exception for EMMA Federated Ingest API communication errors.
#
class Ingest::CommError < Ingest::Error; end

# Base exception for EMMA Federated Ingest API session errors.
#
class Ingest::SessionError < Ingest::Error; end

# Exception raised to indicate that the session token has expired.
#
class Ingest::TimeoutError < Ingest::Error; end

# =============================================================================
# :section: Receive errors
# =============================================================================

public

# Base exception for EMMA Federated Ingest API receive errors.
#
class Ingest::RecvError < Ingest::CommError; end

# Exception raised to indicate a problem with received data.
#
class Ingest::ParseError < Ingest::RecvError; end

# =============================================================================
# :section: Transmit errors
# =============================================================================

public

# Base exception for EMMA Federated Ingest API transmit errors.
#
class Ingest::XmitError < Ingest::CommError; end

# Base exception for EMMA Federated Ingest API requests.
#
class Ingest::RequestError < Ingest::XmitError; end

__loading_end(__FILE__)
