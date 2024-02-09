# app/models/concerns/record/rendering.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Utility methods for reporting on records.
#
# @note From UploadWorkflow::Errors::RenderMethods
#
module Record::Rendering

  include Emma::Common

  extend self

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Default label.
  #
  # @type [String]
  #
  # @note From UploadWorkflow::Errors::RenderMethods#DEFAULT_LABEL
  #
  DEFAULT_LABEL = config_text(:record, :missing)

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Show the submission ID if it can be determined for the given item(s).
  #
  # @param [any, nil] item            Model, Hash, String
  # @param [String]   default
  #
  # @return [String]
  #
  # @note From Upload::RenderMethods#make_label
  # @note From Upload::Errors::RenderMethods#make_label
  #
  def make_label(item, default: DEFAULT_LABEL)
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
  # @param [any, nil] item            Model, Hash, String
  #
  # @return [String, nil]
  #
  # === Implementation Notes
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
    base.extend(self)
  end

end

__loading_end(__FILE__)
