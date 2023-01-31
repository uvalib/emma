# app/decorators/base_collection_decorator/submission.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods supporting bulk submission.
#
module BaseCollectionDecorator::Submission

  include BaseDecorator::Submission

  include BaseCollectionDecorator::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    __included(base, self)
  end

end

__loading_end(__FILE__)
