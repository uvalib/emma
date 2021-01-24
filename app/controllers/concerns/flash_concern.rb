# app/controllers/concerns/flash_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Controller support methods for creation of flash messages.
#
module FlashConcern

  extend ActiveSupport::Concern

  included do |base|

    __included(base, 'FlashConcern')

    include FlashHelper
    extend  FlashHelper

  end

end

__loading_end(__FILE__)
