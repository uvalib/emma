# app/models/manifest_item/options.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

class ManifestItem::Options < Options

  include Record::Properties

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # @private
  MODEL_TYPE = :manifest_item

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

  # ===========================================================================
  # :section: Options overrides
  # ===========================================================================

  public

  # Extract POST parameters that are usable for creating/updating a new model
  # instance.
  #
  # @return [Hash{Symbol=>Any}]
  #
  def get_model_params
    super.tap do |prm|
      prm[:manifest_id] = prm.delete(:manifest) if prm.key?(:manifest)
    end
  end

  # ===========================================================================
  # :section: Options overrides
  # ===========================================================================

  protected

  MODEL_DATA_PARAMS = {
    # URL param   Data hash key
    # ---------   -------------
    file_data:    :file_data,
  }.freeze

  # model_data_params
  #
  # @return [Hash{Symbol=>Symbol}]
  #
  def model_data_params
    MODEL_DATA_PARAMS
  end

  # Extract POST parameters that are usable for creating/updating an Upload
  # instance.
  #
  # @param [Hash] prm         Parameters to update
  # @param [Hash] opt         Options to #json_parse.
  #
  # @return [Hash, nil]       The new contents of *prm* if modified.
  #
  def extract_model_data!(prm, **opt)
    opt[:compact] = false
    super
  end

end

__loading_end(__FILE__)
