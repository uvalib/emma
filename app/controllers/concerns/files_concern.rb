# app/controllers/concerns/files_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# FilesConcern
#
module FilesConcern

  extend ActiveSupport::Concern

  included do |base|
    __included(base, 'FilesConcern')
  end

  include FileFormatHelper

  # ===========================================================================
  # :section: Initialization
  # ===========================================================================

  MIME_REGISTRATION =
    FileNaming.format_classes.values.each(&:register_mime_types)

end

__loading_end(__FILE__)
