# app/helpers/link_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper methods supporting the creation of links.
#
module LinkHelper

  include Emma::Common
  include Emma::Unicode

  include ConfigurationHelper
  include HtmlHelper
  include RouteHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Create a link element to an application action target.
  #
  # @param [String, nil]    label         Label passed to #make_link.
  # @param [Symbol, String] ctrlr
  # @param [Symbol, String] action
  # @param [Hash]           link_opt      Options passed to #make_link.
  # @param [String]         css           Characteristic CSS class/selector.
  # @param [Hash]           path_opt      Path options.
  #
  # @return [ActiveSupport::SafeBuffer]   HTML link element.
  # @return [nil]                         A valid URL could not be determined.
  #
  def link_to_action(
    label,
    ctrlr:,
    action:,
    link_opt: nil,
    css:      '.control',
    **path_opt
  )
    ctrlr    = path_opt.delete(:controller) || ctrlr # Just in case.
    path     = get_path_for(ctrlr, action, **path_opt) or return
    label  ||= config_lookup("#{action}.label", ctrlr: ctrlr) || path
    html_opt = prepend_css(link_opt, css)
    html_opt[:method] ||= :delete if action.to_s == 'destroy'
    html_opt[:title]  ||= config_lookup(:tooltip, ctrlr: ctrlr, action: action)
    # noinspection RubyMismatchedArgumentType
    if path.match?(/^https?:/)
      external_link(path, label, **html_opt)
    else
      make_link(path, label, **html_opt)
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Fallback Unicode symbol for icons.
  #
  # @type [String]
  #
  DEFAULT_ICON = BLACK_STAR

  # Generate a symbol-based icon button or link which should be both accessible
  # and cater to the quirks of various accessibility scanners.
  #
  # @param [String, nil] icon         Default: DEFAULT_ICON
  # @param [String, nil] text         Default: 'Action'
  # @param [String, nil] url          Default: '#'
  # @param [Hash]        opt          To #make_link or #html_span except for:
  #
  # @option opt [String] :symbol      Overrides *symbol*
  # @option opt [String] :text        Overrides *text*
  # @option opt [String] :url         Overrides *url*
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def icon_button(icon: nil, text: nil, url: nil, **opt)
    icon        ||= DEFAULT_ICON
    text        ||= opt[:title] || config_term(:link, :icon_action)
    opt[:title] ||= text

    sr_only = html_span(text, class: 'text sr-only')
    symbol  = html_span(icon, class: 'symbol', 'aria-hidden': true)
    label   = sr_only << symbol

    if url
      # noinspection RubyMismatchedArgumentType
      make_link(url, label, **opt)
    else
      if opt[:tabindex].to_i == -1
        opt.except!(:tabindex, :role)
      else
        opt[:tabindex] ||= 0
        opt[:role]     ||= 'button'
      end
      html_span(label, **opt)
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Added to the tooltip of external links.
  #
  # @type [String]
  #
  NEW_TAB =
    config_term(:link, :new_tab).then { |v|
      (v.start_with?('(','[') && v.end_with?(')',']')) ? v : "(#{v})"
    }.freeze

  # Produce a link with appropriate accessibility settings.
  #
  # @param [String, Hash] path
  # @param [String, nil]  label       Default: *path*.
  # @param [Hash]         opt         Passed to #link_to except for:
  # @param [Proc]         blk         Passed to #link_to.
  #
  # @option opt [String] :label       Overrides *label* parameter if present.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # === Usage Notes
  # This method assumes that local paths are always relative.
  #
  def make_link(path, label = nil, **opt, &blk)
    add_inferred_attributes!(:a, opt)

    http     = path.is_a?(String) && path.start_with?('http')
    label    = (opt.delete(:label) if opt.key?(:label)) || label || path
    named    = accessible_name?(label, **opt)
    title    = opt[:title]
    hidden   = opt[:'aria-hidden']
    disabled = opt[:'aria-disabled']
    new_tab  = (opt[:target] == '_blank')
    sign_in  = has_class?(opt, 'sign-in-required')

    opt[:'aria-label'] = title      if title   && !named
    opt[:tabindex]     = -1         if hidden  && !opt.key?(:tabindex)
    opt[:rel]          = 'noopener' if http    && !opt.key?(:rel)
    append_tooltip!(opt, NEW_TAB)   if new_tab && !disabled && !sign_in
    html_options!(opt)

    link_to(label, path, opt, &blk)
  end

  # Produce a link to an external site which opens in a new browser tab.
  #
  # @param [String]      path
  # @param [String, nil] label        Default: *path*.
  # @param [Hash]        opt          Passed to #make_link.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def external_link(path, label = nil, **opt, &blk)
    opt[:target] = '_blank' unless opt.key?(:target)
    make_link(path, label, **opt, &blk)
  end

  # Produce a link to download an item to the client's browser.
  #
  # @param [String] path
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt               Passed to #external_link.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def download_link(path, css: '.download', **opt, &blk)
    prepend_css!(opt, css)
    external_link(path, **opt, &blk)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Base URL for references to the EMMA project repository.
  #
  # @type [String]
  #
  GITHUB_ROOT = 'https://github.com/uvalib/emma'

  # Base URL for references to EMMA source code.
  #
  # @type [String]
  #
  SOURCE_CODE_ROOT = "#{GITHUB_ROOT}/blob/master"

  # Produce a link to EMMA source code for display within the application.
  #
  # @param [String]      path
  # @param [String, nil] label        Derived from *path* if not given.
  # @param [Hash]        opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see #external_link
  #
  def source_code_link(path, label = nil, **opt, &blk)
    if path.start_with?(SOURCE_CODE_ROOT)
      label ||= path.sub(%r{^#{SOURCE_CODE_ROOT}/}, '')
    else
      label ||= path
      path    = "#{SOURCE_CODE_ROOT}/#{path}"
    end
    external_link(path, label, **opt, &blk)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Base URL for references to the UVALIB configuration repository.
  #
  # @type [String]
  #
  TERRAFORM_ROOT = 'https://gitlab.com/uvalib/terraform-infrastructure'

  # Base URL for references to EMMA UVALIB configuration.
  #
  # @type [String]
  #
  TERRAFORM_EMMA = "#{TERRAFORM_ROOT}/-/blob/master/emma.lib.virginia.edu"

  # Produce a link to EMMA UVALIB configuration for display within the
  # application.
  #
  # @param [String]      path
  # @param [String, nil] label        Derived from *path* if not given.
  # @param [Hash]        opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see #external_link
  #
  def terraform_link(path, label = nil, **opt, &blk)
    if path.start_with?(TERRAFORM_EMMA)
      label ||= path.sub(%r{^#{TERRAFORM_EMMA}/}, '')
    else
      label ||= path
      path    = "#{TERRAFORM_EMMA}/#{path}"
    end
    external_link(path, label, **opt, &blk)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # If *text* is a URL return it directly; if *text* is HTML, locate the first
  # "href" and return the indicated value.
  #
  # @param [String, nil] text
  #
  # @return [String]                  A full URL.
  # @return [nil]                     No URL could be extracted.
  #
  def extract_url(text)
    url = text.to_s.strip
    unless url.blank? || url.start_with?('http')
      url = url.tr("\n", ' ').sub!(/.*href=["']([^"']{2,})["'].*/, '\1')
      unless url.blank? || url.start_with?('http')
        url = url.remove!(/^[^?]+\?url=/) && CGI.unescape(url)
      end
    end
    url.presence
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
