# lib/ext/iso-639/lib/iso-639.rb
#
# encoding:              UTF-8
# frozen_string_literal: true
# warn_indent:           true
#
# Extends the ISO 639-2 entries to include the subset of ISO 639-3 languages
# that are present in Bookshare.

class ISO_639

  # Entries for ISO 639-2 language codes plus a subset of ISO 639-3 codes for
  # languages that are present in Bookshare.
  #
  # @type [(String,String,String,String,String)]
  #
  ISO_639_2 = (
    [
      self['tkb', '', '', 'Buksa Tharu',      ''],
      self['yue', '', '', 'Cantonese',        ''],
      self['ccp', '', '', 'Chakma',           ''],
      self['ctg', '', '', 'Chittagonian',     ''],
      self['the', '', '', 'Chitwania Tharu',  ''],
      self['thl', '', '', 'Dangaura Tharu',   ''],
      self['tkt', '', '', 'Kathoriya Tharu',  ''],
      self['thq', '', '', 'Kochila Tharu',    ''],
      self['cmn', '', '', 'Mandarin',         ''],
      self['pnb', '', '', 'Punjabi, Western', ''],
      self['thr', '', '', 'Rana Tharu',       ''],
      self['rkt', '', '', 'Rangpuri',         ''],
      self['skr', '', '', 'Saraiki',          ''],
      self['soi', '', '', 'Sonha',            ''],
      self['syl', '', '', 'Sylheti',          ''],
    ] + remove_const(:ISO_639_2)
  ).freeze

  remove_const(:INVERTED_INDEX)

  # An inverted index generated from the ISO_639_2 data. Used for searching
  # all words and codes in all fields.
  #
  # @type [Hash{String=>Array<Integer>}]
  #
  INVERTED_INDEX =
    {}.tap { |index|
      ISO_639_2.each_with_index do |record, i|
        record.each do |field|
          field = field.downcase
          words = field.split(/[[:blank:]]|\(|\)|,|;/) + field.split(/;/)
          words.compact_blank!.uniq.each do |word|
            index[word] ||= []
            index[word] << i
          end
        end
      end
    }.deep_freeze

=begin # NOTE: preserved for possible future use
  # Patterns matching languages that should not be presented as choices for
  # bibliographic metadata.
  #
  # @type [Array<Regexp>]
  #
  BOGUS_LANGUAGE = %w[
    ^Bliss
    ^Klingon
    ^Reserved
    ^Sign
    ^Undetermined
    \\\(
    content
    jargon
    language
    pidgin
  ].map { Regexp.new(_1) }.deep_freeze
=end

end
