# app/records/bs/message/periodical_edition.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Message::PeriodicalEdition
#
# @see Bs::Record::PeriodicalEdition
#
class Bs::Message::PeriodicalEdition < Bs::Api::Message

  include Bs::Shared::ArtifactMethods
  include Bs::Shared::EditionMethods
  include Bs::Shared::LinkMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema_from Bs::Record::PeriodicalEdition

end

__loading_end(__FILE__)
