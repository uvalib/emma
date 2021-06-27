# app/helpers/link_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper methods supporting the creation of links.
#
module LinkHelper

  # @private
  def self.included(base)
    __included(base, 'LinkHelper')
  end

  include Emma::Common
  include HtmlHelper
  include I18nHelper
  include RouteHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # TODO: I18n
  #
  # @type [String]
  #
  ANOTHER = 'another'

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Create a link element to an application action target.
  #
  # @param [String, nil]    label         Label passed to #make_link.
  # @param [Hash]           link_opt      Options passed to #make_link.
  # @param [Hash, Array]    path          Default: params :controller/:action.
  # @param [Hash]           path_opt      Path options.
  #
  # @return [ActiveSupport::SafeBuffer]   HTML link element.
  # @return [nil]                         A valid URL could not be determined.
  #
  def link_to_action(label, link_opt: nil, path: nil, **path_opt)
    css_selector = '.control'
    # noinspection RubyNilAnalysis
    ctrlr, action =
      case path
        when Hash then path.values_at(:controller, :action)
        else           Array.wrap(path)
      end
    ctrlr   ||= params[:controller]
    action  ||= params[:action]
    path      = get_path_for(ctrlr, action, **path_opt) or return
    look_opt  = { controller: ctrlr }
    label   ||= config_lookup("#{action}.label", **look_opt) || path
    html_opt  = prepend_classes(link_opt, css_selector)
    html_opt[:method] ||= :delete if action == :destroy
    html_opt[:title]  ||= config_lookup("#{action}.tooltip", **look_opt)
    # noinspection RubyYardParamTypeMatch
    if path.match?(/^https?:/)
      external_link(label, path, **html_opt)
    else
      make_link(label, path, **html_opt)
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # page_action_entry
  #
  # @param [String, Symbol, nil]     action   The target controller action.
  # @param [String, Symbol, nil]     current  Def: current `params[:action]`.
  # @param [Hash{Symbol=>Hash}, nil] table    Def: `#page_action_links`.
  # @param [Hash]                    opt      Passed to #page_action_links.
  #
  # @return [Hash{Symbol=>String}]
  #
  def page_action_entry(action = nil, current: nil, table: nil, **opt)
    current = (current || params[:action])&.to_sym
    action  = (opt.delete(:action) || action || current)&.to_sym
    table ||= page_action_links(**opt)
    entry   = table[action]
    return {} if entry.blank?
    (action == current) ? entry.merge(article: ANOTHER) : entry.dup
  end

  # page_action_link
  #
  # @param [String, Symbol, nil]     action   The target controller action.
  # @param [String, Symbol, nil]     current  Def: current `params[:action]`.
  # @param [String, nil]             label    Override configured label.
  # @param [String, nil]             path     Override configured action.
  # @param [Hash]                    opt      Passed to #page_action_entry.
  #
  # @return [ActiveSupport::SafeBuffer]   An HTML link element.
  # @return [nil]                         If *action* not configured.
  #
  def page_action_link(
    action = nil,
    current: nil,
    label:   nil,
    path:    nil,
    **opt
  )
    action ||= opt.delete(:action)
    entry    = page_action_entry(action, current: current, **opt)
    return if entry.blank? && path.blank?
    action   = entry[:action]
    label    = (label || entry[:label]).presence
    label  &&= label % entry
    label  ||= labelize(action)
    path   ||= { controller: opt[:controller], action: action }.compact
    html_tag(:li, class: 'page-action') do
      # noinspection RubyYardParamTypeMatch
      link_to_action(label, path: path)
    end
  end

  # List controller actions.  If the current action is provided, the associated
  # action link will be appear at the top of the list.
  #
  # @param [String, Symbol, nil]     current      Def: `params[:action]`
  # @param [Hash{Symbol=>Hash}, nil] table        Def: `#page_action_links`.
  # @param [Hash]                    opt          Passed to #page_action_links.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def page_action_list(current: nil, table: nil, **opt)
    table ||= page_action_links(**opt)
    link_opt = { current: current, table: table }
    html_tag(:ul, class: 'page-actions') do
      # noinspection RubyNilAnalysis
      links = table.keys.map { |action| page_action_link(action, **link_opt) }
      first = links.index { |link| link.include?(ANOTHER) }
      first ? [links.delete_at(first), *links] : links
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Action links configured for the controller.
  #
  # @param [String, Symbol, nil] controller   Default: `params[:controller]`.
  # @param [String, Symbol, nil] action       Default: *nil*.
  # @param [Hash]                opt          Passed to #config_lookup.
  #
  # @return [Hash]
  #
  def page_action_links(controller: nil, action: nil, **opt)
    controller ||= request_parameters[:controller]
    config_path  = [action, 'action_links'].compact.join('.')
    config_lookup(config_path, controller: controller, **opt) || {}
  end

  # Generate a menu of database item entries.
  #
  # @param [Symbol, String, nil] controller   Default: `params[:controller]`
  # @param [Symbol, String, nil] action       Default: `params[:action]`
  # @param [Class]               model
  # @param [User, String, nil]   user         Default: `current_user`
  # @param [String, nil]         prompt
  # @param [Hash{Symbol=>Hash}]  table
  # @param [Hash]                opt          Passed to #form_tag except for:
  #
  # @option opt [String, Hash] :ujs
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def page_items_menu(
    controller: nil,
    action:     nil,
    model:,
    user:       nil,
    prompt:     nil,
    table:      nil,
    **opt
  )
    css_selector = '.select-entry'
    controller ||= params[:controller]
    action     ||= params[:action]
    table      ||= page_action_links(controller: controller)

    action = table.dig(action&.to_sym, :action) || action
    # noinspection RubyYardParamTypeMatch
    path   = send(route_helper(controller, action))

    items = nil
    if !model.is_a?(Class)
      raise "model: expected Class; got #{model.class}"
    elsif !(model < ApplicationRecord)
      raise "invalid model #{model.inspect}"
    elsif !(model <= User)
      # noinspection RubyNilAnalysis
      user  = user.id if user.is_a?(User)
      items = model.where(user_id: user).order(:id) if user
    end
    items ||= model.all
    menu    = items.map { |item| [page_menu_label(item), item.id] }

    ujs = opt.delete(:ujs) || 'this.form.submit();'
    ujs = ujs.is_a?(Hash) ? ujs.dup : { onchange: ujs }
    select_opt = ujs.merge!(prompt: prompt || 'Select an entry') # TODO: I18n

    prepend_classes!(opt, css_selector, 'menu-control')
    opt[:method] ||= :get
    html_form(path, opt) do
      select_tag(:selected, options_for_select(menu), select_opt)
    end
  end

  # ===========================================================================
  # :section: Item forms (edit/delete pages)
  # ===========================================================================

  protected

  # page_menu_label
  #
  # @param [Model]       item
  # @param [String, nil] label        Override label.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def page_menu_label(item, label: nil)
    # noinspection RailsParamDefResolve
    label ||= item.try(:menu_label)
    label &&= ERB::Util.h(label.to_s)
    index   = ERB::Util.h(item.id.to_s.presence || '?')
    align   = ('&thinsp;&nbsp;' if index.size == 1)
    index   = "Entry #{align}#{index}" # TODO: I18n
    [index, label].compact.join(' - ').html_safe
  end

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
  # @param [String, Symbol, nil] type         Default: 'text'.
  # @param [String, nil]         text         Override text to display.
  # @param [String, Symbol, nil] controller   Default: `params[:controller]`.
  # @param [String, Symbol, nil] action       Default: `params[:action]`.
  # @param [String, Symbol, nil] tag          Tag for the internal text block.
  # @param [Hash]                opt          Passed to #html_div.
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
    **opt
  )
    css_selector = '.page-text-section'
    type   = type&.to_s&.delete_suffix('_html')&.to_sym || :text
    text ||= page_text(controller: controller, action: action, type: type)
    return if text.blank?
    text = tag ? html_tag(tag, text) : ERB::Util.h(text) unless text.html_safe?
    prepend_classes!(opt, css_selector)
    append_classes!(opt, *type) unless type == :text
    # noinspection RubyYardParamTypeMatch
    html_div(text, opt)
  end

end

__loading_end(__FILE__)
