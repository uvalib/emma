# app/helpers/help_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper methods for "/help" pages.
#
#--
# noinspection RubyTooManyMethodsInspection
#++
module HelpHelper

  include Emma::Common
  include Emma::Constants
  include Emma::Unicode

  include ApplicationHelper
  include HtmlHelper
  include LinkHelper
  include ParamsHelper
  include PopupHelper
  include SessionDebugHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Configuration for help pages properties.
  #
  # @type [Hash]
  #
  HELP_CONFIG = config_section(:help).deep_freeze

  # Help topics and values.
  #
  # Content (if present) is normalize to an array of HTML-safe sections.  If
  # both :content_html and :content are present, they will be combined in that
  # order to create a new :content value with one or more HTML-safe sections.
  #
  # Textual URLs are converted to links.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  HELP_ENTRY =
    HELP_CONFIG[:topic].map { |topic, entry|

      # Skip "_template" entry.
      next if topic.start_with?('_')
      entry = entry.deep_dup

      # Initialize naming definitions.
      entry[:topic] ||= topic.to_s.downcase
      entry[:Topic] ||= topic.to_s.split('_').map(&:camelcase).join('-')
      names = entry.slice(:topic, :Topic)

      # Make substitutions in property definitions.
      entry.except(*names.keys).each_pair do |k, v|
        if v.is_a?(String)
          entry[k] = v % names
        elsif v.is_a?(Array) && v.first.is_a?(String)
          entry[k] = v.map { |line| line % names }
        end
      end

      # Massage content if defined within the YAML file.
      text, html = entry.values_at(:content, :content_html)
      entry[:content] = entry[:content_html] =
        (html ? Array.wrap(html).map(&:html_safe) : Array.wrap(text)).map { |s|
          next if s.blank?
          s = ERB::Util.h(s) unless (safe = s.html_safe?)
          s.strip.gsub(%r{(?<=\s)https?://[^\s]+}) { |url|
            external_link(url)
          }.html_safe.then { |part|
            (safe && part.start_with?('<')) ? part : html_paragraph(part)
          }
        }.compact.presence&.join("\n")&.html_safe

      # The updated help topic entry.
      [topic, entry]

    }.compact.to_h.deep_freeze

  # Default text to display while help is loading asynchronously.
  #
  # @type [String]
  #
  HELP_PLACEHOLDER = config_term(:help, :placeholder).freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Create a container with a visible popup toggle button and a popup panel
  # which is initially hidden.
  #
  # @param [Symbol, String] topic
  # @param [Symbol, String] sub_topic   Starting HTML ID.
  # @param [String]         css         Characteristic CSS class/selector.
  # @param [Hash]           opt         Passed to #inline_popup except for:
  #
  # @option opt [Hash] :attr            Options for deferred content.
  # @option opt [Hash] :placeholder     Options for transient placeholder.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                       If *topic* is blank.
  #
  # @see file:javascripts/shared/modal-base.js *ModalBase.toggleModal()*
  #
  def help_popup(topic, sub_topic = nil, css: '.help-popup', **opt)
    return if topic.blank?
    topic, sub_topic = help_normalize(topic, sub_topic)
    title  = opt.delete(:title)
    p_opt  = opt.delete(:placeholder)
    attr   = opt.delete(:attr)&.dup || {}
    css_id = opt[:'data-iframe'] || attr[:id] || css_randomize("help-#{topic}")

    unless opt.dig(:control, :icon) && opt.dig(:control, :title)
      opt[:control] = opt[:control]&.dup || {}
      opt[:control][:icon]  ||= QUESTION
      opt[:control][:title] ||= title || HELP_ENTRY.dig(topic.to_sym, :tooltip)
    end

    unless opt.dig(:panel, :'aria-label')
      opt[:panel] = opt[:panel]&.dup || {}
      opt[:panel][:'aria-label'] ||= config_term(:help, :contents)
    end

    opt[:'aria-label'] ||= config_term(:help, :label)
    opt[:'data-iframe']  = attr[:id] = css_id

    prepend_css!(opt, css)
    inline_popup(**opt) do
      p_opt = prepend_css(p_opt, 'iframe', POPUP_DEFERRED_CLASS)
      p_opt[:'data-path']  = help_path(id: topic, modal: true)
      p_opt[:'data-attr']  = attr.to_json
      p_opt[:'data-topic'] = [topic, sub_topic, 'help'].compact.join('_')
      ph_txt = p_opt.delete(:text) || HELP_PLACEHOLDER
      html_div(ph_txt, **p_opt)
    end
  end

  # Values for a specific help topic.
  #
  # @param [Symbol, String] topic
  #
  # @return [Hash]
  #
  def help_topic_entry(topic)
    HELP_ENTRY[topic&.to_sym] || {}
  end

  # Normalize help topic and sub_topic.
  #
  # @param [Symbol, String]      topic
  # @param [Symbol, String, nil] sub_topic
  #
  # @return [Array(Symbol,Symbol)]
  # @return [Array(Symbol,nil)]
  #
  def help_normalize(topic, sub_topic = nil)
    topic     = help_topic(topic)
    sub_topic = sub_topic&.to_sym
    case [topic, sub_topic]
      when %i[account new]                then %i[organization add_user]
      when %i[account delete]             then %i[organization remove_user]
      when %i[account edit_select]        then %i[organization edit_user]
      when %i[account delete_select]      then %i[organization remove_user]
      when %i[organization show]          then %i[organization list_org]
      when %i[organization edit_select]   then %i[organization edit]
      when %i[organization delete_select] then %i[organization delete]
      when %i[upload edit_select]         then %i[upload edit]
      when %i[upload delete_select]       then %i[upload delete]
      when %i[upload repository]          then %i[upload repo_step]
      when %i[manifest edit_select]       then %i[manifest edit]
      when %i[manifest delete_select]     then %i[manifest delete]
      when %i[manifest remit_select]      then %i[manifest remit]
      else                                     [topic, sub_topic]
    end
  end

  # Normalize a help topic.
  #
  # @param [Symbol, String, nil] topic
  #
  # @return [Symbol, nil]
  #
  def help_topic(topic)
    return if topic.blank?
    # noinspection RubyMismatchedReturnType
    case (topic = topic.to_sym)
      when :org  then :organization
      when :user then :account
      else            topic
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Help topic names.
  #
  # @return [Array<Symbol>]
  #
  def help_topics
    HELP_ENTRY.select { |_, entry|
      enabled = entry[:enabled]
      (enabled == 'debug') ? session_debug? : (enabled.nil? || true?(enabled))
    }.keys
  end

  # Each help topic with its title.
  #
  # @param [Array<Symbol,Array, Hash>] topics   Default: `#help_topics`.
  #
  # @return [Hash{Symbol=>String}]
  #
  def help_titles(*topics)
    result = {}
    topics = topics.flatten(1)
    topics = help_topics if topics.blank?
    topics.each do |topic|
      if topic.is_a?(Hash)
        result.merge!(topic.symbolize_keys)
      else
        topic = topic.to_sym
        result[topic] = HELP_ENTRY.dig(topic, :title) || topic.to_s.capitalize
      end
    end
    result
  end

  # Title/link pairs for each help topic.
  #
  # The kind of links generated depend on the :type parameter value:
  #   :anchor - Page-relative (default)
  #   :path   - Site-relative links.
  #   :url    - Full URL links.
  #
  # @param [Array<Symbol,Array>] topics   Default: `#help_topics`.
  # @param [Symbol, nil]         type     Type of links; default: :anchor.
  # @param [Hash]                opt      Passed to route helper.
  #
  # @return [Array<Array(String,String)>]
  #
  def help_links(*topics, type: nil, **opt)
    type ||= :anchor
    opt  ||= {}
    opt[:modal] ||= modal?
    help_titles(*topics).map do |topic, title|
      case type
        when :path then [title, help_path(**opt.merge(id: topic))]
        when :url  then [title, help_url(**opt.merge(id: topic))]
        else            [title, "##{topic}_help"]
      end
    end
  end

  # A table of contents element with a link for each help topic.
  #
  # @param [Array<Symbol,Array>] topics   Passed to #help_links.
  # @param [Symbol, String]      tag      HTML tag for outer container.
  # @param [Array, String, nil]  before   Content before the links.
  # @param [Array, String, nil]  after    Content after the links.
  # @param [Hash]                opt      Passed to outer #html_div except for:
  #
  # @option opt [Symbol]        :type     Passed to #help_links.
  # @option opt [Hash]          :inner    Passed to inner link wrapper.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def help_toc(*topics, tag: :ul, before: nil, after: nil, **opt)
    link_type = opt.delete(:type)
    inner_opt = opt.delete(:inner)&.dup || {}
    inner_tag = inner_opt.delete(:tag)  || :li
    links =
      help_links(*topics, type: link_type).map do |title, path|
        html_tag(inner_tag, **inner_opt) { make_link(path, title) }
      end
    html_tag(tag, *before, *links, *after, **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Render help content parts within an HTML element.
  #
  # @param [Array<String, Array>] content
  # @param [Hash]                 opt       Passed to #html_div.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                           If no *content*.
  #
  def help_element(*content, **opt)
    content = help_paragraphs(*content)
    html_div(content, **opt) if content.present?
  end

  # Transform help content parts into an array of HTML entries.
  #
  # @param [Array<String, Array>] content
  #
  # @return [Array<ActiveSupport::SafeBuffer>]
  # @return [nil]                           If no *content*.
  #
  def help_paragraphs(*content)
    return if content.blank?
    content.flatten.map { |part|
      next if part.blank?
      safe = part.html_safe?
      part = part.to_s.strip
      part = part.html_safe if safe
      (safe && part.start_with?('<')) ? part : html_paragraph(part)
    }.compact.presence
  end

  # Render an image from "app/assets/images/help/*".
  #
  # @param [Symbol, String] name
  # @param [Hash]           opt       Passed to #image_tag.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def help_image(name, **opt)
    entry = HELP_CONFIG.dig(:image, name.to_sym)
    asset, alt = entry.is_a?(Hash) ? [entry[:asset], entry[:alt]] : entry
    asset     ||= "help/#{name}.png"
    opt[:alt] ||= alt || name.to_s.tr('_', ' ').capitalize << ' illustration'
    # noinspection RubyMismatchedReturnType
    image_tag(asset_path(asset), **opt)
  end

  # Render an illustration of a button element in help.
  #
  # @param [String] label
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt               Passed to #html_span.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def help_span(label, css: '.for-example', **opt)
    append_css!(opt, css)
    html_span(label, **opt)
  end

  # Render a help link within help text.
  #
  # @param [String]         label
  # @param [Symbol, String] topic
  # @param [Hash]           opt       Passed to #make_link.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def help_jump(label, topic, **opt)
    path = help_path(id: topic, modal: modal?)
    make_link(path, label, **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Render a single entry for use within a list of items.
  #
  # @param [Symbol, nil] item         Default: `#request_parameters[:id]`.
  # @param [Boolean]     wrap         If *false*, do not wrap.
  # @param [String]      css          Characteristic CSS class/selector.
  # @param [Hash]        opt          Passed to #help_container.
  #
  # @return [ActiveSupport::SafeBuffer]   Help contents section element.
  # @return [nil]                         No content and *wrap* is *false*.
  #
  def help_section(item: nil, wrap: true, css: '.help-section', **opt)
    prepend_css!(opt, css)
    help_container(item: item, wrap: wrap, **opt)
  end

  # Render a single entry for use within a list of items.
  #
  # @param [Symbol, nil] item         Default: `#request_parameters[:id]`.
  # @param [Boolean]     wrap         If *true*, wrap in a container element.
  # @param [Hash]        opt          Passed to #help_container.
  #
  # @return [ActiveSupport::SafeBuffer]   Help contents list element.
  # @return [nil]                         No content and *wrap* is *false*.
  #
  def help_list_item(item: nil, wrap: false, **opt)
    help_container(item: item, wrap: wrap, **opt)
  end

  # Render the contents of a single entry from configuration or from a partial.
  #
  # @param [Symbol, nil] item         Default: `#request_parameters[:id]`.
  # @param [Boolean]     wrap         Wrap in a "help-container" element.
  # @param [String]      css          Characteristic CSS class/selector.
  # @param [Hash]        opt          Passed to #html_div.
  #
  # @return [ActiveSupport::SafeBuffer]   Help contents element.
  # @return [nil]                         No content and *wrap* is *false*.
  #
  # @see config/locales/controllers/help.en.yml
  #
  def help_container(item: nil, wrap: true, css: '.help-container', **opt)
    topic     = help_topic(item || request_parameters[:id])
    partial   = "help/topic/#{topic}"
    content   = HELP_ENTRY.dig(topic, :content)
    content ||= (render(partial) if partial_exists?(partial))
    return content unless wrap
    row   = opt.delete(:row)
    row   = ("row-#{row}" if row)
    modal = ('modal'      if modal?)
    opt[:role] = 'article' if opt.delete(:level) == 1
    prepend_css!(opt, css, row, modal)
    html_div(content, **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Render a toggle for use on help pages.
  #
  # @param [String] label
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def help_toggle(label, css: '.toggle', **opt)
    prepend_css!(opt, css)
    help_span(label, **opt)
  end

  # Render a button for use on help pages.
  #
  # @param [String] label
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def help_button(label, css: '.control-button', **opt)
    prepend_css!(opt, css)
    help_span(label, **opt)
  end

  # Render an action menu button for use on help pages.
  #
  # @param [BaseDecorator, Class] decorator
  # @param [Symbol]               action
  # @param [Symbol]               button
  # @param [Hash]                 opt
  #
  # @return [ActiveSupport::SafeBuffer, nil]
  #
  def help_button_for(decorator, action, button, **opt)
    label   = decorator.form_actions.dig(action, button).presence
    label &&= label.dig(:if_enabled, :label) || label[:label]
    help_button(label, **opt) if label.present?
  end

  # Generate data about action shortcut icons for use on help pages.
  #
  # @param [BaseDecorator, Class] decorator
  #
  # @return [Hash{Symbol=>Hash}]
  #
  def help_shortcut_icons(decorator, actions: %i[show edit delete])
    actions.map { |action|
      prop = decorator.icon_definition(action)
      opt  = { title: prop[:spoken], class: "icon #{action}" }
      icon = html_span(**opt) { symbol_icon(prop[:icon]) }
      [action, { label: icon, value: prop[:tooltip]}]
    }.to_h
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  class FieldEntry

    include HtmlHelper

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # @return [Symbol]
    attr_reader :field

    # @return [ActiveSupport::SafeBuffer]
    attr_reader :label

    # @return [String]
    attr_reader :name

    # @return [ActiveSupport::SafeBuffer, nil]
    attr_reader :text

    # @return [ActiveSupport::SafeBuffer, nil]
    attr_reader :note

    # @return [String]
    attr_reader :id

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Create a new instance.
    #
    # @param [any, nil] base
    # @param [Hash]     cfg
    #
    def initialize(base: nil, **cfg)
      @field  = cfg[:field]
      @name   = cfg[:label]
      @label  = html_bold(@name)
      @id     = html_id(base, @name, separator: '_')
      @text   = text && html_span(text, class: 'text')
      @text   = text_value(cfg, :help, :tooltip)
      @text ||= '(TODO)' unless cfg.blank? # TODO: remove (?)
      @text &&= html_span(@text, class: 'text')
      @note   = text_value(cfg, :note, :notes)
      @note &&= html_div(@note, class: 'note')
    end

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    # Find an HTML or plain test value.
    #
    # @param [Hash]          cfg
    # @param [Array<Symbol>] names
    #
    # @return [String, nil]
    #
    def text_value(cfg, *names)
      # noinspection RubyMismatchedReturnType
      names.find do |name|
        if (value = cfg[:"#{name}_html"]&.strip).present?
          return value.html_safe? ? value : value.html_safe
        end
        if (value = cfg[name]&.strip).present?
          return value.match?(/[[:punct:]]$/) ? value : "#{value}."
        end
      end
    end

  end

  # help_field_entries
  #
  # @param [any, nil]      model      Symbol, String, Class, Model
  # @param [Array<Symbol>] names
  # @param [any, nil]      base
  #
  # @return [Hash{Symbol=>FieldEntry}]
  #
  def help_field_entries(model, *names, base: nil)
    model  = Model.for(model)
    base   = (base || model).to_s
    fields = Model.database_fields(model).to_h
    fields.slice!(*names) if names.present?
    fields.transform_values do |cfg|
      FieldEntry.new(base: base, **cfg)
    end
  end

  # A help entry for a model field description.
  #
  # @param [Symbol]                   fld
  # @param [Hash{Symbol=>FieldEntry}] fields
  # @param [String]                   css     Characteristic CSS class/selector
  # @param [Hash]                     opt
  #
  # @yield [entry] The enclosed content for the entry.
  # @yieldparam [FieldEntry] entry  Values related to the field.
  #
  def help_field(fld, fields:, css: '.field', **opt, &blk)
    entry = fields[fld] || FieldEntry.new(label: "(missing #{fld.inspect})")
    opt[:id]           ||= entry.id
    opt[:'data-field'] ||= fld
    prepend_css!(opt, css)
    html_div(**opt) do
      capture(entry, &blk)
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The introductory panel at the top of the Help index page.
  #
  # @param [Hash]   opt             Passed to the container.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def help_main_intro(**opt)
    meth = :help_offline
    docs = send(meth)
    cfg  = config_page_section(:help, :index)
    if (text = cfg[:intro_html]&.dup)
      docs = nil if text.sub!(%r{<p>%{#{meth}}</p>|%{#{meth}}}, docs)
      text = text.html_safe
      text << docs if docs
    elsif (text = cfg[:intro])
      text = text.split(/%{#{meth}}/).compact.map { |txt| html_paragraph(txt) }
      text = safe_join(text, docs)
    end
    html_div(**opt) do
      help_paragraphs(text || docs)
    end
  end

  # Render a numbered list container with links to each item in "/public/doc".
  #
  # @param [String] css             Characteristic CSS class/selector.
  # @param [Hash]   opt             Passed to the outer list container.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def help_offline(css: '.help-offline', **opt)
    prepend_css!(opt, css)
    html_ol(**opt) do
      base = Rails.root.join('public').to_s
      help_offline_items.map do |path|
        path.match(%r{^([^ ]+/)(\d+\.)(.*)(\(.*)$})
        name = $3.squish!
        file = "#{$2}#{$3}#{$4}"
        dir  = $1.delete_prefix(base)
        path = dir + ERB::Util.u(file)
        html_li do
          external_link(path, name)
        end
      end
    end
  end

  # Full directory paths to all "/public/doc" PDFs.
  #
  # @return [Array<String>]
  #
  def help_offline_items
    dir  = Rails.root.join('public', 'doc')
    base = "#{dir}/"
    Dir[dir.join('*.pdf')].sort_by { |s| s.delete_prefix(base).to_i }
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    __included(base, self)
    base.include(Emma::Unicode)
  end

end

__loading_end(__FILE__)
