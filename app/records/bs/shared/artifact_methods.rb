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
    # noinspection RailsParamDefResolve
    try(:format).to_s
  end

  # A method name for use where there may be confusion with `params[:format]`.
  #
  # @return [Array<String>]
  #
  def fmts
    # noinspection RailsParamDefResolve
    try(:formats)&.map(&:to_s) || [fmt]
  end

end

__loading_end(__FILE__)
