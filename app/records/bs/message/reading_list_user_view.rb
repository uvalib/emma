# app/records/bs/message/reading_list_user_view.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Message::ReadingListUserView
#
# @see Bs::Record::ReadingListUserView
#
class Bs::Message::ReadingListUserView < Bs::Api::Message

  include Bs::Shared::LinkMethods
  include Bs::Shared::ReadingListMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema_from Bs::Record::ReadingListUserView

end

__loading_end(__FILE__)
