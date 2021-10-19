# app/records/bs/message/organization.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Message::Organization
#
# @see Bs::Record::Organization
#
class Bs::Message::Organization < Bs::Api::Message

  include Bs::Shared::LinkMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema_from Bs::Record::Organization

end

__loading_end(__FILE__)
