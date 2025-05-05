# app/records/search/shared/score_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods mixed in to record elements related to dates.
#
module Search::Shared::ScoreMethods

  include Emma::Common

  include Search::Shared::IdentifierMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # @type [Array<Symbol>]
  SCORE_TYPES = %i[title creator publisher identifier keyword].freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  attr_accessor :search_title_score
  attr_accessor :search_creator_score
  attr_accessor :search_publisher_score
  attr_accessor :search_identifier_score
  attr_accessor :search_keyword_score

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Get the summation of all current score attribute values.
  #
  # @param [Numeric, nil] precision   Passed to Float#round if given.
  # @param [Hash]         opt         Passed to #get_scores.
  #
  # @return [Float,Integer]           Integer if *precision* <= 0.
  #
  # === Usage Notes
  #
  def total_score(precision: nil, **opt)
    result = get_scores(**opt).values.compact.sum
    precision ? result.round(precision) : result
  end

  # All search score attribute values.
  #
  # @param [Numeric, nil] precision   Passed to Float#round if given.
  # @param [Boolean]      all         If *true*, include 0 and nil values.
  #
  # @return [Hash{Symbol=>Float,nil}]
  #
  # === Usage Notes
  # * These are the current values of the search score attributes as assigned
  #   directly or via #calculate_scores!.
  # * If a non-zero :keyword_score is present then that is the *only* value
  #   returned.
  #
  def get_scores(precision: nil, all: nil, **)
    SCORE_TYPES.map { |type|
      value = send("search_#{type}_score")
      value = value.round(precision) if value && precision
      [:"#{type}_score", value]
    }.to_h.tap { |result|
      all ||= result.values.compact.all?(&:zero?)
      all ||= !result[:keyword_score]&.nonzero?
      result.slice!(:keyword_score) unless all
    }
  end

  # Update search score attribute values.
  #
  # @param [String, Array<String>] terms  Given to all score methods if present
  # @param [Hash]                  opt    Passed to score methods except:
  #
  # @option opt [Symbol, Array<Symbol>] :types  Default: $SCORE_TYPES.
  #
  # @return [Array<Float>]
  #
  # === Implementation Notes
  # If included :keyword is always placed last so that #calculate_keyword_score
  # can take advantage of the calculations of the other scores.  If no types
  # are specified all defined types *except* :keyword are calculated.
  #
  def calculate_scores!(terms = nil, **opt)
    if opt.key?(:q) || opt.key?(:keyword)
      terms ||= opt[:q] || opt[:keyword]
      types = SCORE_TYPES
    else
      types = SCORE_TYPES.excluding(:keyword)
    end
    types = Array.wrap(opt.delete(:for))    if opt.key?(:for)
    types = (types-%i[keyword]) << :keyword if types[0...-1].include?(:keyword)
    types.map do |type|
      value = send("calculate_#{type}_score", terms, **opt)
      send("search_#{type}_score=", value)
    end
  end

  # Calculate a title search relevancy score.
  #
  # @param [String, Array<String>] terms
  # @param [Hash]                  opt
  #
  # @option opt [String, Array<String>] :title
  #
  # @return [Float]
  #
  # === Implementation Notes
  # The actual relevancy seems to discount certain "stop words", but the actual
  # behavior cannot be easily inferred from the search results.
  #
  def calculate_title_score(terms = nil, **opt)
    #opt[:stop_words] ||= %w[of] # %w[a and by of the]
    #opt[:keep_words] ||= %w[Of] # %w[A And By Of The]
    terms = opt.delete(:title) || terms
    field_score(:dc_title, terms, **opt)
  end

  # Calculate a creator search relevancy score.
  #
  # @param [String, Array<String>] terms
  # @param [Hash]                  opt
  #
  # @option opt [String, Array<String>] :creator
  #
  # @return [Float]
  #
  def calculate_creator_score(terms = nil, **opt)
    terms = opt.delete(:creator) || terms
    field_score(:dc_creator, terms, **opt)
  end

  # Calculate a publisher search relevancy score.
  #
  # @param [String, Array<String>] terms
  # @param [Hash]                  opt
  #
  # @option opt [String, Array<String>] :publisher
  #
  # @return [Float]
  #
  def calculate_publisher_score(terms = nil, **opt)
    terms = opt.delete(:publisher) || terms
    field_score(:dc_publisher, terms, **opt)
  end

  # Calculate a standard identifier search relevancy score.
  #
  # @param [String, Array<String>] terms
  # @param [Hash]                  opt
  #
  # @option opt [String, Array<String>] :identifier
  #
  # @return [Float]                   Either 0.0 or 100.0.
  #
  def calculate_identifier_score(terms = nil, **opt)
    terms = opt.delete(:identifier) || terms
    terms = normalize_identifiers(terms)
    field_score(:dc_identifier, terms, **opt).zero? ? 0.0 : 100.0
  end

  # Calculate a keyword search relevancy score as a combination of title,
  # creator and publisher scores.
  #
  # @param [String, Array<String>] terms
  # @param [Hash]                  opt
  #
  # @option opt [String, Array<String>] :q
  # @option opt [String, Array<String>] :keyword
  #
  # @return [Float]
  #
  def calculate_keyword_score(terms = nil, **opt)
    search = opt.extract!(:q, *SCORE_TYPES)
    terms  = search[:q] || search[:keyword] || terms
    count  = 0
    types  = { title: 100, creator: 0, publisher: 0 }
    scores =
      types.map { |type, weight|
        next if weight.zero?
        score = send("search_#{type}_score").to_f
        score = send("calculate_#{type}_score", terms, **opt) if score.zero?
        if score.nonzero?
          count += weight
          score *= weight
        end
        [type, score]
      }.compact.to_h
    Float(scores.values.sum) / Float(types.values.sum)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # @type [String,Array<String>]
  DEF_NO_BREAK = %w[ _ . " ' ].freeze

  # @type [String]
  KEEP = "\001"

  # Generate a score from the number of words found in *field* which are also
  # found in *terms*.
  #
  # @param [Array<String>, String, Symbol] field
  # @param [Array<String>, String]         terms
  # @param [Hash]                          opt    Passed to #scoring_words
  #
  # @return [Float]
  #
  def field_score(field, terms, **opt)
    field = scoring_words(field, **opt)
    terms = scoring_words(terms, **opt)
    return 0.0 if field.blank? || terms.blank?
    hits  = terms.sum { field.count(_1) }
    100.0 * hits / field.size
  end

  # Break a word on spaces or punctuation into one or more normalized words.
  #
  # @param [Symbol, String, Array<String>] value
  # @param [String, Array<String>]         no_break     Default: #DEF_NO_BREAK
  # @param [String, Array<String>]         stop_words   Default: []
  # @param [String, Array<String>]         keep_words   Default: []
  #
  # @return [Array<String>]
  #
  def scoring_words(value, no_break: nil, stop_words: nil, keep_words: nil, **)
    stop_words = Array.wrap(stop_words).compact.presence&.uniq
    keep_words = stop_words && Array.wrap(keep_words).compact.presence&.uniq
    no_break   = Array.wrap(no_break || DEF_NO_BREAK).compact.presence&.uniq
    original   = no_break&.join
    substitute = no_break&.map&.with_index(2) { |_, i| i.chr }&.join

    value = send(value) if value.is_a?(Symbol)
    words = Array.wrap(value).map(&:to_s)
    words.map! { _1.gsub(/'s(\W|$)/i, '\1') }                     # NOTE: [1]
    words.map! { _1.tr(original, substitute) }                    if no_break
    words.map! { break_words(_1, !keep_words) }.flatten!
    words.map! { keep_words.include?(_1) ? "#{KEEP}#{_1}" : _1 }  if keep_words
    words -= stop_words                                           if stop_words
    words.map! { _1.delete(KEEP).downcase }                       if keep_words
    words.map! { normalized(_1.tr(substitute, original)) }        if no_break
    words.compact_blank

    # NOTE: [1] Eliminate possessives before *no_break* makes them invisible.
  end

  # Break a word on spaces or punctuation into one or more normalized words.
  #
  # @param [String]  word
  # @param [Boolean] lowercase
  #
  # @return [Array<String>]
  #
  def break_words(word, lowercase = false)
    normalized(word, lowercase: lowercase).split(/\s+/)
  end

end

__loading_end(__FILE__)
