# app/records/search/message/search_record_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Search::Message::SearchRecordList
#
class Search::Message::SearchRecordList < Search::Api::Message

  schema do
    has_many :records, Search::Record::MetadataRecord
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Strategy for pre-wrapping message data before de-serialization.
  #
  # @type [Hash{Symbol=>String,Boolean}]
  #
  WRAP_FORMATS = { xml: true, json: %q({"records":%{data}}) }.freeze

  # Initialize a new instance.
  #
  # @param [Faraday::Response, Api::Record, Hash, String, nil] src
  # @param [Hash]                                              opt
  #
  # @option opt [Boolean] :example    If this list should be generated from
  #                                     sample data. # TODO: remove - testing
  #
  # This method overrides:
  # @see Api::Record#initialize
  #
  def initialize(src, **opt)
    # noinspection RubyScope
    create_message_wrapper(opt) do |opt|
      if opt[:example] # TODO: remove - testing
        @serializer_type = :hash
        initialize_attributes
        self.records = make_examples(**opt)
      else
        if opt[:wrap].nil? || opt[:wrap].is_a?(Hash)
          opt[:wrap] = WRAP_FORMATS.merge(opt[:wrap] || {})
        end
        super(src, **opt)
      end
    end
  end

  # Simulates the :totalResults field of similar Bookshare API records.
  #
  # @return [Integer]
  #
  #--
  # noinspection RubyInstanceMethodNamingConvention, RubyYardReturnMatch
  #++
  def totalResults
    records&.size || 0
  end

  # ===========================================================================
  # :section: TODO: remove - testing unified search with fake records
  # ===========================================================================

  protected

  include Search::Shared::TitleMethods

  # @type [Hash]
  #
  #--
  # noinspection RailsI18nInspection
  #++
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
          next unless (entry = make_example(fields))
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
