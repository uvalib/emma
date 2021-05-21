# app/models/concerns/file_object/daisy_audio.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# A DAISY AUDIO file object.
#
class FileObject::DaisyAudio < FileObject::Daisy

  include FileFormat::DaisyAudio

end

__loading_end(__FILE__)
