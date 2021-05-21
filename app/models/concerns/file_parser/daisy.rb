# app/models/concerns/file_parser/daisy.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# DAISY (ANSI/NISO Z39.86) file format metadata extractor.
#
# Also known as ANSI/NISO Z39.86 - DTBook (Digital Talking Book).
#
# @see http://www.daisy.org/z3986/2005/Z3986-2005.html
#
class FileParser::Daisy < FileParser::Ocf

  include FileFormat::Daisy

end

__loading_end(__FILE__)
