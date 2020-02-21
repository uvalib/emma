# app/models/concerns/daisy_audio_parser.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# DAISY AUDIO document information.
#
class DaisyAudioParser < DaisyParser

  include DaisyAudioFormat

end

__loading_end(__FILE__)
