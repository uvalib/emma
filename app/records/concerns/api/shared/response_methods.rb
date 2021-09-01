# app/records/concerns/api/shared/response_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods mixed in to message elements supporting error reporting.
#
module Api::Shared::ResponseMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # @return [ExecReport]
  attr_reader :exec_report

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Generate the error table.
  #
  # @param [Array<Faraday::Response, Exception, String, Array, nil>] src
  #
  # @return [ExecReport]
  #
  # == Usage Notes
  # Intended to be executed in the initializer.
  #
  def initialize_exec_report(*src)
    @exec_report = ExecReport.new(*src)
  end

end

__loading_end(__FILE__)
