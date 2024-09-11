# app/models/config_entry.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# The base class for collections of configuration-related values.
#
class ConfigEntry < Hash

  include Emma::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Create a new instance.
  #
  # @param [ConfigEntry, Hash, nil] src
  #
  # @raise [RuntimeError]             If *src* is invalid.
  #
  def initialize(src = nil)
    if src.is_a?(self.class)
      update(src.deep_dup)
    elsif src.is_a?(Hash) && !src.is_a?(ConfigEntry)
      src.each_pair { self[_1.to_sym] = config_value(_2) }
    elsif !src.nil?
      raise "Not a Hash or subclass of #{self.class}: #{src.inspect}"
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Transform an item into the expected value type (if one is defined by the
  # subclass).
  #
  # @param [any, nil] item
  #
  # @return [any, nil]
  #
  def config_value(item)
    value_type&.wrap(item) || item.dup
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  # Return *item* if it is already an instance of the subclass; if not, use it
  # to initialize a new subclass instance.
  #
  # @param [any, nil] item
  #
  # @return [ConfigEntry]
  #
  def self.wrap(item)
    item.is_a?(self_class) ? item.dup : new(item)
  end

  # The expected value type defined by the subclass.
  #
  # @return [Class, nil]
  #
  def self.value_type
    may_be_overridden
  end

  # Indicate whether an item can be directly assigned as a value in a subclass.
  #
  # (Always *true* if the subclass does not define a value type.)
  #
  # @param [any, nil] item
  #
  def self.value_type?(item)
    value_type.nil? || item.is_a?(value_type)
  end

  delegate :wrap, :value_type, :value_type?, to: :class

end

# A configuration entry for a field for a specific controller/action.
#
class FieldConfig < ConfigEntry

  # Create a new instance.
  #
  # @param [FieldConfig, Hash, nil] src
  #
  # @raise [RuntimeError]             If *src* is invalid.
  #
  def initialize(src = nil)
    super
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  def self.value_type = nil

  def self.value_type?(*) = true

  EMPTY = new.freeze

end

# A configuration entry for a set of fields for a specific controller/action.
#
class ActionConfig < ConfigEntry

  # Create a new instance.
  #
  # @param [ActionConfig, Hash, nil] src
  #
  # @raise [RuntimeError]             If *src* is invalid.
  #
  def initialize(src = nil)
    super
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  def self.value_type = FieldConfig

  def self.value_type?(value) = value.is_a?(value_type)

  EMPTY = new.freeze

end

# A set of configuration entries for the actions of a controller.
#
# Two entries are guaranteed:
#
# * :all is the configuration for fields which is not specific to an action.
# * :database is the configuration for fields in the context of displaying
#   records from the database.
#
# The presence of other entries depends on the '/config/controllers/**.yml'
# contents for the given controller.
#
class ModelConfig < ConfigEntry

  # Return with the generic field configurations followed by entries for
  # each action-specific field configuration.
  #
  # @param [ModelConfig, ActionConfig, Hash, nil] src
  # @param [ActionConfig, Hash, nil] all        Generic config
  # @param [ActionConfig, Hash, nil] database   Database-specific config.
  # @param [Hash, nil]               synthetic  Synthetic field properties.
  # @param [Hash]                    opt        Action-specific configs.
  #
  def initialize(src = nil, all: nil, database: nil, synthetic: nil, **opt)
    # Generic entries not specific to any action are the first key/value pair.
    # (All fields will be set up in the expected order if initializing a copy.)
    if src.is_a?(self_class)
      update(src.deep_dup)
    else
      src ||= all
      all ||= src || opt.values.first
      self[:all] = config_value(all)
    end
    raise "invalid: #{src.inspect}" unless src.nil? || value_type?(self[:all])

    # Add extra definitions of fields which do not map on to data columns.
    if synthetic && (added = synthetic.keys - self[:all].keys).present?
      added_fields =
        synthetic.slice(*added).map { |field, entry|
          entry = Field.normalize(entry, field).merge!(synthetic: true)
          [field, entry]
        }.to_h
      self[:all] = config_value(self[:all].merge(added_fields))
    end

    # Identify the fields which map on to database columns in the second
    # key/value pair.
    database &&= config_value(database)
    database ||= self[:database]
    database ||= config_value(self[:all].reject { |_, e| e[:synthetic] })
    self[:database] = database

    # Entries for the third and subsequent action-specific field configurations
    if opt.present?
      update(opt.symbolize_keys!.transform_values! { config_value(_1) })
    end
  end

  # ===========================================================================
  # :section: Hash overrides
  # ===========================================================================

  public

  def empty?
    values.all?(&:empty?)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Generic field configurations.
  #
  # @return [ActionConfig]
  #
  def all
    self[:all]
  end

  # Database field configurations.
  #
  # @return [ActionConfig]
  #
  def database
    self[:database]
  end

  # Fields which do not map on to data columns.
  #
  # @return [Hash{Symbol=>FieldConfig}]
  #
  def synthetic
    all.select { |_, entry| entry[:synthetic] }
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Report on anomalies.
  #
  # @param [any, nil] type
  # @param [Boolean]  fatal           If *true*, raise if there are error(s).
  #
  # @return [Boolean]                 If *fatal* is not *true*.
  #
  def validate(type: nil, fatal: false, **)
    fields  = transform_values(&:keys)
    generic = fields.delete(:all) || []
    diffs   = []
    fields.each_pair do |section, section_keys|
      expected  = generic
      expected -= synthetic.keys if section == :database
      missing   = (expected - section_keys).presence
      extra     = (section_keys - expected).presence
      diffs << "#{section}: missing fields #{missing.inspect}" if missing
      diffs << "#{section}: extra fields #{extra.inspect}"     if extra
    end
    return true if diffs.blank?
    msg = ['*** CONFIGURATION ***', type].compact.join(' ')
    sep = diffs.many? ? "\n" : '; '
    __debug(*diffs, leader: msg, separator: sep)
    fatal and raise(msg) or false
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  def self.value_type = ActionConfig

  def self.value_type?(value) = value.is_a?(value_type)

  EMPTY = new.freeze

end

__loading_end(__FILE__)
