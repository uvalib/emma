# app/records/bs/message/reading_position.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Message::ReadingPosition
#
# @see Bs::Record::ReadingPosition
#
class Bs::Message::ReadingPosition < Bs::Api::Message

  include Bs::Shared::LinkMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema_from Bs::Record::ReadingPosition

end

__loading_end(__FILE__)
