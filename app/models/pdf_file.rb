# app/models/pdf_file.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# A PDF file object.
#
class PdfFile < FileObject

  include PdfFormat

end

__loading_end(__FILE__)
