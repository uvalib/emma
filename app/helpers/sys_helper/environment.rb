# app/helpers/sys_helper/environment.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper supporting EMMA settings available to all workers/threads.
#
module SysHelper::Environment

  include SysHelper::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Request header values listing.
  #
  # @param [Hash] opt                 To #dt_dd_section.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def environment_section(**opt)
    dt_dd_section(environment_variables, **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # Reformat `ENV` as a sorted Hash starting with lowercase names.
  #
  # @return [Hash{String=>String}]
  #
  def environment_variables
    ENV_VAR.from_env.partition { |k, _| k =~ /[a-z]/ }.flat_map(&:itself).to_h
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
