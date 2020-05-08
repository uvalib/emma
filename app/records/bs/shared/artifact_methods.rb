# app/records/bs/shared/artifact_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods mixed in to record elements related to artifacts.
#
module Bs::Shared::ArtifactMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # A method name for use where there may be confusion with `params[:format]`.
  #
  # @return [String]
  #
  def fmt
    format.to_s if respond_to?(:format)
  end

  # A method name for use where there may be confusion with `params[:format]`.
  #
  # @return [Array<String>]
  #
  def fmts
    respond_to?(:formats) ? formats.map(&:to_s) : Array.wrap(fmt)
  end

end

__loading_end(__FILE__)
