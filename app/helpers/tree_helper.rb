# app/helpers/tree_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper methods supporting the creation of tree controls.
#
module TreeHelper

  include HtmlHelper
  include PanelHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Configuration for tree control properties.
  #
  # @type [Hash]
  #
  TREE_CTRL_CFG = config_page_section(:tree, :control).deep_freeze

  # Label for button to open a collapsed tree.
  #
  # @type [ActiveSupport::SafeBuffer]
  #
  TREE_OPENER_LABEL = non_breaking(TREE_CTRL_CFG[:label]).freeze

  # Tooltip for button to open a collapsed tree.
  #
  # @type [String]
  #
  TREE_OPENER_TIP = TREE_CTRL_CFG[:tooltip]

  # Label for button to close an expanded tree.
  #
  # @type [ActiveSupport::SafeBuffer]
  #
  TREE_CLOSER_LABEL = non_breaking(TREE_CTRL_CFG.dig(:open, :label)).freeze

  # Tooltip for button to close an expanded tree.
  #
  # @type [String]
  #
  TREE_CLOSER_TIP = TREE_CTRL_CFG.dig(:open, :tooltip)

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Tree open/close control.
  #
  # @param [Hash] opt                 Passed to PanelHelper#toggle_button.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see file:app/assets/javascripts/feature/search.js
  #
  def tree_button(**opt)
    opt[:label]   ||= opt[:open] ? TREE_CLOSER_LABEL : TREE_OPENER_LABEL
    opt[:title]   ||= opt[:open] ? TREE_CLOSER_TIP   : TREE_OPENER_TIP
    opt[:context] ||=
      unless css_class_array(opt[:class]).any? { _1.start_with?('for-') }
        'for-tree'
      end
    toggle_button(**opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    __included(base, self)
  end

end

__loading_end(__FILE__)
