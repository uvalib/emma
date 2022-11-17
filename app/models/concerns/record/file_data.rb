# app/models/concerns/record/file_data.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Record methods to support processing of :file_data record columns.
#
# TODO: Does PG return 'json' fields as a symbolized Hashes?
# TODO: Does PG accommodate setting 'json' fields with symbolized Hashes?
# TODO: If the answer to both of those questions is "yes" then these methods
#   shouldn't go to the trouble of stringify-ing Hashes.
#
module Record::FileData

  extend ActiveSupport::Concern

  include Emma::Json

  include Record

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The default name for the column which holds upload data.
  #
  # @type [Symbol]
  #
  FILE_DATA_COLUMN = :file_data

  # Whether the #FILE_DATA_COLUMN should be persisted as a Hash.
  #
  # @type [Boolean]
  #
  FILE_DATA_HASH = true

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Generate a record to express structured file data.
  #
  # @param [Hash, String, nil] data
  #
  # @return [Hash{String=>Any}]
  #
  # @note Only used by #file_attacher_load
  #
  def make_file_record(data, **opt)
    opt.reverse_merge!(symbolize_keys: false)
    json_parse(data, **opt) || {}
  end

  # parse_file_data
  #
  # @param [String, Hash, nil] data
  # @param [Boolean]           allow_blank
  #
  # @return [Hash]
  #
  # @note Invoked only from methods which are currently unused.
  #
  def parse_file_data(data, allow_blank = false)
    return {} if data.blank?
    result = make_file_record(data, no_raise: false)
    raise 'array unexpected'       if result.is_a?(Array)
    result = reject_blanks(result) unless allow_blank
    result&.symbolize_keys! || {}
  rescue => error
    Log.warn do
      msg = [__method__, error.message]
      msg << "for #{data.inspect}" if Log.debug?
      msg.join(': ')
    end
    re_raise_if_internal_exception(error) or {}
  end

  # generate_file_data
  #
  # @param [String, Hash, ActionController::Parameters, Model, nil] data
  # @param [String, Hash, ActionController::Parameters, Model, nil] attr
  #
  # @return [Hash]
  #
  # @note Currently unused.
  #
  def generate_file_data(data, attr)
    # noinspection RubyMismatchedArgumentType
    data = parse_file_data(data)
    afd  = parse_file_data(attr&.dig(:file_data))
    # noinspection RubyNilAnalysis
    data.merge!(afd)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Class methods automatically added to the including record class.
  #
  module ClassMethods
    include Record::FileData
  end

  # Instance implementations to be included if the schema has an
  # FILE_DATA_COLUMN column.
  #
  module InstanceMethods

    include Record::FileData

    # =========================================================================
    # :section: Record::FileData overrides
    # =========================================================================

    public

    def generate_file_data(data, attr = nil)
      # noinspection RubyMismatchedArgumentType
      super(data, (attr || self))
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Present :file_data as a structured object (if it is present).
    #
    # @return [Hash] # TODO: ???
    #
    # @note Currently unused.
    #
    def emma_file_record
      @emma_file_record ||= make_file_record(emma_file_data)
    end

    # Present :file_data as a hash (if it is present).
    #
    # @return [Hash{Symbol=>Any}]
    #
    # @note Invoked only from methods which are currently unused.
    #
    def emma_file_data
      @emma_file_data ||= parse_file_data(file_data, true)
    end

    # Set the :file_data field value (if not #FILE_DATA_HASH).
    #
    # @param [Hash, String, nil] data
    # @param [Boolean]           allow_blank
    #
    # @return [String]                New value of :file_data
    # @return [nil]                   ...if *data* is *nil*.
    #
    # @note Currently unused.
    #
    def set_file_data(data, allow_blank = true)
      @emma_file_record = nil # Force regeneration.
      @emma_file_data   = parse_file_data(data, allow_blank)
      self[:file_data]  =
        case data
          when nil    then data
          when String then data.dup
          else             @emma_file_data.to_json
        end
    end

    # Selectively modify the :file_data field value (if not #FILE_DATA_HASH).
    #
    # @param [Hash]    data
    # @param [Boolean] allow_blank
    #
    # @return [String]                New value of :file_data.
    # @return [nil]                   If no change and :file_data was *nil*.
    #
    # @note Currently unused.
    #
    def modify_file_data(data, allow_blank = true)
      if (new_file_data = parse_file_data(data, allow_blank)).present?
        @emma_file_record = nil # Force regeneration.
        @emma_file_data   = emma_file_data.merge(new_file_data)
        self[:file_data]  = @emma_file_data.to_json
      end
      self[:file_data]
    end

  end

  module InstanceMethods

    # Set the :file_data field value hash.
    #
    # @param [Hash, String, nil] data
    # @param [Boolean]           allow_blank
    #
    # @return [String]                New value of :file_data
    # @return [nil]                   ...if *data* is *nil*.
    #
    # @note Currently unused.
    #
    def set_file_data(data, allow_blank = true)
      @emma_file_record = nil # Force regeneration.
      @emma_file_data   = parse_file_data(data, allow_blank)
      self[:file_data]  = data && @emma_file_data.deep_stringify_keys
    end

    # Selectively modify the :file_data field value hash.
    #
    # @param [Hash]    data
    # @param [Boolean] allow_blank
    #
    # @return [Hash{String=>Any}]     New value of :file_data
    # @return [nil]                   If no change and :file_data was *nil*.
    #
    # @note Currently unused.
    #
    def modify_file_data(data, allow_blank = true)
      if (new_file_data = parse_file_data(data, allow_blank)).present?
        @emma_file_record = nil # Force regeneration.
        @emma_file_data   = emma_file_data.merge(new_file_data)
        self[:file_data]  = @emma_file_data.deep_stringify_keys
      end
      self[:file_data]
    end

  end if FILE_DATA_HASH

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  THIS_MODULE = self

  included do |base|

    __included(base, THIS_MODULE)
    assert_record_class(base, THIS_MODULE)

    include InstanceMethods if has_column?(FILE_DATA_COLUMN)

  end

end

__loading_end(__FILE__)
