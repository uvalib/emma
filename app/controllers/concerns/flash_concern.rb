# app/controllers/concerns/flash_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Controller support methods for creation of flash messages.
#
module FlashConcern

  extend ActiveSupport::Concern

  include FlashHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # flash_link
  #
  # @param [String]       label
  # @param [String, Hash] path
  # @param [Hash]         opt
  #
  # @option opt [String] :tooltip   Alias for :title.
  # @option opt [String] :tip       Alias for :title.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def flash_link(label, path, **opt)
    ti_opt      = extract_hash!(opt, :tooltip, :tip, :title).compact
    opt[:title] = ERB::Util.h(ti_opt.values.first) if ti_opt.present?
    full = path.is_a?(String) && path.start_with?('http')
    path = make_path(request.fullpath, path) unless full
    attr = { href: path }.merge!(opt).map { |k, v| %Q(#{k}="#{v}") }.join(' ')
    "<a #{attr}>#{label}</a>".html_safe
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  THIS_MODULE = self

  included do |base|
    __included(base, THIS_MODULE)
  end

end

__loading_end(__FILE__)
