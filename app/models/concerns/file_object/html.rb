# app/models/concerns/file_object/html.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# An HTML file object.
#
class FileObject::Html < FileObject

  include FileFormat::Html

end

__loading_end(__FILE__)
