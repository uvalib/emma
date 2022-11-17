# app/models/manifest/options.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

class Manifest::Options < Options

  include Record::Properties

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # @private
  MODEL_TYPE = :manifest

  # URL parameters associated with item/entry identification.
  #
  # @type [Array<Symbol>]
  #
  IDENTIFIER_PARAMS = [:manifest_id, *Options::IDENTIFIER_PARAMS].uniq.freeze

  # URL parameters associated with POST data.
  #
  # @type [Array<Symbol>]
  #
  DATA_PARAMS = [*Options::DATA_PARAMS, MODEL_TYPE].uniq.freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  def initialize(prm = nil)
    super(MODEL_TYPE, prm)
  end

end

__loading_end(__FILE__)
