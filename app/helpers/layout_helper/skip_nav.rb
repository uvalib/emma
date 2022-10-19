# app/helpers/layout_helper/skip_nav.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper methods for setting/getting the hidden "skip navigation" menu.
#
module LayoutHelper::SkipNav

  include LayoutHelper::PageControls

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Storage for "skip navigation" menu entries.
  #
  # @return [Array]
  #
  def skip_nav
    @skip_nav ||= []
  end

  # Clear all "skip navigation" menu entries.
  #
  # @return [Array]
  #
  # @note Currently unused.
  #
  def skip_nav_clear
    @skip_nav = []
  end

  # Set "skip navigation" menu entries (replacing any existing ones).
  #
  # @param [Array] entries
  #
  # @return [Array]
  #
  # @yield To supply additional entries to @skip_nav.
  # @yieldreturn [String, Array<String>]
  #
  def skip_nav_set(*entries)
    entries.flatten!
    entries += Array.wrap(yield) if block_given?
    @skip_nav = entries
  end

  # Add entries to the end of the "skip navigation" menu.
  #
  # @param [Array] entries
  #
  # @return [Array]
  #
  # @yield To supply additional entries to @skip_nav.
  # @yieldreturn [String, Array<String>]
  #
  def skip_nav_append(*entries)
    return skip_nav if modal?
    block = block_given? && yield || []
    skip_nav_set(*skip_nav, *entries, *block)
  end

  # Add entries to the beginning of the "skip navigation" menu.
  #
  # @param [Array] entries
  #
  # @return [Array]
  #
  # @yield To supply additional entries to prepend to @skip_nav.
  # @yieldreturn [String, Array<String>]
  #
  def skip_nav_prepend(*entries)
    return skip_nav if modal?
    block = block_given? && yield || []
    skip_nav_set(*entries, *block, *skip_nav)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Generate HTML for a "skip navigation" menu.
  #
  # @param [Hash] opt                 Passed to outer #html_tag.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def render_skip_nav(opt = nil)
    css = '.skip-nav-menu'
    opt = prepend_css(opt, css)
    html_tag(:ul, opt) do
      skip_nav.flat_map { |entry|
        if entry.is_a?(Hash)
          entry.map { |label, link| render_skip_nav_link(label, link) }
        else
          entry.presence
        end
      }.compact.uniq.map { |e| html_tag(:li, e, class: 'skip-nav-entry') }
    end
  end

  # Generate a single "skip navigation" link.
  #
  # @param [String, Symbol, Array<Symbol,String>] label
  # @param [String]                               link
  # @param [Hash]                                 opt   Passed to #link_to.
  #
  # @return [ActiveSupport::SafeBuffer]   HTML link element.
  # @return [nil]                         If *label* or *link* is missing.
  #
  def render_skip_nav_link(label, link, **opt)
    css = '.skip-nav-link'
    return if label.blank? || link.blank?

    unless label.is_a?(String)
      if label.is_a?(Array)
        other = label.dup
        key   = other.shift
        if other.blank?
          t_opt = {}
        elsif !other.first.is_a?(Hash)
          t_opt = { default: other }
        else
          t_opt = other.shift || {}
          other = [*t_opt[:default], *other].compact.uniq
          t_opt = t_opt.merge(default: other) if other.present?
        end
        label = I18n.t(key, **t_opt)
      elsif label.to_s.start_with?('emma.')
        label = I18n.t(label)
      else
        label = page_controls_label(controller: label.to_s, many: true)
      end
    end

    link = link.to_s
    unless link.start_with?('#', 'http') || link.include?('/')
      link = '#' + link
    end

    prepend_css!(opt, css)
    link_to(label, link, opt)
  end

end

__loading_end(__FILE__)
