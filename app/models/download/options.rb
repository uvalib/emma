# app/models/download/options.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# URL parameter options related to Download records.
#
class Download::Options < Options

  include Record::Properties

  # ===========================================================================
  # :section: Options overrides
  # ===========================================================================

  public

  # Extract POST parameters that are usable for creating/updating a new model
  # instance.
  #
  # @return [Hash]
  #
  def model_post_params
    super.tap do |prm|
      usr = prm.delete(:user) || prm[:user_id]
      prm[:user_id] = usr.id if usr.is_a?(User)
    end
  end

end

__loading_end(__FILE__)
