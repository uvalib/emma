# app/models/upload/_config.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

module Upload::Config

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicates whether the submission form prompts for "Source Repository".
  #
  # If *true*, display the "Source Repository" menu for selecting the
  # destination repository for the submission, and for a partner repository,
  # engage the mini-form for selecting the original EMMA entry for which this
  # submission is a variant.
  #
  # If *false*, the emma_repository of the submission is always "emma", the
  # "Source Repository" menu is not shown, and the mini-form is never engaged.
  #
  # @see file:assets/javascripts/feature/model-form.js *SELECT_REPO*.
  #
  SELECT_REPO = false

end

__loading_end(__FILE__)
