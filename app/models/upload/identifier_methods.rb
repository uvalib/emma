# app/models/upload/identifier_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Upload record utility methods related to identifiers.
#
module Upload::IdentifierMethods

  include Record::EmmaIdentification

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    base.extend(self)
    base.include(Record::EmmaIdentification::InstanceMethods)
  end

end

__loading_end(__FILE__)
