# app/models/concerns/record/rendering.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Utility methods for reporting on records.                                     # NOTE: from UploadWorkflow::Errors::RenderMethods
#
module Record::Rendering

  include Emma::Common

  extend self

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Default label. TODO: I18n                                                   # NOTE: from UploadWorkflow::Errors::RenderMethods
  #
  # @type [String]
  #
  DEFAULT_LABEL = '(missing)'

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Show the submission ID if it can be determined for the given item(s).
  #
  # @param [Model, Hash, String, Any, nil] item
  # @param [String]                        default
  #
  # @return [String]
  #
  def make_label(item, default: DEFAULT_LABEL)                                  # NOTE: from UploadWorkflow::Errors::RenderMethods
    # noinspection RailsParamDefResolve
    file  = item.try(:filename)
    ident = item.try(:identifier) || item_identity(item) || default
    ident = "Item #{ident}"      # TODO: look for :name field...
    ident = "#{ident} (#{file})" if file.present?
    ident
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # SID or ID of *item*
  #
  # @param [Model, Hash, String, Any, nil] item
  #
  # @return [String, nil]
  #
  # == Implementation Notes
  # This exists solely to avoid a 'require' cycle by not making the module
  # dependent on Record::EmmaIdentification.
  #
  def item_identity(item)
    # noinspection RubyMismatchedReturnType
    [self, self.class].find do |obj|
      %i[sid_value id_value].find do |meth|
        result = obj.try(meth, item) and return result
      end
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    __included(base, self)
    base.send(:extend, self)
  end

end

__loading_end(__FILE__)
