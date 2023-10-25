# app/helpers/layout_helper/common.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Shared view helper methods supporting general page layout.
#
module LayoutHelper::Common

  include Emma::Common
  include Emma::Constants

  include FormHelper
  include HtmlHelper
  include SearchTermsHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # If the client is responsible for managing hidden inputs on forms then they
  # should not be generated via #search_form.
  #
  # @type [Boolean]
  #
  CLIENT_MANAGES_HIDDEN_INPUTS = true

  def search_form(target, id = nil, hidden: nil, **opt, &blk)
    search_form_with_hidden(target, id, hidden: hidden, **opt, &blk)
  end unless CLIENT_MANAGES_HIDDEN_INPUTS

  # A form used to create/modify a search.
  #
  # @param [Symbol, String, nil] target
  # @param [Symbol, String, nil] id       NOTE [1]
  # @param [Hash, nil]           hidden   NOTE [1]
  # @param [Hash]                opt      Passed to #html_form.
  #
  # @return [ActiveSupport::SafeBuffer]   An HTML form element.
  # @return [nil]                         Search is not available for *target*.
  #
  # @yield To supply additional field(s) for the '<form>'.
  # @yieldreturn [String, Array<String>]
  #
  # === Notes
  # - [1] If #CLIENT_MANAGES_HIDDEN_INPUTS then id and hidden are ignored.
  #
  #--
  # noinspection RubyUnusedLocalVariable
  #++
  def search_form(target, id = nil, hidden: nil, **opt, &blk)
    return if (path = search_target_path(target)).blank?
    opt[:method] ||= :get
    html_form(path, **opt, &blk)
  end if CLIENT_MANAGES_HIDDEN_INPUTS

  # A form used to create/modify a search.
  #
  # When searching via the indicated *target*, and *id* is supplied then the
  # current URL parameters are included as hidden fields so that the current
  # search is repeated but augmented with the added parameter.
  #
  # Otherwise a new search is assumed.
  #
  # @param [Symbol, String, nil] target
  # @param [Symbol, String, nil] id       Passed to #hidden_parameter_for.
  # @param [Hash, nil]           hidden   Passed to #hidden_parameter_for.
  # @param [Hash]                opt      Passed to #html_form.
  #
  # @return [ActiveSupport::SafeBuffer]   An HTML form element.
  # @return [nil]                         Search is not available for *target*.
  #
  # @yield To supply additional field(s) for the '<form>'.
  # @yieldreturn [String, Array<String>]
  #
  # @note Used only if #CLIENT_MANAGES_HIDDEN_INPUTS is false.
  #
  def search_form_with_hidden(target, id = nil, hidden: nil, **opt)
    return if (path = search_target_path(target)).blank?
    include_hidden = hidden.present? || (id.present? && (path == request.path))
    # noinspection RubyMismatchedArgumentType
    before, after = (hidden_parameters_for(id, hidden) if include_hidden)
    elements = [*before, *yield, *after]
    opt[:method] ||= :get
    html_form(path, *elements, **opt)
  end

  # The target path for searches from the search bar.
  #
  # @param [Symbol, String, nil] target   Default: #DEFAULT_SEARCH_CONTROLLER
  # @param [Hash]                opt      Passed to #url_for.
  #
  # @return [String]
  #
  def search_target_path(target = nil, **opt)
    target ||= DEFAULT_SEARCH_CONTROLLER
    ctrlr    = "/#{target}"
    action   = SEARCH_CONTROLLERS[target&.to_sym]
    url_for(opt.merge(controller: ctrlr, action: action, only_path: true))
  rescue ActionController::UrlGenerationError
    search_target_path(**opt)
  end

end

__loading_end(__FILE__)
