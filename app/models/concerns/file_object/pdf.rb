# app/models/concerns/file_object/pdf_file.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# A PDF file object.
#
class FileObject::Pdf < FileObject

  include FileFormat::Pdf

end

__loading_end(__FILE__)
