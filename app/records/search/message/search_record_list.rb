# app/records/search/message/search_record_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Search::Message::SearchRecordList
#
class Search::Message::SearchRecordList < Search::Api::Message

  include TimeHelper

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
  # @option opt [Symbol] :format      If not provided, this will be determined
  #                                     heuristically from *data*.
  #
  # This method overrides:
  # @see Api::Record#initialize
  #
  # noinspection RubyYardParamTypeMatch
  def initialize(data, **opt)
    __debug { "### #{self.class}.#{__method__}" }
#=begin # TODO: testing - remove section vvv
    @serializer_type = opt[:format] || DEFAULT_SERIALIZER_TYPE
    assert_serializer_type(@serializer_type)
    @records = make_examples
#=end # TODO: testing - remove section ^^^
    start_time = timestamp
=begin # TODO: restore section vvv
    data = data.body.presence if data.is_a?(Faraday::Response)
    opt  = opt.dup
    opt[:format] ||= self.format_of(data)
    opt[:error]  ||= true if opt[:format].blank?
    data = wrap_outer(data, opt) if (opt[:format] == :xml) && !opt[:error]
    @exception =
      case opt[:error]
        when Exception then opt[:error]
        when String    then Api::Error.new(opt[:error])
      end
    if @exception
      @serializer_type = :hash
      initialize_attributes
    else
      @serializer_type = opt[:format] || DEFAULT_SERIALIZER_TYPE
      assert_serializer_type(@serializer_type)
      @records = deserialize(data)
    end
=end # TODO: restore section ^^^
  ensure
    elapsed_time = time_span(start_time)
    __debug { "<<< #{self.class} processed in #{elapsed_time}" }
    Log.info { "#{self.class} processed in #{elapsed_time}"}
  end

  # ===========================================================================
  # :section: TODO: remove - testing federated search with fake records
  # ===========================================================================

  protected

  include Search::Shared::TitleMethods

  # @type [Hash]
  EXAMPLE_DATA = I18n.t('emma.examples.search').deep_freeze

  # @type [Hash]
  RECORD_TEMPLATE = EXAMPLE_DATA.dig(:generic, :template).deep_freeze

  # Generate example records from config/locales/examples.en.yml data.
  #
  # @param [Array<Symbol>] repositories   Default: Repository#values.
  #
  # @return [Array<Search::Message::SearchRecord>]
  #
  def make_examples(repositories = nil) # TODO: remove - testing
    repositories ||= Repository.values
    repositories = Array.wrap(repositories).map(&:to_sym)
    EXAMPLE_DATA.flat_map { |section, entries|
      next unless repositories.include?(section)
      entries = entries.values.flatten(1) if entries.is_a?(Hash)
      Array.wrap(entries).map { |fields| make_example(fields) }
    }.compact << make_example # Finish with an entry with all fields displayed.
  end

  # Generate an example record.
  #
  # @overload make_example(source, values = nil)
  #   @param [SourceRecord] source
  #   @param [Hash]         values    Default: {}.
  #
  # @overload make_example(values = nil)
  #   @param [Hash]         values    Default: #RECORD_TEMPLATE.
  #
  # @return [Search::Message::SearchRecord]
  #
  def make_example(source = nil, values = nil) # TODO: remove - testing
    if source.is_a?(Search::Message::SearchRecord)
      source.dup.tap do |result|
        if values.is_a?(Hash)
          values.each_pair do |attribute, value|
            result.send(:"#{attribute}=", value)
          end
        end
      end
    else
      values = source if source.is_a?(Hash)
      values ||= RECORD_TEMPLATE
      Search::Message::SearchRecord.new(values.to_json)
    end
  end

end

__loading_end(__FILE__)
