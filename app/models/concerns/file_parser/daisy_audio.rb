# app/models/concerns/file_parser/daisy_audio.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# DAISY AUDIO file format metadata extractor.
#
class FileParser::DaisyAudio < FileParser::Daisy

  include FileFormat::DaisyAudio

end

__loading_end(__FILE__)
