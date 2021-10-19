# app/records/bs/message/title_metadata_summary.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Message::TitleMetadataSummary
#
# @see Bs::Record::TitleMetadataSummary
#
class Bs::Message::TitleMetadataSummary < Bs::Api::Message

  include Bs::Shared::ArtifactMethods
  include Bs::Shared::CreatorMethods
  include Bs::Shared::IdentifierMethods
  include Bs::Shared::LinkMethods
  include Bs::Shared::TitleMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema_from Bs::Record::TitleMetadataSummary

end

__loading_end(__FILE__)
