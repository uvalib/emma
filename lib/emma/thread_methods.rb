# lib/emma/thread_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Thread utilities.
#
module Emma::ThreadMethods

  extend self

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Normalize thread name representation.
  #
  # @param [Thread, nil] thread       Default: `Thread#current`
  #
  # @return [String]
  #
  def thread_name(thread = nil)
    thread ||= Thread.current
    thread.name.sub(/^GoodJob::Scheduler[^)]+\)/, 'GoodJob')
  end

end

__loading_end(__FILE__)
