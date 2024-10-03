# app/models/concerns/file_object/tex.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# A TeX file object.
#
class FileObject::Tex < FileObject

  include FileFormat::Tex

end

__loading_end(__FILE__)
