# app/models/manifest/paginator.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Parameters for pagination of lists of Manifest records.
#
class Manifest::Paginator < Paginator

  # ===========================================================================
  # :section: Paginator overrides
  # ===========================================================================

  public

  def initialize(ctrlr = nil, **opt)
    opt[:action] = base_action(opt[:action]) if opt[:action]
    super
  end

end

__loading_end(__FILE__)
