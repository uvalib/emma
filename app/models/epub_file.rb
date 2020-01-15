# app/models/epub_file.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# An EPUB file object.
#
class EpubFile < OcfFile

  include EpubFormat

end

__loading_end(__FILE__)
