# app/models/concerns/file_parser/epub.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# EPUB file format metadata extractor.
#
class FileParser::Epub < FileParser::Ocf

  include FileFormat::Epub

end

__loading_end(__FILE__)
