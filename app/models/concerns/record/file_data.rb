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

  include Emma::Common
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
  # @param [Hash]              opt    Passed to #json_parse
  #
  # @return [Hash{String=>any,nil}]
  #
  def make_file_record(data, **opt)
    json_parse(data, symbolize_keys: false, **opt) || {}
  end

  # parse_file_data
  #
  # @param [String, Hash, nil] data
  # @param [Boolean]           allow_blank
  #
  # @return [Hash]
  #
  # @note Currently used only by unused methods.
  # :nocov:
  def parse_file_data(data, allow_blank = false)
    return {} if data.blank?
    result = make_file_record(data, fatal: true)
    raise 'array unexpected' if result.is_a?(Array)
    reject_blanks!(result)   unless allow_blank
    result.symbolize_keys!
  rescue => error
    Log.warn do
      msg = [__method__, error.message]
      msg << "for #{data.inspect}" if Log.debug?
      msg.join(': ')
    end
    re_raise_if_internal_exception(error) or {}
  end
  # :nocov:

  # generate_file_data
  #
  # @param [Hash, String, nil] data
  # @param [Hash, String, nil] attr
  #
  # @return [Hash]
  #
  # @note Currently unused.
  # :nocov:
  def generate_file_data(data, attr)
    data = parse_file_data(data)
    afd  = parse_file_data(attr&.dig(:file_data))
    data.merge!(afd)
  end
  # :nocov:

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
      attr ||= self
      super
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
    # :nocov:
    def emma_file_record
      @emma_file_record ||= make_file_record(emma_file_data)
    end
    # :nocov:

    # Present :file_data as a hash (if it is present).
    #
    # @return [Hash]
    #
    # @note Currently used only by unused methods.
    # :nocov:
    def emma_file_data
      @emma_file_data ||= parse_file_data(file_data, true)
    end
    # :nocov:

    # Set the :file_data field value (if not #FILE_DATA_HASH).
    #
    # @param [Hash, String, nil] data
    # @param [Boolean]           allow_blank
    #
    # @return [String]                New value of :file_data
    # @return [nil]                   ...if *data* is *nil*.
    #
    # @note Currently unused.
    # :nocov:
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
    # :nocov:

    # Selectively modify the :file_data field value (if not #FILE_DATA_HASH).
    #
    # @param [Hash]    data
    # @param [Boolean] allow_blank
    #
    # @return [String]                New value of :file_data.
    # @return [nil]                   If no change and :file_data was *nil*.
    #
    # @note Currently unused.
    # :nocov:
    def modify_file_data(data, allow_blank = true)
      if (new_file_data = parse_file_data(data, allow_blank)).present?
        @emma_file_record = nil # Force regeneration.
        @emma_file_data   = emma_file_data.merge(new_file_data)
        self[:file_data]  = @emma_file_data.to_json
      end
      self[:file_data]
    end
    # :nocov:

  end

  module InstanceMethods

    # Set the :file_data field value hash.
    #
    # @param [Hash, String, nil] data
    # @param [Boolean]           allow_blank
    #
    # @return [Hash{String=>any,nil}] New value of :file_data
    # @return [nil]                   ...if *data* is *nil*.
    #
    # @note Currently unused.
    # :nocov:
    def set_file_data(data, allow_blank = true)
      @emma_file_record = nil # Force regeneration.
      @emma_file_data   = parse_file_data(data, allow_blank)
      self[:file_data]  = data && @emma_file_data.deep_stringify_keys
    end
    # :nocov:

    # Selectively modify the :file_data field value hash.
    #
    # @param [Hash]    data
    # @param [Boolean] allow_blank
    #
    # @return [Hash{String=>any,nil}] New value of :file_data
    # @return [nil]                   If no change and :file_data was *nil*.
    #
    # @note Currently unused.
    # :nocov:
    def modify_file_data(data, allow_blank = true)
      if (new_file_data = parse_file_data(data, allow_blank)).present?
        @emma_file_record = nil # Force regeneration.
        @emma_file_data   = emma_file_data.merge(new_file_data)
        self[:file_data]  = @emma_file_data.deep_stringify_keys
      end
      self[:file_data]
    end
    # :nocov:

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
