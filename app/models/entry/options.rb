# app/models/entry/options.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

class Entry::Options < Options

  include Record::Properties

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # @private
  MODEL_TYPE = :entry

  # URL parameters associated with item/entry identification.
  #
  # @type [Array<Symbol>]
  #
  IDENTIFIER_PARAMS = [*Options::IDENTIFIER_PARAMS, :submission_id].uniq.freeze

  # URL parameters associated with POST data.
  #
  # @type [Array<Symbol>]
  #
  DATA_PARAMS = [*Options::DATA_PARAMS, :entry, :phase, :action].uniq.freeze

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

  protected

  def option_method(key)
    WF_METHOD_MAP[key&.to_sym]
  end

  # ===========================================================================
  # :section: Options overrides
  # ===========================================================================

  public

  # Get URL parameters relevant to the current operation.
  #
  # @param [ActionController::Parameters, Hash, nil] p   Def: `Options#params`
  #
  # @return [Hash{Symbol=>Any}]
  #
  def get_model_params(p = nil)
    super.delete_if { |k, _| k.start_with?('edit_') } # TODO: temporary until JavaScript upload -> entry
  end

  # ===========================================================================
  # :section: Options overrides
  # ===========================================================================

  protected

  MODEL_DATA_PARAMS = {
    # URL param   Data hash key
    # ---------   -------------
    file_data:    :file,
    emma_data:    :emma_data,
    revert:       :revert_data,
  }.freeze

  def model_data_params
    MODEL_DATA_PARAMS
  end

end

__loading_end(__FILE__)
