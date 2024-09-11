# app/models/concerns/file_object/other.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# A file object of a non-specific format.
#
class FileObject::Other < FileObject

  include FileFormat::Other

end

__loading_end(__FILE__)
