# app/models/concerns/epub_parser.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# EPUB document information.
#
class EpubParser < OcfParser

  include EpubFormat

end

__loading_end(__FILE__)
