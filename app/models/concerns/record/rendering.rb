# app/models/concerns/record/rendering.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Utility methods for reporting on records.
#
# @note From Upload::RenderMethods
#
module Record::Rendering

  include Emma::Common

  extend self

  # ===========================================================================
  # :section: ApplicationRecord overrides
  # ===========================================================================

  public

  # menu_label
  #
  # @param [ApplicationRecord, nil] item      Default: self.
  # @param [String, nil]            default   Passed to #make_label
  #
  # @return [String, nil]
  #
  # @see BaseDecorator::Menu#items_menu_label
  #
  def menu_label(item = nil, default: nil, **)
    make_label((item || self), default: default)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Default label.
  #
  # @type [String]
  #
  # @note From Upload::RenderMethods#DEFAULT_LABEL
  #
  DEFAULT_LABEL = config_term(:record, :missing).freeze

  # Show the label or identifier for the given item.
  #
  # @param [any, nil]    item         Model, Hash, String
  # @param [Boolean]     ident        Append identifier if available.
  # @param [String, nil] default
  #
  # @return [String]
  #
  # @note From Upload::RenderMethods#make_label
  #
  def make_label(item, ident: false, default: DEFAULT_LABEL, **)
    label   = item.try(:label)
    ident ||= label.nil?
    ident &&= item.try(:identifier) || item_identity(item)
    ident &&= config_term(:record, :item, id: ident)
    # noinspection RubyMismatchedReturnType
    (label && ident) && "#{label} (#{ident})" || label || ident || default
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # SID or ID of *item*
  #
  # @param [any, nil]      item       Model, Hash, String
  # @param [Array<Symbol>] meths      Methods to attempt.
  #
  # @return [String, nil]
  #
  # === Implementation Notes
  # This exists solely to avoid a 'require' cycle by not making the module
  # dependent on Record::EmmaIdentification.
  #
  #--
  # noinspection RubyMismatchedReturnType
  #++
  def item_identity(item, meths: %i[sid_value id_value])
    meths.each { |meth| value = item.try(meth)             and return value }
    meths.each { |meth| value = try(meth, item)            and return value }
    meths.each { |meth| value = self.class.try(meth, item) and return value }
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    __included(base, self)
    base.extend(self)
  end

end

__loading_end(__FILE__)
