# app/models/download/paginator.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Parameters for pagination of lists of Download records.
#
class Download::Paginator < Paginator

  # ===========================================================================
  # :section: Paginator overrides
  # ===========================================================================

  public

  def initialize(ctrlr = nil, **opt)
    opt[:action]   = base_action(opt[:action]) if opt[:action]
    opt[:disabled] = true unless opt.key?(:disabled)
    super
  end

end

__loading_end(__FILE__)
