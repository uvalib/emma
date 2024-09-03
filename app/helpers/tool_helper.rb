# app/helpers/tool_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper methods supporting standalone "tools".
#
module ToolHelper

  include LinkHelper

  # Non-functional hints for RubyMine type checking.
  unless ONLY_FOR_DOCUMENTATION
    # :nocov:
    include ActionDispatch::Routing::UrlFor
    # :nocov:
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The table of standalone tool labels and paths.
  #
  # @return [Hash{Symbol=>Hash}]
  #
  TOOL_ITEMS =
    config_page_section(:tool, :action).except(:index).map { |k, v|
      next if k.start_with?('_')
      p = v[:path].presence
      v = v.merge(path: p.to_sym).freeze if p.is_a?(String) && !p.include?('/')
      [k, v]
    }.compact.to_h.freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Standalone tool list entry.
  #
  # @param [User, nil] user           Default: `current_user`
  # @param [String]    css            Characteristic CSS class/selector.
  # @param [Hash]      opt            Passed to outer :ul tag.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see file:app/assets/javascripts/feature/search.js
  #
  def tool_list(user: nil, css: '.tool-list', **opt)
    user ||= current_user
    prepend_css!(opt, css)
    html_ul(**opt) do
      TOOL_ITEMS.map { |act, cfg| tool_list_item(act, cfg, user: user) }
    end
  end

  # Standalone tool list entry.
  #
  # @param [Symbol]    action
  # @param [Hash]      config
  # @param [User, nil] user           Default: `current_user`
  # @param [String]    css            Characteristic CSS class/selector.
  # @param [Hash]      opt            Passed to #make_link.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see file:app/assets/javascripts/feature/search.js
  #
  def tool_list_item(action, config, user: nil, css: '.tool-item', **opt)
    user ||= current_user
    allow  = tool_authorized?(action, user: user, config: config, check: true)

    label  = (config[:label] || config[:title] || action).to_s
    path   = config[:path]
    path   = try(path) if path.is_a?(Symbol)
    path ||= url_for(controller: :tool, action: action, only_path: true)
    l_css  = %w[action]
    l_css << (user ? 'role-failure' : 'sign-in-required') unless allow
    # noinspection RubyMismatchedArgumentType
    link   = make_link(path, label, **append_css(l_css))

    n_css  = %w[notice]
    n_css << 'hidden' if allow
    notice = config_term(:tool, (user ? :role_failure : :sign_in))
    notice = html_span(notice, **append_css(n_css))

    prepend_css!(opt, css)
    html_li(**opt) do
      link << notice
    end
  end

  # Indicate whether the user is authorized to access the given tool page.
  #
  # @param [Symbol]    action
  # @param [User, nil] user         Default: `current_user`
  # @param [Hash, nil] config       Default: `TOOL_ITEMS[action]`
  # @param [Boolean]   check        If *true* don't raise CanCan::AccessDenied.
  #
  # @raise [CanCan::AccessDenied]   User is not authorized.
  #
  def tool_authorized?(action, user: nil, config: nil, check: false)
    config ||= TOOL_ITEMS[action]
    raise %Q("en.emma.page.tool.#{action}" is bad) unless config
    auth     = config[:authorization]
    allow    = auth.nil? || false?(auth)
    allow  ||= ((user || current_user).present? if true?(auth))
    if allow.nil?
      raise %Q(expected "authorization: nil/true/false"; got: #{auth.inspect})
    elsif !allow && !check
      action = config[:label] || config[:title] || action
      raise CanCan::AccessDenied, "Not authorized for #{action}"
    end
    allow
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
