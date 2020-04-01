# app/models/concerns/ocf_file.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# An OCF-based file object.
#
# @see DaisyFile
# @see EpubFile
# @see OcfFormat
#
class OcfFile < FileObject

  include OcfFormat

end

__loading_end(__FILE__)
