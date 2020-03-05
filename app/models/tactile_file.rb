# app/models/tactile_file.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# A Tactile file object.
#
class TactileFile < CachedFile

  include TactileFormat

end

__loading_end(__FILE__)
