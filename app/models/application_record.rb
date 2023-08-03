# app/models/application_record.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Base class for database record models.
#
class ApplicationRecord < ActiveRecord::Base

  include SqlMethods

  self.abstract_class = true

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The explicit :org_id field if a model defines it, or the method defined by
  # the model to derive the ID of the Organization associated with the model
  # instance.
  #
  # @return [Integer, nil]
  #
  def org_id
    #Log.debug { "#{__method__}: not applicable to #{self.class}" }
  end

  # The explicit :user_id field if a model defines it, or the method defined by
  # the model to derive the ID of the User associated with the model instance.
  #
  # @return [Integer, nil]
  #
  def user_id
    #Log.debug { "#{__method__}: not applicable to #{self.class}" }
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # A textual label for the record instance.
  #
  # @param [ApplicationRecord, nil] item  Default: self.
  #
  # @return [String, nil]
  #
  # @see Api::Shared::TitleMethods#label
  #
  def label(item = nil)
    (item || self).id.to_s.presence
  end

  # menu_label
  #
  # @param [ApplicationRecord, nil] item  Default: self.
  #
  # @return [String, nil]
  #
  # @see BaseDecorator::Menu#items_menu_label
  #
  def menu_label(item = nil)
    label(item)
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  # Symbolic types for all record classes.
  #
  # @return [Array<Symbol>]
  #
  def self.model_types
    ApplicationRecord.subclasses.map(&:model_type)
  end

  # ===========================================================================
  # :section: Class and instance methods
  # ===========================================================================

  public

  # A representation of the model subclass for use in URL parameters.
  #
  # @return [Symbol]
  #
  def self.model_type
    model_name.singular.to_sym
  end

  # A URL parameter key denoting a model instance or its values.
  #
  # @type [Symbol]
  #
  def self.model_key
    model_type
  end

  # A URL parameter key denoting the identity of a model instance.
  #
  # @type [Symbol]
  #
  def self.model_id_key
    :"#{model_key}_id"
  end

  # The controller for the model/model instance.
  #
  # @type [Class]
  #
  def self.model_controller
    "#{model_type}_controller".camelize.safe_constantize
  end

  delegate :model_type, :model_key, :model_id_key, to: :class
  delegate :model_controller, to: :class

  # ===========================================================================
  # :section: Class and instance methods
  # ===========================================================================

  public

  def self.normalize_id_keys(arg, target = nil)
    return arg unless arg.is_a?(Hash) && arg.present?
    normalize_id_keys!(arg.dup, target)
  end

  def self.normalize_id_keys!(hash, target = nil)
    target_type = target&.model_type
    hash.extract!(*model_types).each_pair do |model, val|
      key = (model == target_type) ? :id : :"#{model}_id"
      Log.warn {
        "#{__method__}: #{key}: now #{val.inspect}; was: #{hash[key].inspect}"
      } if hash.key?(key)
      hash[key] = val
    end
    id_or_value = ->(v) { v.is_a?(ApplicationRecord) ? v.id : v }
    hash.transform_values! do |val|
      val.is_a?(Array) ? val.map(&id_or_value) : id_or_value.(val)
    end
  end

  delegate :normalize_id_keys, :normalize_id_keys!, to: :class

end

__loading_end(__FILE__)
