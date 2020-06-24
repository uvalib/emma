# app/records/bs/error.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Base exception for Bookshare API errors.
#
class Bs::Error < ::Api::Error

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
  # @see en.emma.error.bookshare in config/locales/en.yml
  #
  # This method overrides:
  # @see Api::Error#default_message
  #
  def self.default_message(allow_nil: false)
    super(allow_nil: allow_nil, source: :bookshare)
  end

end

# =============================================================================
# :section: Authorization errors
# =============================================================================

public

# Base exception for Bookshare API authorization errors.
#
class Bs::AuthError < Bs::Error; end

# Base exception for Bookshare API communication errors.
#
class Bs::CommError < Bs::Error; end

# Base exception for Bookshare API session errors.
#
class Bs::SessionError < Bs::Error; end

# Exception raised to indicate that the session token has expired.
#
class Bs::TimeoutError < Bs::Error; end

# =============================================================================
# :section: Receive errors
# =============================================================================

public

# Base exception for Bookshare API receive errors.
#
class Bs::RecvError < Bs::CommError; end

# Exception raised to indicate a problem with received data.
#
class Bs::ParseError < Bs::RecvError; end

# =============================================================================
# :section: Transmit errors
# =============================================================================

public

# Base exception for Bookshare API transmit errors.
#
class Bs::XmitError < Bs::CommError; end

# Base exception for Bookshare API requests.
#
class Bs::RequestError < Bs::XmitError; end

# Exception raised to indicate a problem with an account operation.
#
class Bs::AccountError < Bs::RequestError; end

# Exception raised to indicate a problem with a subscription operation.
#
class Bs::SubscriptionError < Bs::RequestError; end

# Exception raised to indicate a problem with a title/catalog operation.
#
class Bs::TitleError < Bs::RequestError; end

# Exception raised to indicate a problem with a periodicals operation.
#
class Bs::PeriodicalError < Bs::RequestError; end

# Exception raised to indicate a problem with a reading list operation.
#
class Bs::ReadingListError < Bs::RequestError; end

# Exception raised to indicate a problem with an organization operation.
#
class Bs::OrganizationError < Bs::RequestError; end

__loading_end(__FILE__)
