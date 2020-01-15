# app/models/word_file.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# A Microsoft Word (.docx) file object.
#
class WordFile < RemoteFile

  include WordFormat

end

__loading_end(__FILE__)
