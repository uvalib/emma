# app/models/concerns/file_object/ocf_file.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# An OCF-based file object.
#
# @see FileFormat::Ocf
# @see FileObject::Daisy
# @see FileObject::Epub
#
class FileObject::Ocf < FileObject

  include FileFormat::Ocf

end

__loading_end(__FILE__)
