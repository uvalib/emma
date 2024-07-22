# app/models/upload/render_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods to support rendering Upload records.
#
module Upload::RenderMethods

  include Emma::Common

  extend self

  # ===========================================================================
  # :section: ApplicationRecord overrides
  # ===========================================================================

  public

  # menu_label
  #
  # @param [Upload, nil] item         Default: self.
  # @param [String, nil] default      Passed to #make_label
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
  DEFAULT_LABEL = config_term(:record, :missing).freeze

  # Show the submission ID if it can be determined for the given item
  # annotated with the file associated with the submission.
  #
  # @param [any, nil]    item         Api::Record, Upload, Hash, String
  # @param [Boolean]     ident        Append identifier if available.
  # @param [String, nil] default
  #
  # @return [String, nil]
  #
  def make_label(item, ident: false, default: DEFAULT_LABEL, **)
    label   = Upload.sid_value(item)
    ident ||= label.nil?
    ident &&= Upload.id_value(item)
    ident &&= config_term(:record, :item, id: ident)
    label ||= ident
    file    = (item[:filename] || item['filename'] if item.is_a?(Hash))
    file  ||= item.try(:filename)
    # noinspection RubyMismatchedReturnType
    (label && file) && "#{label} (#{file})" || label || file || default
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
