# app/helpers/layout_helper/common.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# LayoutHelper::Common
#
module LayoutHelper::Common

  include ParamsHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # A form used to create/modify a search.
  #
  # If currently searching for the indicated *type*, then the current URL
  # parameters are included as hidden fields so that the current search is
  # repeated but augmented with the added parameter.  Otherwise a new search is
  # assumed.
  #
  # @param [Symbol, String] id
  # @param [Symbol, String] type
  # @param [Hash]           opt       Passed to #form_tag.
  #
  # @yield Supplies additional field(s) for the <form>.
  # @yieldreturn [String, Array<String>]
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                       If search is not available for *type*.
  #
  def search_form(id, type, **opt)
    return if (path = search_target(type)).blank?
    opt = opt.merge(method: :get) if opt[:method].blank?
    hidden_fields =
      if path == request.path
        url_parameters.except(id, :offset, :start).map do |k, v|
          hidden_field_tag(k, v, id: "#{id}-#{k}")
        end
      end
    form_tag(path, opt) do
      [*hidden_fields, *yield].join("\n").html_safe
    end
  end

  # The target path for searches from the search bar.
  #
  # @param [Symbol, String] type
  # @param [Hash]           opt       Passed to #url_for.
  #
  # @return [String]
  #
  def search_target(type, **opt)
    opt = opt.merge(controller: "/#{type}", action: :index, only_path: true)
    # noinspection RubyYardReturnMatch
    url_for(opt)
  rescue ActionController::UrlGenerationError
    search_target(:title)
  end

end

__loading_end(__FILE__)
