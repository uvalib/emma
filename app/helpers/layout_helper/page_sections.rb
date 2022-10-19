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
  # @param [String, nil] text         Override text to display.
  # @param [Hash]        opt          Passed to #page_text_section.
  #
  # @return [ActiveSupport::SafeBuffer]   An HTML element.
  # @return [nil]                         If no text was provided or defined.
  #
  def page_description_section(text = nil, **opt)
    page_text_section(:description, text, **opt)
  end

  # Supply an element containing directions for the current action context.
  #
  # @param [String, nil] text         Override text to display.
  # @param [Hash]        opt          Passed to #page_text_section.
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
  # @param [String, nil] text         Override text to display.
  # @param [Hash]        opt          Passed to #page_text_section.
  #
  # @return [ActiveSupport::SafeBuffer]   An HTML element.
  # @return [nil]                         If no text was provided or defined.
  #
  def page_notes_section(text = nil, **opt)
    page_text_section(:notes, text, **opt)
  end

  # Supply an element containing configured text for the current action.
  #
  # @param [String, Symbol, nil]  type        Default: 'text'.
  # @param [String, nil]          text        Override text to display.
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
    interpolation_keys = named_references(text).presence
    text %= extract_hash!(opt, *interpolation_keys) if interpolation_keys
    text = tag ? html_tag(tag, text) : ERB::Util.h(text) unless text.html_safe?
    prepend_css!(opt, css)
    append_css!(opt, *type) unless type == :text
    html_div(text, opt)
  end

  # Get the configured page description.
  #
  # @param [String, Symbol, nil] controller   Default: `params[:controller]`
  # @param [String, Symbol, nil] action       Default: `params[:action]`
  # @param [String, Symbol, nil] type         Optional type under action.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [String]
  # @return [nil]
  #
  def page_text(controller: nil, action: nil, type: nil)
    controller ||= params[:controller]
    action     ||= params[:action]
    entry = controller_configuration(controller, action)
    types = Array.wrap(type).compact.map(&:to_sym)
    types = %i[description text] if types.blank? || types == %i[description]
    # noinspection RubyMismatchedReturnType
    types.find do |t|
      html  = "#{t}_html".to_sym
      plain = t.to_sym
      text  = entry[html]&.strip&.presence&.html_safe || entry[plain]&.strip
      return text if text.present?
    end
  end

end

__loading_end(__FILE__)
