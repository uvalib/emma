# app/models/concerns/file_object/latex.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# A LaTeX file object.
#
class FileObject::Latex < FileObject

  include FileFormat::Latex

end

__loading_end(__FILE__)
