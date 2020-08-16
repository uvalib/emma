# app/helpers/help_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# HelpHelper
#
module HelpHelper

  def self.included(base)
    __included(base, '[HelpHelper]')
    include Emma::Unicode
  end

  include Emma::Common
  include Emma::Constants
  include HtmlHelper
  include PopupHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

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
  #--
  # noinspection RailsI18nInspection
  #++
  HELP_ENTRY =
    I18n.t('emma.help.topic').map { |topic, entry|

      # Skip "_template" entry.
      next if topic.to_s.start_with?('_')

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
      html = entry[:content_html]
      text = entry[:content]
      content = html ? Array.wrap(html).map(&:html_safe) : Array.wrap(text)
      content.map! do |part|
        safe = part.html_safe?
        part = ERB::Util.h(part) unless safe
        part =
          part.strip.gsub(%r{(?<=\s)https?://[^\s]+}) { |url|
            external_link(url, url)
          }.html_safe
        (safe && part.start_with?('<')) ? part : html_tag(:p, part)
      end
      entry[:content] = entry[:content_html] =
        content.compact.presence&.join("\n")&.html_safe

      # The updated help topic entry.
      [topic, entry]

    }.compact.to_h.deep_freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Create a container with a visible popup toggle button and a popup panel
  # which is initially hidden.
  #
  # @param [Symbol, String] topic
  # @param [Symbol, String] sub_topic   Starting HTML ID.
  # @param [Hash]           opt         Passed to #popup_container except for:
  #
  # @option opt [Hash] :attr            Options for deferred content.
  # @option opt [Hash] :placeholder     Options for transient placeholder.
  #
  # @see togglePopup() in app/assets/javascripts/feature/popup.js
  #
  def help_popup(topic, sub_topic = nil, **opt)
    opt    = append_css_classes(opt, 'help-popup')
    ph_opt = opt.delete(:placeholder)
    attr   = opt.delete(:attr)&.dup || {}
    id     = opt[:'data-iframe'] || attr[:id] || css_randomize("help-#{topic}")

    opt[:'data-iframe'] = attr[:id] = id
    opt[:title] ||= HELP_ENTRY.dig(topic.to_sym, :tooltip)

    popup_container(**opt) do
      ph_opt = prepend_css_classes(ph_opt, 'iframe', POPUP_DEFERRED_CLASS)
      ph_txt = ph_opt.delete(:text) || 'Loading help topic...' # TODO: I18n
      ph_opt[:'data-path'] = help_path(id: topic, modal: true)
      ph_opt[:'data-attr'] = attr.to_json
      ph_opt[:'data-top']  = "#{topic}_#{sub_topic}_help" if sub_topic
      html_div(ph_txt, **ph_opt)
    end
  end

  # Values for a specific help topic.
  #
  # @param [Symbol, String] topic
  #
  # @return [Hash{Symbol=>*}]
  #
  def help_topic(topic)
    HELP_ENTRY[topic&.to_sym] || {}
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
    HELP_ENTRY.keys
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
  # @param [Hash]                opt      Passed to path helper.
  #
  # @return [Array<Array<(String,String)>>]
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
  # @param [Hash]                opt      Passed to outer #html_div except:
  #
  # @option opt [Symbol]        :type     Passed to #help_links.
  # @option opt [Symbol,String] :tag      Default: :ul.
  # @option opt [Hash]          :inner    Passed to inner #html_div.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def help_toc(*topics, **opt)
    opt, outer_opt = partition_options(opt, :type, :tag, :inner)
    link_type = opt[:type]
    outer_tag = opt[:tag] || :ul
    inner_opt = opt[:inner]&.dup || {}
    inner_tag = inner_opt.delete(:tag).presence || :li
    html_tag(outer_tag, **outer_opt) do
      help_links(*topics, type: link_type).map do |title, path|
        html_tag(inner_tag, **inner_opt) { link_to(title, path) }
      end
    end
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
  #
  def help_element(*content, **opt)
    html_div(**opt) { help_paragraphs(*content) }
  end

  # Transform help content parts into an array of HTML entries.
  #
  # @param [Array<String, Array>] content
  #
  # @return [Array<ActiveSupport::SafeBuffer>]
  #
  def help_paragraphs(*content)
    content.flatten.map { |part|
      next if part.blank?
      safe = part.html_safe?
      part = part.to_s.strip
      part = part.html_safe if safe
      (safe && part.start_with?('<')) ? part : html_tag(:p, part)
    }.compact
  end

  # Render an image from "app/assets/images/help/*".
  #
  # @param [Symbol, String] name
  # @param [Hash]           opt       Passed to #image_tag.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def help_image(name, **opt)
    entry = I18n.t("emma.help.image.#{name}", default: nil)
    asset, alt = entry.is_a?(Hash) ? [entry[:asset], entry[:alt]] : entry
    asset     ||= "help/#{name}.png"
    opt[:alt] ||= alt || name.to_s.tr('_', ' ').capitalize << ' illustration'
    # noinspection RubyYardReturnMatch
    image_tag(asset_path(asset), **opt)
  end

  # Render an illustration of a button element in help.
  #
  # @param [String] label
  # @param [Hash]   opt               Passed to #html_span.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def help_span(label, **opt)
    html_opt = append_css_classes(opt, 'for-help')
    html_span(label, html_opt)
  end

  # Render a help link within help text.
  #
  # @param [String]         label
  # @param [Symbol, String] topic
  # @param [Hash]           opt       Passed to #link_to.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def help_jump(label, topic, **opt)
    path = help_path(id: topic, modal: modal?)
    link_to(label, path, **opt)
  end

  # ===========================================================================
  # :section: Item list (index page) support
  # ===========================================================================

  public

  # Render a single entry for use within a list of items.
  #
  # @param [Symbol, nil] item         Default: `#request_parameters[:id]`.
  # @param [Boolean]     wrap         If *false*, do not wrap.
  # @param [Hash]        opt          Passed to #help_container.
  #
  # @return [ActiveSupport::SafeBuffer]   Help contents section element.
  # @return [nil]                         No content and *wrap* is false.
  #
  def help_section(item: nil, wrap: true, **opt)
    opt = append_css_classes(opt, 'help-section')
    help_container(item: item, wrap: wrap, **opt)
  end

  # Render a single entry for use within a list of items.
  #
  # @param [Symbol, nil] item         Default: `#request_parameters[:id]`.
  # @param [Boolean]     wrap         If *true*, wrap in a container element.
  # @param [Hash]        opt          Passed to #help_container.
  #
  # @return [ActiveSupport::SafeBuffer]   Help contents list element.
  # @return [nil]                         No content and *wrap* is false.
  #
  def help_list_entry(item: nil, wrap: false, **opt)
    help_container(item: item, wrap: wrap, **opt)
  end

  # Render the contents of a single entry from configuration or from a partial.
  #
  # @param [Symbol, nil] item         Default: `#request_parameters[:id]`.
  # @param [Boolean]     wrap         Wrap in a "help-container" element.
  # @param [Hash]        opt          Passed to #html_div.
  #
  # @return [ActiveSupport::SafeBuffer]   Help contents element.
  # @return [nil]                         No content and *wrap* is false.
  #
  # @see config/locales/controllers/help.en.yml
  #
  def help_container(item: nil, wrap: true, **opt)
    topic   = (item || request_parameters[:id]).to_sym
    partial = "help/topic/#{topic}"
    content = HELP_ENTRY.dig(topic, :content)
    content ||= (render(partial) if partial_exists?(partial))
    return content unless wrap
    lvl = opt.delete(:level)
    row = opt.delete(:row)
    row &&= "row-#{row}"
    mod = ('modal' if modal?)
    opt = prepend_css_classes(opt, 'help-container', row, mod)
    opt[:role] = 'article' if lvl == 1
    html_div(content, **opt)
  end

end

__loading_end(__FILE__)
