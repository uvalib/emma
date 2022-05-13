# app/records/bs/shared/artifact_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods mixed in to record elements related to artifacts.
#
module Bs::Shared::ArtifactMethods

  include Bs::Shared::CommonMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # A method name for use where there may be confusion with `params[:format]`.
  #
  # @return [String]
  #
  def fmt
    find_item(:format).to_s
  end

  # A method name for use where there may be confusion with `params[:format]`.
  #
  # @return [Array<String>]
  #
  def fmts
    find_values(:formats).presence || [fmt]
  end

end

__loading_end(__FILE__)
