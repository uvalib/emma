# app/models/daisy_audio_file.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# A DAISY AUDIO file object.
#
class DaisyAudioFile < DaisyFile

  include DaisyAudioFormat

end

__loading_end(__FILE__)
