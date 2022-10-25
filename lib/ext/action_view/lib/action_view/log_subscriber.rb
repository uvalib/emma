# lib/ext/action_view/lib/action_view/log_subscriber.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# ActionView logging overrides.

__loading_begin(__FILE__)

require 'action_view/log_subscriber'

module ActionView

  # Generates an empty method for each LogSubscriber method marked as inactive,
  # which will prevent that method from writing to the log when this module is
  # prepended to LogSubscriber.
  module LogSubscriberExt
    {
      render_template:      true,   # Log.info
      render_partial:       false,  # Log.debug
      render_layout:        true,   # Log.info
      render_collection:    false,  # Log.debug
      log_rendering_start:  false,  # Log.debug
    }.each_pair { |meth, active| neutralize(meth) unless active }
  end

end

# =============================================================================
# Override gem definitions
# =============================================================================

override ActionView::LogSubscriber => ActionView::LogSubscriberExt

__loading_end(__FILE__)
