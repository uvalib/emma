# app/models/upload/identifier_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Upload record utility methods related to identifiers.
#
module Upload::IdentifierMethods

  include Emma::Common

  extend self

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # @type [String]
  SID_PREFIX = 'u'

  # @type [(Integer,Integer)]
  SID_LETTERS = ('g'..'z').minmax.map(&:ord).deep_freeze

  # @type [Integer]
  # noinspection RubyMismatchedArgumentType
  SID_LETTER_SPAN = SID_LETTERS.then { |pr| pr.last - pr.first + 1 }

  # @type [String]
  SID_LETTER_MATCH = ('[%c-%c]' % SID_LETTERS).freeze

  # @type [Regexp]
  SID_PATTERN = /^#{SID_PREFIX}\h{8,}#{SID_LETTER_MATCH}\d\d$/

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether the value could be a valid #id_column value.
  #
  # @param [*] value
  #
  def valid_id?(value)
    digits_only?(value)
  end

  # Extract the database ID from the given item.
  #
  # @param [Api::Record, Upload, Hash, String, *] item
  #
  # @return [String]                  Record ID (:id).
  # @return [nil]                     No valid :id specified.
  #
  def id_for(item)
    # noinspection RailsParamDefResolve
    v = item.is_a?(Hash) ? (item[:id] || item['id']) : (item.try(:id) || item)
    v.to_s if valid_id?(v)
  end

  # Extract the submission ID from the given item.
  #
  # @param [Api::Record, Upload, Hash, String, *] item
  #
  # @return [String]                  The submission ID.
  # @return [nil]                     No submission ID could be determined.
  #
  def sid_for(item)
    return item               if valid_sid?(item)
    return item.submission_id if item.respond_to?(:submission_id)
    _, rid, _ = Upload.record_id(item)&.split('-')
    rid if valid_sid?(rid)
  end

  # Indicate whether *value* could be an EMMA submission ID.
  #
  # @param [String, *] value
  #
  def valid_sid?(value)
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
  # === Implementation Notes
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
  def generate_submission_id(time = nil, prefix: true)
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
  def sid_counter
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
  def id_term(v)
    id, sid =
      case v
        when Integer then [v, nil]
        when Upload  then [v[:id], v[:submission_id]]
        when Hash    then v.symbolize_keys.values_at(:id, :submission_id)
        else              valid_id?((v = v.to_s.strip)) ? [v, nil] : [nil, v]
      end
    id = id.to_i if digits_only?(id)
    id ? { id: id } : { submission_id: sid }
  end

  # The database ID of the first "upload" table record.
  #
  # @return [Integer]                 If 0 then the table is empty.
  #
  def minimum_id
    Upload.minimum(:id).to_i
  end

  # The database ID of the last "upload" table record.
  #
  # @return [Integer]                 If 0 then the table is empty.
  #
  def maximum_id
    Upload.maximum(:id).to_i
  end

  # Transform a mixture of ID representations into a set of one or more
  # non-overlapping range representations followed by non-identifiers (if any).
  #
  # @param [Array<Upload, String, Integer, Array>] items
  # @param [Hash]                                  opt
  #
  # @option opt [Integer] :min_id     Default: `#minimum_id`
  # @option opt [Integer] :max_id     Default: `#maximum_id`
  #
  # @return [Array<String>]
  #
  def compact_ids(*items, **opt)
    ids, non_ids = expand_ids(*items, **opt).partition { |v| valid_id?(v) }
    group_ids(*ids, **opt) + non_ids.sort!.uniq
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
  # === Examples
  #
  # @example Single
  #   expand_ids('123') -> %w[123]
  #
  # @example Sequence
  #   expand_ids('123,789') -> %w[123 789]
  #
  # @example Range
  #   expand_ids('123-126') -> %w[123 124 125 126]
  #
  # @example Mixed
  #   expand_ids('125,789-791,123-126') -> %w[125 789 790 791 123 124 126]
  #
  # @example Implicit range
  #   expand_ids('-3')  -> %w[1 2 3]
  #   expand_ids('*-3') -> %w[1 2 3]
  #
  # @example Open-ended range
  #   expand_ids('3-')  -> %w[3 4 5 6]
  #   expand_ids('3-*') -> %w[3 4 5 6]
  #   expand_ids('3-$') -> %w[3 4 5 6]
  #
  # @example All records
  #   expand_ids('*')   -> %w[1 2 3 4 5 6]
  #   expand_ids('-$')  -> %w[1 2 3 4 5 6]
  #   expand_ids('*-$') -> %w[1 2 3 4 5 6]
  #   expand_ids('1-$') -> %w[1 2 3 4 5 6]
  #
  # @example Last record only
  #   expand_ids('$')   -> %w[6]
  #   expand_ids('$-$') -> %w[6]
  #
  def expand_ids(*ids, **opt)
    opt[:min_id] ||= minimum_id
    opt[:max_id] ||= maximum_id
    ids.flatten.flat_map { |id|
      id.is_a?(String) ? id.strip.tr(',', ' ').split(/\s+/) : id
    }.flat_map { |id|
      expand_id_range(id, **opt) if id.present?
    }.compact.uniq
  end

  # Condense an array of identifiers by replacing runs of contiguous number
  # values like "first", "first+1", "first+2", ..., "last" with "first-last".
  #
  # If the entire
  #
  #
  # @param [Array<String>] ids
  # @param [Integer, nil]  min_id     Default: `#minimum_id`
  # @param [Integer, nil]  max_id     Default: `#maximum_id`
  #
  # @return [Array<String>]
  #
  def group_ids(*ids, min_id: nil, max_id: nil, **)
    min = (min_id ||= minimum_id).to_s
    max = (max_id ||  maximum_id).to_s
    ids.map! { |id| [id.to_i, min_id].max }.sort!.uniq!
    # noinspection RubyMismatchedArgumentType
    ids =
      ids.chunk_while { |prev, this| (prev + 1) == this }.map do |range|
        first = range.shift
        last  = range.pop || first
        (first == last) ? first.to_s : "#{first}-#{last}"
      end
    all   = (ids == [max] if min == max)
    all ||= (ids == [min]) || (ids == [min, max])
    all ||= ids.first&.match?(/^(0|1|#{min}|\*)?-(#{max}|\$)$/)
    all ? %w[*] : ids
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # A valid ID range term for interpolation into a Regexp.
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
  def expand_id_range(id, **opt)
    min = max = nil
    case id
      when Numeric, /^\d+$/, '$'           then min = id
      when Upload                          then min = id.id
      when Hash                            then min = id[:id] || id['id']
      when '*'                             then min, max = [1,  '$']
      when /^-#{RANGE_TERM}/               then min, max = [1,  $1 ]
      when /^#{RANGE_TERM}-$/              then min, max = [$1, '$']
      when /^#{RANGE_TERM}-#{RANGE_TERM}$/ then min, max = [$1, $2 ]
    end
    min = (opt[:max_id] ||= maximum_id) if (min == '$')
    min = [1, min.to_i].max             if digits_only?(min)
    max = (opt[:max_id] ||= maximum_id) if (max == '$') || (max == '*')
    max = [1, max.to_i].max             if digits_only?(max)
    if min.is_a?(Integer) && max.is_a?(Integer)
      (min..max).to_a.map!(&:to_s)
    else
      min ||= (id.submission_id                          if id.is_a?(Upload))
      min ||= (id[:submission_id] || id['submission_id'] if id.is_a?(Hash))
      min ||= id
      Array.wrap(min&.to_s)
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    base.extend(self)
  end

end

__loading_end(__FILE__)
