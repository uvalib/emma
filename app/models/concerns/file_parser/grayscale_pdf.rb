# app/models/concerns/file_parser/grayscale_pdf.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Grayscale PDF file format metadata extractor.
#
class FileParser::GrayscalePdf < FileParser::Pdf

  include FileFormat::GrayscalePdf

end

__loading_end(__FILE__)
