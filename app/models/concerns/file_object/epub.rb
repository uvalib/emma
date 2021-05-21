# app/models/concerns/file_object/epub.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# An EPUB file object.
#
class FileObject::Epub < FileObject::Ocf

  include FileFormat::Epub

end

__loading_end(__FILE__)
