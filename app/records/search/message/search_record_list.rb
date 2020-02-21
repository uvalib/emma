# app/records/search/message/search_record_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Search::Message::SearchRecordList
#
class Search::Message::SearchRecordList < Search::Api::Message

  include Emma::Time

  attr_reader :records

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Initialize a new instance.
  #
  # @param [Faraday::Response, Hash, String] data
  # @param [Hash]                            opt
  #
  # @option opt [Symbol]  :format     If not provided, this will be determined
  #                                     heuristically from *data*.
  #
  # @option opt [Boolean] :example    If this list should be generated from
  #                                     sample data. # TODO: remove - testing
  #
  # This method overrides:
  # @see Api::Record#initialize
  #
  # noinspection RubyYardParamTypeMatch
  def initialize(data, **opt)
    __debug { "### #{self.class}.#{__method__}" }
    start_time = timestamp
    # noinspection RubyCaseWithoutElseBlockInspection
    @exception =
      case opt[:error]
        when Exception then opt[:error]
        when String    then Api::Error.new(opt[:error])
      end
    if @exception
      @serializer_type = :hash
      initialize_attributes
    elsif opt[:example] # TODO: remove - testing
      @serializer_type = :hash
      initialize_attributes
      @records = make_examples(**opt)
    else
      @serializer_type = opt[:format] || DEFAULT_SERIALIZER_TYPE
      assert_serializer_type(@serializer_type)
      data = data.body.presence if data.is_a?(Faraday::Response)
      opt[:format] ||= self.format_of(data)
      opt[:error]  ||= true if opt[:format].blank?
      data = wrap_outer(data, **opt) if (opt[:format] == :xml) && !opt[:error]
      @records = deserialize(data)
    end
  ensure
    elapsed_time = time_span(start_time)
    __debug { "<<< #{self.class} processed in #{elapsed_time}" }
    Log.info { "#{self.class} processed in #{elapsed_time}"}
  end

  # ===========================================================================
  # :section: TODO: remove - testing unified search with fake records
  # ===========================================================================

  protected

  include Search::Shared::TitleMethods

  # @type [Hash]
  EXAMPLE_DATA = I18n.t('emma.examples.search').deep_freeze

  # @type [Hash]
  RECORD_TEMPLATE = EXAMPLE_DATA.dig(:generic, :template)

  # Generate example records from config/locales/examples.en.yml data.
  #
  # @param [Hash] opt
  #
  # @option opt [Symbol]        :example      Either :template or :search.
  # @option opt [String]        :repository   Limit by :emma_repository.
  # @option opt [String]        :fmt          Limit by :dc_format.
  # @option opt [String]        :language     Limit by :dc_language.
  # @option opt [String, Array] :feature      Limit by :emma_formatFeature.
  #
  # @return [Array<Search::Message::SearchRecord>]
  #
  def make_examples(**opt) # TODO: remove - testing
    example  = opt[:example] || :search
    feature  = Array.wrap(opt[:accessibilityFeature]).map(&:to_s).presence
    source   = opt[:repository]&.to_s
    language = opt[:language]&.to_s
    format   = opt[:fmt]&.to_s
    if example == :search
      repositories = EmmaRepository.values.map(&:to_sym)
      EXAMPLE_DATA.flat_map { |section, entries|
        next unless repositories.include?(section)
        entries = entries.values.flatten(1) if entries.is_a?(Hash)
        Array.wrap(entries).map do |fields|
          entry = make_example(fields)
          next unless (feature - entry.emma_formatFeature).blank? if feature
          next unless entry.emma_repository == source             if source
          next unless entry.dc_format       == format             if format
          next unless entry.dc_language     == language           if language
          entry
        end
      }.compact
    else
      [make_example(RECORD_TEMPLATE)]
    end
  end

  # Generate an example record.
  #
  # @param [Hash, SourceRecord] source
  # @param [Hash]               values  Optional field value overrides.
  #
  # @return [Search::Message::SearchRecord]
  # @return [nil]
  #
  def make_example(source, values = nil) # TODO: remove - testing
    case source
      when Search::Message::SearchRecord then result = source.dup
      when Hash then result = Search::Message::SearchRecord.new(source.to_json)
      else return
    end
    if values.present?
      values.each_pair do |attribute, value|
        result.send(:"#{attribute}=", value)
      end
    end
    result
  end

end

__loading_end(__FILE__)
