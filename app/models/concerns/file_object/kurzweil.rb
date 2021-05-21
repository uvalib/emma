# app/models/concerns/file_object/kurzweil.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# A Kurzweil file object.
#
class FileObject::Kurzweil < FileObject

  include FileFormat::Kurzweil

end

__loading_end(__FILE__)
