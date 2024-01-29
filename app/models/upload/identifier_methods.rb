# app/models/upload/identifier_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Upload record utility methods related to identifiers.
#
module Upload::IdentifierMethods

  include Record::EmmaIdentification

  extend self

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    base.extend(self)
  end

end

__loading_end(__FILE__)
