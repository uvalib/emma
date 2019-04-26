# app/models/concerns/api/error.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

module Api

  # Base exception for Bookshare API errors.
  #
  class Error < RuntimeError

    # If applicable, the original exception that was rescued which resulted in
    # raising an Api::Error exception.
    #
    # @return [Exception]
    # @return [nil]
    #
    attr_reader :original_exception

    # Initialize a new instance.
    #
    # @param [Array<(String,Exception)>] args
    #
    def initialize(*args)
      msg = nil
      while (arg = args.shift)
        case arg
          when String    then msg = arg
          when Exception then @original_exception = arg
        end
      end
      msg ||= @original_exception&.message
      super(msg)
    end

  end

  # ===========================================================================
  # :section: Authorization errors
  # ===========================================================================

  public

  # Base exception for Bookshare API authorization errors.
  #
  class AuthError < Api::Error; end

  # Base exception for Bookshare API session errors.
  #
  class SessionError < Api::Error; end

  # Exception raised to indicate that the session token has expired.
  #
  class TimeoutError < SessionError; end

  # ===========================================================================
  # :section: Receive errors
  # ===========================================================================

  public

  # Base exception for Bookshare API receive errors.
  #
  class RecvError < Api::Error; end

  # Exception raised to indicate a problem with received data.
  #
  class ParseError < Api::RecvError; end

  # ===========================================================================
  # :section: Transmit errors
  # ===========================================================================

  public

  # Base exception for Bookshare API transmit errors.
  #
  class XmitError < Error; end

  # Base exception for Bookshare API requests.
  #
  class RequestError < XmitError; end

  # Exception raised to indicate a problem with an account operation.
  #
  class AccountError < RequestError; end

  # Exception raised to indicate a problem with a subscription operation.
  #
  class SubscriptionError < RequestError; end

  # Exception raised to indicate a problem with a title/catalog operation.
  #
  class TitleError < RequestError; end

  # Exception raised to indicate a problem with a periodicals operation.
  #
  class PeriodicalError < RequestError; end

  # Exception raised to indicate a problem with a reading list operation.
  #
  class ReadingListError < RequestError; end

end

__loading_end(__FILE__)
