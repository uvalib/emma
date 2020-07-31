# app/helpers/layout_helper/skip_nav.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Hidden "skip navigation" menu.
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
    entries  = @skip_nav + entries if @skip_nav.present?
    entries += Array.wrap(yield)   if block_given?
    skip_nav_set(*entries)
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
    entries += Array.wrap(yield) if block_given?
    entries += @skip_nav         if @skip_nav.present?
    skip_nav_set(*entries)
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
    opt = prepend_css_classes(opt, 'skip-nav-menu')
    html_tag(:ul, opt) do
      skip_nav.flat_map { |entry|
        if entry.is_a?(Hash)
          # noinspection RubyYardParamTypeMatch
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
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]
  #
  def render_skip_nav_link(label, link, **opt)
    return if label.blank? || link.blank?
    opt  = prepend_css_classes(opt, 'skip-nav-link')
    link = link.to_s
    unless link.start_with?('#', 'http') || link.include?('/')
      link = '#' + link
    end
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
    link_to(label, link, opt)
  end

end

__loading_end(__FILE__)
