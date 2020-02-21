# app/models/brf_file.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# A BRF file object.
#
class BrfFile < CachedFile

  include BrfFormat

end

__loading_end(__FILE__)
