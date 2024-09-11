# app/models/field/configuration.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

module Field::Configuration

  include Field::Property

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  DEFAULT_MODEL = :upload

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Sub-trees of the configuration that are visited when looking for a specific
  # field.  The first (*nil*) indicates the top-level -- i.e., where the field
  # is an ActionConfig key.  The others are meaningful only for the Upload
  # configuration -- e.g., allowing :dc_title to be found within the subtree
  # rooted at :emma_data.
  #
  # @type [Array<nil,Symbol,Array<Symbol>]
  #
  SUB_SECTIONS = [
    nil,                    # Properties of a database column field.
    :emma_data,             # Properties at :emma_recordId, :emma_titleId, etc.
    :file_data,             # Properties at :id, :storage, :metadata
    %i[filedata metadata],  # Properties at :filename, :size, :mimetype.
  ].deep_freeze

  # Configuration properties for a field within a given model/controller.
  #
  # @param [Symbol, String, Array, nil]  field
  # @param [Symbol, String, ModelConfig] model
  # @param [Symbol, String, nil]         action
  #
  # @return [FieldConfig]             Frozen result.
  #
  #--
  # === Variations
  #++
  #
  # @overload configuration_for(field, model = nil, action = nil)
  #   Look the named field in the configuration subtree for *action* if given
  #   and then in the :all subtree.  For hierarchical configurations (currently
  #   only for submissions), the top-level is checked for *field* and then
  #   the sub-sections within :emma_data, :file_data, and :file_data :metadata.
  #   @param [Symbol, String, nil]         field
  #   @param [Symbol, String, ModelConfig] model
  #   @param [Symbol, String, nil]         action
  #
  # @overload configuration_for(field_path, model = nil, action = nil)
  #   The field name to check is taken from the end of the array; the remainder
  #   is used to limit the sub-section to check.
  #   @param [Array<Symbol,String,Array>]  field_path
  #   @param [Symbol, String, ModelConfig] model
  #   @param [Symbol, String, nil]         action
  #
  def configuration_for(field, model, action = nil)
    subs  = field.is_a?(Array) ? (field[...-1] || []) : SUB_SECTIONS
    field = field.last if field.is_a?(Array)
    if subs.present? && (field = field&.to_sym).present?
      cfg  = model.is_a?(ModelConfig) ? model : Model.config_for(model)
      secs = cfg && Array.wrap(action).compact.map!(&:to_sym) << :all
      secs&.find do |section|
        next unless (section_cfg = cfg[section]).is_a?(Hash)
        ss_cfgs = subs.map { _1 ? section_cfg.dig(*_1) : section_cfg }
        ss_cfgs.find do |ss_cfg|
          next unless ss_cfg.is_a?(Hash)
          next unless (fld_cfg = ss_cfg[field]).is_a?(Hash)
          return FieldConfig.wrap(fld_cfg)
        end
      end
    end
    FieldConfig::EMPTY
  end

  # Find the field whose configuration entry has a matching label.
  #
  # @param [String, Symbol, nil]         label
  # @param [Symbol, String, ModelConfig] model
  # @param [Symbol, String, nil]         action
  #
  # @return [FieldConfig]      Frozen result.
  #
  def configuration_for_label(label, model, action = nil)
    if (label = label.to_s).present?
      subs = SUB_SECTIONS
      cfg  = model.is_a?(ModelConfig) ? model : Model.config_for(model)
      secs = cfg && Array.wrap(action).compact.map!(&:to_sym) << :all
      secs&.find do |section|
        next unless (section_cfg = cfg[section]).is_a?(Hash)
        ss_cfgs = subs.map { _1 ? section_cfg.dig(*_1) : section_cfg }
        ss_cfgs.find do |ss_cfg|
          next unless ss_cfg.is_a?(Hash)
          ss_cfg.values.find do |fld_cfg|
            next unless fld_cfg.is_a?(Hash)
            return FieldConfig.wrap(fld_cfg) if fld_cfg[:label] == label
          end
        end
      end
    end
    FieldConfig::EMPTY
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
