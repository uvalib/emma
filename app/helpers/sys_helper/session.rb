# app/helpers/sys_helper/session.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper supporting EMMA settings available to all workers/threads.
#
module SysHelper::Session

  include SysHelper::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Request `session` values listing.
  #
  # @param [Hash] opt                 To #dt_dd_section.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def request_session_section(**opt)
    dt_dd_section(request.session.to_hash, **opt)
  end

  # Request `session_options` values listing.
  #
  # @param [Hash] opt                 To #dt_dd_section.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def request_options_section(**opt)
    dt_dd_section(request.session_options.to_hash, **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    __included(base, self)
  end

end

__loading_end(__FILE__)
