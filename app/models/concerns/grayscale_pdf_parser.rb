# app/models/concerns/grayscale_pdf_parser.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Grayscale PDF document information.
#
class GrayscalePdfParser < PdfParser

  include GrayscalePdfFormat

end

__loading_end(__FILE__)
