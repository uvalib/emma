# app/models/concerns/file_object/rtf.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# An RTF file object.
#
class FileObject::Rtf < FileObject

  include FileFormat::Rtf

end

__loading_end(__FILE__)
