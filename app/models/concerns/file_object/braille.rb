# app/models/concerns/file_object/braille.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# A Braille file object.
#
class FileObject::Braille < FileObject

  include FileFormat::Braille

end

__loading_end(__FILE__)
