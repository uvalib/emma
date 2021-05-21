# app/models/concerns/file_object/grayscale_pdf.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# A Grayscale PDF file object.
#
class FileObject::GrayscalePdf < FileObject::Pdf

  include FileFormat::GrayscalePdf

end

__loading_end(__FILE__)
