# app/models/concerns/file_object/word_file.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# A Microsoft Word (.docx) file object.
#
class FileObject::Word < FileObject

  include FileFormat::Word

end

__loading_end(__FILE__)
