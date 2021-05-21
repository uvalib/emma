# app/models/concerns/file_object/tactile.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# A Tactile file object.
#
class FileObject::Tactile < FileObject

  include FileFormat::Tactile

end

__loading_end(__FILE__)
