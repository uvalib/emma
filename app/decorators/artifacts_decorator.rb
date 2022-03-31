# app/decorators/artifacts_decorator.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Collection presenter for "/artifact" pages.
#
# @!attribute [r] object
#   Set in Draper#initialize
#   @return [Array<Bs::Record::ArtifactMetadata>]
#
class ArtifactsDecorator < BaseCollectionDecorator

  # ===========================================================================
  # :section: Draper
  # ===========================================================================

  collection_of ArtifactDecorator

end

__loading_end(__FILE__)
