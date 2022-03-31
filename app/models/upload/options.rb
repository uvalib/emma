# app/models/upload/options.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

class Upload::Options < Options

  # include UploadWorkflow::Properties # NOTE: This ends up being problematic.
  include Record::Properties

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # @private
  MODEL_TYPE = :upload

  # URL parameters associated with item/entry identification.
  #
  # @type [Array<Symbol>]
  #
  IDENTIFIER_PARAMS = [*Options::IDENTIFIER_PARAMS, :submission_id].uniq.freeze

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

  def option_keys
    WF_METHOD_MAP.keys
  end

  def option_method(key)
    super || WF_METHOD_MAP[key]
  end

  # ===========================================================================
  # :section: Options overrides
  # ===========================================================================

  protected

  # MODEL_DATA_PARAMS
  #
  # @type [Hash{Symbol=>Symbol}]
  #
  # == Implementation Notes
  # The value `params[:upload][:emma_data]` is ignored because it reports the
  # original metadata values that were supplied to the edit form.  The value
  # `params[:upload][:file]` is ignored if it is blank or is the JSON
  # representation of an empty object ("{}") -- this indicates an editing
  # submission where metadata is being changed but the uploaded file is not
  # being replaced.
  #
  MODEL_DATA_PARAMS = {
    # URL param   Data hash key
    # ---------   -------------
    file_data:    :file,
    #emma_data:    :emma_data,   # NOTE: see above
    #revert:       :revert_data, # NOTE: from Entry::Options::MODEL_DATA_PARAMS
    revert:       :revert,
  }.freeze

  def model_data_params
    MODEL_DATA_PARAMS
  end

end

__loading_end(__FILE__)
