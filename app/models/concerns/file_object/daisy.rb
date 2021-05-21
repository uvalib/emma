# app/models/concerns/file_object/daisy.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# A DAISY file object.
#
class FileObject::Daisy < FileObject::Ocf

  include FileFormat::Daisy

end

__loading_end(__FILE__)
