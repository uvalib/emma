# app/models/upload/options.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# URL parameter options related to Upload records.
#
class Upload::Options < Options

  # include UploadWorkflow::Properties # NOTE: This ends up being problematic.
  include Record::Properties

  # ===========================================================================
  # :section: Options overrides
  # ===========================================================================

  public

  def self.model_id_key = :submission_id

  # ===========================================================================
  # :section: Options overrides
  # ===========================================================================

  public

  def option_keys
    OPTION_METHOD_MAP.keys
  end

  def option_method(key)
    OPTION_METHOD_MAP[key] || super
  end

  # ===========================================================================
  # :section: Options overrides
  # ===========================================================================

  protected

  # MODEL_DATA_PARAMS
  #
  # @type [Hash{Symbol=>Symbol}]
  #
  # === Implementation Notes
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
