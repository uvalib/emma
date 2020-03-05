# app/models/concerns/file_properties.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# A subclass of Hash used to encapsulate and manage the properties associated
# with downloaded and downloadable files.
#
# noinspection RubyTooManyMethodsInspection
class FileProperties < Hash

  include Emma::Debug
  include FileAttributes

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # File property keys along with keys which are treated as an alias for those
  # keys when initializing.
  #
  # Entries with these keys are always present (even if *nil*) and presented in
  # the order specified here.
  #
  # @type [Hash{Symbol=>Array<Symbol>}]
  #
  KEY_ALIAS_MAP = {
    repository:   %i[repo],
    repositoryId: %i[repository_id id],
    fmt:          %i[type],
    ext:          nil,
    filename:     %i[file_name file],
  }.transform_values { |v| Array.wrap(v) }.deep_freeze

  # Each key and key alias (as Symbol and as String) mapped to the file
  # property key it aliases.
  #
  # @type [Hash{Symbol,String=>Symbol}]
  #
  ALIAS_KEY_MAP =
    KEY_ALIAS_MAP.flat_map { |key, aliases|
      aliases.map { |key_alias| [key_alias, key] } << [key, key]
    }.sort.to_h.tap { |h| h.merge!(h.stringify_keys) }.deep_freeze

  # File property keys.
  #
  # @type [Array<Symbol>]
  #
  KEYS = KEY_ALIAS_MAP.keys.freeze

  # All keys recognized as special by the class.
  #
  # In particular, entries with these keys cannot be deleted.
  #
  # @type [Array<Symbol,String>]
  #
  RESERVED_KEYS = ALIAS_KEY_MAP.keys.deep_freeze

  # PROPERTY_ENTRIES_TEMPLATE
  #
  # @type [Hash{Symbol=>nil}]
  #
  PROPERTY_ENTRIES_TEMPLATE = KEYS.map { |k| [k, nil] }.to_h.freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Initialize a new instance.
  #
  # @param [FileProperties, Hash, nil] src
  # @param [Boolean]                   complete
  #
  def initialize(src, complete: false)
    hash_replace(PROPERTY_ENTRIES_TEMPLATE)
    update!(src) if src.present?
  end

  # ===========================================================================
  # :section: FileAttributes overrides
  # ===========================================================================

  public

  # repository
  #
  # @return [String, nil]
  #
  # This method overrides
  # @see FileAttributes#repository
  #
  def repository
    self[:repository]
  end

  # repository_id
  #
  # @return [String, nil]
  #
  # This method overrides
  # @see FileAttributes#repository_id
  #
  def repository_id
    self[:repositoryId]
  end

  # fmt
  #
  # @return [Symbol, nil]
  #
  # This method overrides
  # @see FileAttributes#fmt
  #
  def fmt
    self[:fmt]
  end

  # ext
  #
  # @return [String, nil]
  #
  # This method overrides
  # @see FileAttributes#ext
  #
  def ext
    self[:ext]
  end

  # filename
  #
  # @return [String, nil]
  #
  # This method overrides
  # @see FileAttributes#filename
  #
  def filename
    self[:filename]
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # property_keys
  #
  # @return [Array<Symbol>]
  #
  def property_keys
    KEYS
  end

  # property_entries
  #
  # @return [Hash]
  #
  def property_entries
    slice(*property_keys)
  end

  # added_keys
  #
  # @return [Array<Symbol>]
  #
  def added_keys
    keys - property_keys
  end

  # added_entries
  #
  # @return [Hash]
  #
  def added_entries
    slice(*added_keys)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  def property?(key)
    KEYS.include?(key)
  end

  def reserved?(key)
    RESERVED_KEYS.include?(key)
  end

  def normalize_key(key)
    ALIAS_KEY_MAP[key] || key
  end

  def normalize_keys(*keys)
    keys.flatten.map { |key| normalize_key(key) }
  end

  # ===========================================================================
  # :section: Object overrides
  # ===========================================================================

  public

  # @return [FileProperties]
  def dup
    self.class.new(to_h)
  end

  # ===========================================================================
  # :section: Hash overrides
  # ===========================================================================

  public

  alias_method :hash_delete,  :delete
  alias_method :hash_replace, :replace
  alias_method :hash_merge!,  :merge!

  # @return [Hash]
  def to_h
    Hash[self]
  end

  # Ensure that regular String conversion operates like Hash#to_s.
  #
  # @return [String]
  #
  # Compare with:
  # @see Hash#inspect
  #
  def to_s
    super
  end

  # Show file properties along with other entries that may have been added.
  #
  # @param [String] leader            Added to the beginning of each line.
  # @param [String] separator         Line separator.
  #
  # @return [String]
  #
  # This method overrides:
  # @see Hash#inspect
  #
  def inspect(leader: nil, separator: "\n")
    result = []
    result << 'repo = %s' % self[:repository].inspect
    result << 'id   = %s' % self[:repositoryId].inspect
    result << 'fmt  = %s' % self[:fmt].inspect
    result << 'ext  = %s' % self[:ext].inspect
    result << 'file = %s' % self[:filename].inspect
    result << 'added  %s' % added_entries.to_s if added_keys.present?
    if leader.present?
      leader = "#{leader} | " unless leader.end_with?(' ')
      result.map! { |line| "#{leader}#{line}" }
    end
    result.join(separator)
  end

  def ==(other)
    if other.is_a?(self.class)
      super(other)
    elsif !other.is_a?(Hash)
      false
    elsif keys != other.keys.map { |k| normalize_key(k) }.uniq
      false
    else
      other.all? { |k, v| v == self[normalize_key(k)] }
    end
  end

  def fetch(key, &block)
    super(normalize_key(key), &block)
  end

  def store(key, value)
    super(normalize_key(key), value)
  end

  def default(key = nil)
    super(key) unless reserved?(key)
  end

  # Indicate whether this instance has nothing set.
  #
  def empty?
    property_entries.values.compact.empty? && added_entries.empty?
  end

  alias_method :blank?, :empty?

  def transform_keys(&block)
    dup.transform_keys!(&block)
  end

  def transform_keys!
    super unless block_given?
    if added_keys.present?
      old_entries = added_entries
      new_entries = old_entries.map { |k, v| [yield(k), v] }.to_h
      old_entries.keys.each { |k| hash_delete(k) }
      hash_merge!(new_entries)
    end
    self
  end

  def values_at(*keys)
    super(*normalize_keys(keys))
  end

  def fetch_values(*keys, &block)
    super(*normalize_keys(keys), &block)
  end

  def shift
    raise "Not permitted for #{self.class}"
  end

  def delete(key, &block)
    if reserved?(key)
      yield(key) if block_given?
    else
      super(key, &block)
    end
  end

  def delete_if
    super unless block_given?
    added_keys.each { |k| hash_delete(k) if yield(k, self[k]) }
    self
  end

  def keep_if
    super unless block_given?
    added_keys.each { |k| hash_delete(k) unless yield(k, self[k]) }
    self
  end

  def select(&block)
    dup.keep_if(&block)
  end

  alias_method :filter, :select

  def select!
    super unless block_given?
    to_delete = added_keys.map { |k| k unless yield(k, self[k]) }.compact
    to_delete.each { |k| hash_delete(k) }
    self if to_delete.present?
  end

  alias_method :filter!, :select!

  def reject(&block)
    dup.delete_if(&block)
  end

  def reject!
    super unless block_given?
    to_delete = added_keys.map { |k| k if yield(k, self[k]) }.compact
    to_delete.each { |k| hash_delete(k) }
    self if to_delete.present?
  end

  # Returns a hash containing only the given keys and their values.
  #
  # @param [Array<Symbol,String>] keys
  #
  # @return [Hash]                    NOTE: Hash not FileProperties
  #
  def slice(*keys)
    to_h.slice(*normalize_keys(keys))
  end

  def clear
    super
    hash_replace(PROPERTY_ENTRIES_TEMPLATE)
    self
  end

  def replace(other_hash)
    clear
    merge!(other_hash)
  end

  def merge!(*hashes, &block)
    copy!(*hashes, safe: false, &block)
  end

  alias_method :update, :merge!

  def merge(*hashes, &block)
    dup.merge!(*hashes, &block)
  end

  def compact
    self.class.new(property_entries).hash_merge!(added_entries.compact)
  end

  def compact!
    reject! { |_, v| v.nil? }
  end

  def dig(key, *keys)
    super(normalize_key(key), *keys)
  end

  def key?(key)
    super(normalize_key(key))
  end

  alias_method :include?, :key?
  alias_method :member?,  :key?
  alias_method :has_key?, :key?

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Fill in file properties from other source(s), retaining properties that
  # already have a value.
  #
  # @param [Array<Hash>] hashes
  #
  # @return [self]
  #
  # @see #copy!
  #
  def update!(*hashes, &block)
    copy!(*hashes, safe: true, &block)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Copy values from one or more hashes.
  #
  # @param [Array<Hash>] hashes
  # @param [Boolean]     safe         If *true*, retain file properties that
  #                                     already have a value.
  #
  # @return [self]
  #
  def copy!(*hashes, safe:, &block)
    hashes.each do |hash|
      extra = hash.except(*RESERVED_KEYS)
      hash  = hash.slice(*RESERVED_KEYS)
      KEY_ALIAS_MAP.each_pair do |key, aliases|
        next if safe && self[key]
        value =
          [key, *aliases].find do |k|
            break hash[k]      if hash.key?(k)
            break hash[k.to_s] if hash.key?(k.to_s)
          end
        value = yield(key, self[key], value) if block_given?
        self[key] = value
        self[key] &&=
          case key
            when :fmt then value.to_sym
            when :ext then value.to_s.strip.delete_prefix(EXT_SEPARATOR)
            else           value.to_s
          end
      end
      hash_merge!(extra, &block)
    end
    self
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  # Create a new instance from the provided collection of values.
  #
  # @overload FileProperties[args]
  #   @param [Hash] args
  #
  # @overload FileProperties[args]
  #   @param [Array] args             where:
  #
  #   args[0] [String, nil]           repository
  #   args[1] [String, nil]           repository_id
  #   args[2] [String, Symbol, nil]   fmt
  #   args[3] [String, nil]           ext
  #   args[4] [String, nil]           filename
  #
  # @return [FileProperties]
  #
  def self.[](*args)
    opt = (args.first if args.first.is_a?(Hash))
    opt ||= KEYS.map { |k| [k, args.shift.presence] }.to_h
    FileProperties.new(opt)
  end

  # Partition options into file properties and everything else.
  #
  # @param [Hash, nil] hash
  #
  # @return [Array<(FileProperties,Hash)>]
  #
  def self.partition_options(hash)
    hash ||= {}
    prop = hash.slice(*RESERVED_KEYS)
    opt  = hash.except(*prop.keys)
    prop = new(prop, complete: false)
    return prop, opt
  end

end

__loading_end(__FILE__)
