# app/helpers/layout_helper/page_sections.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Page sections.
#
module LayoutHelper::PageSections

  include LayoutHelper::Common

  include ConfigurationHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Supply an element containing a description for the current action context.
  #
  # @param [String, Array, nil] text  Override text to display.
  # @param [Hash]               opt   Passed to #page_text_section.
  #
  # @return [ActiveSupport::SafeBuffer]   An HTML element.
  # @return [nil]                         If no text was provided or defined.
  #
  def page_description_section(text = nil, **opt)
    page_text_section(:description, text, **opt)
  end

  # Supply an element containing directions for the current action context.
  #
  # @param [String, Array, nil] text  Override text to display.
  # @param [Hash]               opt   Passed to #page_text_section.
  #
  # @return [ActiveSupport::SafeBuffer]   An HTML element.
  # @return [nil]                         If no text was provided or defined.
  #
  def page_directions_section(text = nil, **opt)
    opt[:tag] = :h2 unless opt.key?(:tag)
    page_text_section(:directions, text, **opt)
  end

  # Supply an element containing additional notes for the current action.
  #
  # @param [String, Array, nil] text  Override text to display.
  # @param [Hash]               opt   Passed to #page_text_section.
  #
  # @return [ActiveSupport::SafeBuffer]   An HTML element.
  # @return [nil]                         If no text was provided or defined.
  #
  def page_notes_section(text = nil, **opt)
    page_text_section(:notes, text, **opt)
  end

  # Supply a section indicating a persistent warning condition.
  #
  # @param [String, Symbol]     type
  # @param [String, Array, nil] text  Override text to display.
  # @param [Hash]               opt   Passed to #page_text_section.
  #
  # @return [ActiveSupport::SafeBuffer]   An HTML element.
  # @return [nil]                         If no text was provided or defined.
  #
  def page_alert_section(type, text = nil, **opt)
    append_css!(opt, 'alert')
    page_text_section(type, text, type: type, **opt)
  end

  # Supply an element containing configured text for the current action.
  #
  # @param [String, Symbol, nil]  type        Default: 'text'.
  # @param [String, Array, nil]   text        Override text to display.
  # @param [String, Symbol, nil]  controller  Default: `params[:controller]`.
  # @param [String, Symbol, nil]  action      Default: `params[:action]`.
  # @param [Symbol, Integer, nil] tag         Tag for the internal text block.
  # @param [String]               css         Characteristic CSS class/selector
  # @param [Hash]                 opt         Passed to #html_div.
  #
  # @return [ActiveSupport::SafeBuffer]   An HTML element.
  # @return [nil]                         If no text was provided or defined.
  #
  def page_text_section(
    type = nil,
    text = nil,
    controller: nil,
    action:     nil,
    tag:        :p,
    css:        '.page-text-section',
    **opt
  )
    type   = type&.to_s&.delete_suffix('_html')&.to_sym || :text
    text ||= page_text(controller: controller, action: action, type: type)
    return if text.blank?
    refs   = Array.wrap(text).map { named_references(_1) }
    if (all_refs = refs.flatten).present?
      vals = opt.extract!(*all_refs)
      (all_refs - vals.keys).each do |ref|
        vals[ref] = respond_to?(ref) ? (send(ref) || ref.to_s) : '???'
      end
      edit = ->(t, i = 0) { (r = refs[i]).presence ? (t % vals.slice(*r)) : t }
      text = text.is_a?(Array) ? text.map.with_index(&edit) : edit.(text)
    end
    prepend_css!(opt, css)
    append_css!(opt, *type) unless type == :text
    html_div(**opt) do
      if tag.blank? || Array.wrap(text).all?(&:html_safe?)
        text
      else
        html_tag(tag, text)
      end
    end
  end

  # Get the configured page description.
  #
  # @param [String, Symbol, nil] controller   Default: `params[:controller]`
  # @param [String, Symbol, nil] action       Default: `params[:action]`
  # @param [String, Symbol, nil] type         Optional type under action.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [Array<String>]
  # @return [String]
  # @return [nil]
  #
  def page_text(controller: nil, action: nil, type: nil)
    controller ||= params[:controller]
    action     ||= params[:action]
    entry = config_page_section(controller, action)
    types = type ? Array.wrap(type).compact.map!(&:to_sym) : []
    types = %i[description text] if types.excluding(:description).blank?
    types.find do |t|
      if (text = entry[:"#{t}_html"]).present?
        case text
          when Array then return text.compact.join("\n").html_safe
          else            return text.html_safe? ? text : text.html_safe
        end
      elsif (text = entry[t.to_sym]).present?
        case text
          when Array then return text.map { _1.to_s.strip }
          else            return text.strip
        end
      end
    end
  end

end

__loading_end(__FILE__)
