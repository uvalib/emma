# app/records/concerns/api/shared/transform_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods supporting transformations of data fields.
#
module Api::Shared::TransformMethods

  include Api::Shared::IdentifierMethods
  include Api::Shared::DateMethods

  extend self

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Transform data fields.
  #
  # @param [Hash, nil] data           Default: *self*.
  #
  # @return [void]
  #
  def normalize_data_fields!(data = nil)
    clean_dc_relation!(data)
    normalize_title_dates!(data)
  end

end

__loading_end(__FILE__)
