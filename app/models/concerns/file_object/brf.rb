# app/models/concerns/file_object/brf.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# A BRF file object.
#
class FileObject::Brf < FileObject

  include FileFormat::Brf

end

__loading_end(__FILE__)
