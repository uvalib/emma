# app/models/application_record.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Base class for database record models.
#
class ApplicationRecord < ActiveRecord::Base

  include IdMethods
  include SqlMethods

  include Emma::TypeMethods

  self.abstract_class = true

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The user associated with this record if applicable.
  #
  # @return [Integer, nil]
  #
  def user_id
    may_be_overridden
  end

  # The organization associated with this record if applicable.
  #
  # @return [Integer, nil]
  #
  def org_id
    may_be_overridden
  end

  # A short textual representation for the record instance.
  #
  # @param [ApplicationRecord, nil] item  Default: self.
  #
  # @return [String, nil]
  #
  def abbrev(item = nil)
    (item || self).id.to_s.presence
  end

  # A textual label for the record instance.
  #
  # @param [ApplicationRecord, nil] item  Default: self.
  #
  # @return [String, nil]
  #
  # @see Api::Shared::TitleMethods#label
  #
  def label(item = nil)
    abbrev(item)
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

  # A mapping of #model_key to #model_id_key for all record classes.
  #
  # @return [Hash{Symbol=>Symbol}]
  #
  def self.model_id_key_map
    ApplicationRecord.subclasses.map { |c| [c.model_key, c.model_id_key] }.to_h
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

  # Return the record instance indicated by the argument.
  #
  # @param [any, nil] v               Model, Hash, String, Integer
  #
  # @return [ApplicationRecord, nil]  A fresh record unless *v* is a *self*.
  #
  def self.instance_for(v)
    v &&= try_key(v, model_key) || v
    return v if v.is_a?(self) || v.nil?
    if (id = get_id(v, model_id_key))
      find_by(id: id)
    elsif (id = try_key(v, model_id_key)).is_a?(String)
      find_by(id: id)
    elsif v.is_a?(Hash)
      find_by(v) if (v = v.slice(*field_names)).present?
    end
  end

  delegate :model_type, :model_key, :model_id_key, to: :class
  delegate :model_controller, to: :class

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  # This is a convenience so that model classes can provide lists for use with
  # menus in the same way that EnumType#pairs does.
  #
  # @param [Symbol, String, Hash, Array, nil] sort      Default: :id
  # @param [Hash, nil]                        prepend   Added leading pair(s).
  # @param [Hash, nil]                        append    Added following pairs.
  # @param [Hash]                             opt       Terms passed to #where.
  #
  # @return [Hash]
  #
  # @see EnumType::Methods#pairs
  #
  def self.pairs(sort: nil, prepend: nil, append: nil, **opt, &blk)
    blk  ||= ->(rec) { [rec.id, rec.label] }
    sort ||= :id
    opt    = opt.presence
    user   = opt && extract_value!(nil, opt, :user)
    org    = opt && extract_value!(nil, opt, :org)
    case
      when user then recs = for_user(user, **opt)
      when org  then recs = for_org(org, **opt)
      when opt  then recs = where(**opt)
      else           recs = all
    end
    recs.order(sort).map(&blk).to_h.tap { |pairs|
      # noinspection RubyMismatchedArgumentType
      pairs.merge!(append)          if append.present?
      pairs.reverse_merge!(prepend) if prepend.present?
    }.stringify_keys!
  end

end

__loading_end(__FILE__)
