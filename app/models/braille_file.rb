# app/models/braille_file.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# A Braille file object.
#
class BrailleFile < FileObject

  include BrailleFormat

end

__loading_end(__FILE__)
