# app/models/upload/identifier_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Upload record utility methods related to identifiers.
#
module Upload::IdentifierMethods

  def included(base)
    base.send(:extend, self)
  end

  include Emma::Common

  extend self

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # @type [String]                                                              # NOTE: to Record::EmmaIdentification
  SID_PREFIX = 'u'

  # @type [(Integer,Integer)]                                                   # NOTE: to Record::EmmaIdentification
  SID_LETTERS = ('g'..'z').minmax.map(&:ord).deep_freeze

  # @type [Integer]                                                             # NOTE: to Record::EmmaIdentification
  SID_LETTER_SPAN = SID_LETTERS.then { |pr| pr.last - pr.first + 1 }

  # @type [String]                                                              # NOTE: to Record::EmmaIdentification
  SID_LETTER_MATCH = ('[%c-%c]' % SID_LETTERS).freeze

  # @type [Regexp]                                                              # NOTE: to Record::EmmaIdentification
  SID_PATTERN = /^#{SID_PREFIX}\h{8,}#{SID_LETTER_MATCH}\d\d$/

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Extract the database ID from the given item.
  #
  # @param [Api::Record, Upload, Hash, String, Any, nil] item
  #
  # @return [String]                  Record ID (:id).
  # @return [nil]                     No valid :id specified.
  #
  #--
  # noinspection RubyNilAnalysis
  #++
  def id_for(item)                                                              # NOTE: to Record::Identification#id_value
    result   = (item                    if digits_only?(item))
    result ||= (item.id                 if item.is_a?(Upload))
    result ||= (item[:id] || item['id'] if item.is_a?(Hash))
    result   = result.to_i
    result.to_s unless result.zero?
  end

  # Extract the submission ID from the given item.                              # NOTE: to Record::EmmaIdentification#sid_value
  #
  # @param [Api::Record, Upload, Hash, String, Any, nil] item
  #
  # @return [String]                  The submission ID.
  # @return [nil]                     No submission ID could be determined.
  #
  #--
  # noinspection RubyNilAnalysis
  #++
  def sid_for(item)
    # noinspection RubyMismatchedReturnType, RubyMismatchedArgumentType
    return item               if valid_sid?(item)
    return item.submission_id if item.is_a?(Upload)
    _, rid, _ = Upload.record_id(item)&.split('-')
    rid if valid_sid?(rid)
  end

  # Indicate whether *value* could be an EMMA submission ID.
  #
  # @param [Any] value                Must be a String.
  #
  def valid_sid?(value)                                                         # NOTE: to Record::EmmaIdentification
    value.is_a?(String) && value.match?(SID_PATTERN)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Create a unique submission item identifier.
  #
  # @param [Time, DateTime, nil] time
  # @param [String, Boolean] prefix   Character(s) leading the numeric portion,
  #                                     *true* for the default prefix, or
  #                                     *false* for no prefix.
  #
  # @return [String]
  #
  # @see #sid_counter
  #
  # == Implementation Notes
  # The result is a (single-character) prefix followed by 8 hexadecimal digits
  # which represent seconds into the epoch followed by a single random letter
  # from 'g' to 'z', followed by two decimal digits from "00" to "99" based on
  # a randomly initialized counter.  This arrangement allows bulk upload (which
  # occurs on a single thread) to be able to generate unique IDs in rapid
  # succession.
  #
  # Leading with a non-hex-digit guarantees that submission ID's are distinct
  # from database ID's (which are only decimal digits).
  #
  #--
  # noinspection RubyNilAnalysis
  #++
  def generate_submission_id(time = nil, prefix: true)                          # NOTE: to Record::EmmaIdentification
    prefix  = SID_PREFIX if prefix.is_a?(TrueClass)
    time    = time.is_a?(DateTime) ? time.to_time : (time || Time.now)
    base_id = time.tv_sec
    letter  = SID_LETTERS.first + rand(SID_LETTER_SPAN)
    sprintf('%s%x%c%02d', prefix, base_id, letter, sid_counter)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Counter for the trailing portion of the generated submission ID.
  #
  # This provides a per-thread value in the range 0..99 which can be used to
  # differentiate submission IDs which are generated in rapid succession (e.g.,
  # for bulk upload).
  #
  # @return [Integer]
  #
  def sid_counter                                                               # NOTE: to Record::EmmaIdentification and Entry#sid_counter
    @sid_counter &&= (@sid_counter + 1) % 100
    @sid_counter ||= rand(100) % 100
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Interpret an identifier as either an :id or :submission_id, generating a
  # field/value pair for use with #find_by or #where.
  #
  # @param [String, Symbol, Integer, Hash, Upload, nil] v
  #
  # @return [Hash{Symbol=>Integer,String,nil}] Result will have only one entry.
  #
  def id_term(v)                                                                # NOTE: to Record::EmmaIdentification
    # noinspection RubyNilAnalysis
    id, sid =
      case v
        when Integer then [v, nil]
        when Upload  then [v[:id], v[:submission_id]]
        when Hash    then v.symbolize_keys.values_at(:id, :submission_id)
        else digits_only?((v = v.to_s.strip)) ? [v, nil] : [nil, v]
      end
    id ? { id: id.to_i } : { submission_id: sid }
  end

  # The database ID of the first "upload" table record.
  #
  # @return [Integer]                 If 0 then the table is empty.
  #
  def minimum_id                                                                # NOTE: to Record::Identification
    Upload.minimum(:id).to_i
  end

  # The database ID of the last "upload" table record.
  #
  # @return [Integer]                 If 0 then the table is empty.
  #
  def maximum_id                                                                # NOTE: to Record::Identification
    Upload.maximum(:id).to_i
  end

  # Transform a mixture of ID representations into a set of one or more
  # non-overlapping range representations.
  #
  # @param [Array<Upload, String, Integer, Array>] items
  # @param [Hash]                                  opt
  #
  # @option opt [Integer] :min_id     Default: `#minimum_id`
  # @option opt [Integer] :max_id     Default: `#maximum_id`
  #
  # @return [Array<String>]
  #
  #--
  # noinspection RubyMismatchedArgumentType, RubyMismatchedReturnType
  #++
  def compact_ids(*items, **opt)                                                # NOTE: to Record::Identification
    opt[:min_id] ||= minimum_id
    opt[:max_id] ||= maximum_id
    ids, non_ids = expand_ids(*items, **opt).partition { |v| digits_only?(v) }
    non_ids.sort!.uniq!
    ids.map! { |id| [id.to_i, opt[:min_id]].max }.sort!.uniq!
    ids =
      ids.chunk_while { |prev, this| (prev + 1) == this }.map do |range|
        first = range.shift
        last  = range.pop || first
        (first == last) ? first.to_s : "#{first}-#{last}"
      end
    min, max = opt.values_at(:min_id, :max_id).map(&:to_s)
    all = (ids == [max] if min == max)
    all ||= (ids == [min, '$']) || (ids == [min, max])
    all ||= ids.first&.match?(/^(0|1|#{min}|\*)?-(#{max}|\$)$/)
    ids = %w(*) if all
    ids + non_ids
  end

  # Transform a mixture of ID representations into a list of single IDs.
  #
  # Any parameter may be (or contain):
  # - A single ID as a String or Integer
  # - A set of IDs as a string of the form /\d+(,\d+)*/
  # - A range of IDs as a string of the form /\d+-\d+/
  # - A range of the form /-\d+/ is interpreted as /0-\d+/
  #
  # @param [Array<Upload, String, Integer, Array>] ids
  # @param [Hash]                                  opt
  #
  # @option opt [Integer] :min_id     Default: `#minimum_id`
  # @option opt [Integer] :max_id     Default: `#maximum_id`
  #
  # @return [Array<String>]
  #
  # == Examples
  #
  # @example Single
  #   expand_ids('123') -> %w(123)
  #
  # @example Sequence
  #   expand_ids('123,789') -> %w(123 789)
  #
  # @example Range
  #   expand_ids('123-126') -> %w(123 124 125 126)
  #
  # @example Mixed
  #   expand_ids('125,789-791,123-126') -> %w(125 789 790 791 123 124 126)
  #
  # @example Implicit range
  #   expand_ids('-3')  -> %w(1 2 3)
  #   expand_ids('*-3') -> %w(1 2 3)
  #
  # @example Open-ended range
  #   expand_ids('3-')  -> %w(3 4 5 6)
  #   expand_ids('3-*') -> %w(3 4 5 6)
  #   expand_ids('3-$') -> %w(3 4 5 6)
  #
  # @example All records
  #   expand_ids('*')   -> %w(1 2 3 4 5 6)
  #   expand_ids('-$')  -> %w(1 2 3 4 5 6)
  #   expand_ids('*-$') -> %w(1 2 3 4 5 6)
  #   expand_ids('1-$') -> %w(1 2 3 4 5 6)
  #
  # @example Last record only
  #   expand_ids('$')   -> %w(6)
  #   expand_ids('$-$') -> %w(6)
  #
  def expand_ids(*ids, **opt)                                                   # NOTE: to Record::Identification
    opt[:min_id] ||= minimum_id
    opt[:max_id] ||= maximum_id
    # noinspection RubyMismatchedReturnType
    ids.flatten.flat_map { |id|
      id.is_a?(String) ? id.strip.tr(',', ' ').split(/\s+/) : id
    }.flat_map { |id|
      expand_id_range(id, **opt) if id.present?
    }.compact.uniq
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # A valid ID range term for interpolation into a Regexp.                      # NOTE: to Record::Identification::RNG_TERM
  #
  # @type [String]
  #
  RANGE_TERM = '(\d+|\$|\*)'

  # Interpret an ID string as a range of IDs if possible.
  #
  # The method supports a mixture of database IDs (which are comprised only of
  # decimal digits) and submission IDs (which always start with a non-digit),
  # however a submission ID cannot be part of a range.
  #
  # @param [String, Integer, Upload] id
  # @param [Hash]                    opt
  #
  # @option opt [Integer] :min_id     Default: `#minimum_id`
  # @option opt [Integer] :max_id     Default: `#maximum_id`
  #
  # @return [Array<String>]
  #
  # @see #expand_ids
  #
  def expand_id_range(id, **opt)                                                # NOTE: to Record::EmmaIdentification and Record::Identification
    min = max = nil
    # noinspection RubyCaseWithoutElseBlockInspection
    case id
      when Numeric, /^\d+$/, '$'           then min = id
      when Upload                          then min = id.id
      when Hash                            then min = id[:id] || id['id']
      when '*'                             then min, max = [1,  '$']
      when /^-#{RANGE_TERM}/               then min, max = [1,  $1 ]
      when /^#{RANGE_TERM}-$/              then min, max = [$1, '$']
      when /^#{RANGE_TERM}-#{RANGE_TERM}$/ then min, max = [$1, $2 ]
    end
    min &&= (opt[:max_id] ||= maximum_id) if (min == '$')
    min &&= [1, min.to_i].max
    max &&= (opt[:max_id] ||= maximum_id) if (max == '$') || (max == '*')
    max &&= [1, max.to_i].max
    result   = max ? (min..max).to_a : min
    result ||= (id.submission_id                          if id.is_a?(Upload))
    result ||= (id[:submission_id] || id['submission_id'] if id.is_a?(Hash))
    result ||= id
    Array.wrap(result).compact_blank.map(&:to_s)
  end

end

__loading_end(__FILE__)
