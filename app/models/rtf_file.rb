# app/models/rtf_file.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# An RTF file object.
#
class RtfFile < CachedFile

  include RtfFormat

end

__loading_end(__FILE__)
