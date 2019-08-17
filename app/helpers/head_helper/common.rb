# app/helpers/head_helper/common.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# HeadHelper::Common
#
module HeadHelper::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Include common options for "<link>" and "<script>" tags.
  #
  # @param [Hash] opt
  #
  # @return [Hash]
  #
  # == Implementation Notes
  # Note that 'reload' is the documented value for 'data-turbolinks-track'
  # however (for some unknown reason) causes requests to be made twice.  By
  # experimentation the value that works best here is the empty string.
  #
  def meta_options(**opt)
    opt.reverse_merge('data-turbolinks-track': '')
  end

end

__loading_end(__FILE__)
