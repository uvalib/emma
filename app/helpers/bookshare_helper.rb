# app/helpers/bookshare_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods supporting linkages to Bookshare.
#
module BookshareHelper

  def self.included(base)
    __included(base, '[BookshareHelper]')
  end

  include GenericHelper
  include HtmlHelper
  include I18nHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  BOOKSHARE_SITE    = 'https://www.bookshare.org'
  BOOKSHARE_CMS     = "#{BOOKSHARE_SITE}/cms".freeze
  BOOKSHARE_CATALOG = 'https://catalog.bookshare.org'

  # Bookshare actions.
  #
  # Any action not explicitly listed (or listed without a :url value) is
  # implicitly assumed to be a #BOOKSHARE_SITE endpoint.
  #
  # @type [Hash{Symbol=>(Hash|String)}]
  #
  BOOKSHARE_ACTION = {
    bookActionHistory:  "#{BOOKSHARE_CATALOG}/bookActionHistory",
    submitBook:         "#{BOOKSHARE_CATALOG}/submitBook",
    bookEditMetadata:   "#{BOOKSHARE_CATALOG}/bookEditMetadata",
    bookWithdrawal:     "#{BOOKSHARE_CATALOG}/bookWithdrawal",
    orgAccountMembers: {
      Add:    "#{BOOKSHARE_SITE}/orgAccountMembers/edit",                                     # TODO: ???
      Edit:   "#{BOOKSHARE_SITE}/orgAccountMembers/edit",
      Remove: "#{BOOKSHARE_SITE}/orgAccountMembers/remove?userIds=%{ids}",                    # TODO: HTTP POST
    },
    orgAccountSponsors: {
      Add:    "#{BOOKSHARE_SITE}/orgAccountSponsors/edit",                                    # TODO: ???
      Edit:   "#{BOOKSHARE_SITE}/orgAccountSponsors/edit",                                    # TODO: controller/model
      Remove: "#{BOOKSHARE_SITE}/orgAccountSponsors/remove?userIds=%{ids}",                   # TODO: controller/model, HTTP POST
    },
    myReadingLists: {
      Add:    "#{BOOKSHARE_SITE}/myReadingLists?readingListId=%{id}&addTitle=%{bookshareId}", # TODO: HTTP POST
      Create: "#{BOOKSHARE_SITE}/myReadingLists/create",
      Edit:   "#{BOOKSHARE_SITE}/myReadingLists/%{id}/edit",
      Delete: "#{BOOKSHARE_SITE}/myReadingLists/%{id}?delete",                                # TODO: HTTP DELETE
    },
  }.deep_freeze

  # Mapping of application URL parameters to Bookshare URL parameters.
  #
  # @type [Hash{Symbol=>Hash{Symbol=>Symbol}}]
  #
  PARAM_MAPPING = {
    title: {
      id: :titleInstanceId
    },
    periodical: {
      id: :seriesId
    },
    edition: {
      id: :editionId
    },
    member: {
      id: nil
    },
    sponsor: {
      # TODO: sponsor?
    },
    reading_list: {
      id: :readingListId
    },
    subscription: { # TODO: subscription controller/model
      id: :subscriptionId
    },
  }.freeze

  # Mapping of an application action (expressed as "controller-action") to the
  # associated Bookshare action (expressed as a #BOOKSHARE_ACTION key).
  #
  # @type [Hash{Symbol=>Symbol}]
  #
  ACTION_MAPPING = {
    title: {
      history: :bookActionHistory,
      new:     :submitBook,         # TODO: Bookshare way to create a catalog title without uploading an artifact?
      create:  :submitBook,         # TODO: ditto
      edit:    :bookEditMetadata,
      update:  :bookEditMetadata,
      delete:  :bookWithdrawal,
      destroy: :bookWithdrawal,
    },
    periodical: {
      # TODO: periodical?
    },
    edition: {
      # TODO: edition?
    },
    member: {
      new:     %i[orgAccountMembers Add],
      create:  %i[orgAccountMembers Add],
      edit:    %i[orgAccountMembers Edit],
      update:  %i[orgAccountMembers Edit],
      delete:  %i[orgAccountMembers Remove],  # TODO: method
      destroy: %i[orgAccountMembers Remove],  # TODO: method
    },
    sponsor: {
      # TODO: sponsor controller/model?
      new:     %i[orgAccountSponsors Add],
      create:  %i[orgAccountSponsors Add],
      edit:    %i[orgAccountSponsors Edit],
      update:  %i[orgAccountSponsors Edit],
      delete:  %i[orgAccountSponsors Remove],
      destroy: %i[orgAccountSponsors Remove],
    },
    reading_list: {
      new:     %i[myReadingLists Create],
      create:  %i[myReadingLists Create],
      edit:    %i[myReadingLists Edit],
      update:  %i[myReadingLists Edit],
      delete:  %i[myReadingLists Delete],
      destroy: %i[myReadingLists Delete],
    },
    subscription: {
      # TODO: subscription?
    },
  }.deep_freeze

  # Generate overrides for route helpers of actions that must be performed on
  # a Bookshare site and not by an application endpoint.
  #
  # @example Edit catalog title metadata
  #
  # - The route helper :edit_title_path will be defined by ActionDispatch to
  #   refer to the route '/title/:id/edit', however there is currently no API
  #   support for this action so it cannot be implemented in the application.
  #
  # - The ACTION_MAPPING[:title][:edit] entry is used here to generate an
  #   overriding method :edit_title_path which replaces the method generated by
  #   ActionDispatch with one that
  #
  ACTION_MAPPING.each do |controller, actions|
    class_exec do
      actions.keys.each do |action|
        define_method(:"#{action}_#{controller}_path") do |**opt|
          bookshare_url(controller: controller, action: action, **opt)
        end
      end
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Generate a Bookshare URL.  If *path* is not given, infer it from the
  # originating controller and action.
  #
  # @param [String, nil]    path
  # @param [String, Symbol] controller  Default: `params[:controller]`.
  # @param [String, Symbol] action      Default: `params[:action]`.
  # @param [Hash]           path_opt    Passed to #make_path
  #
  # @return [String]
  # @return [nil]                     If the URL could not be determined.
  #
  def bookshare_url(path = nil, controller: nil, action: nil, **path_opt)

    # If *path* was not given, get a #BOOKSHARE_ACTION reference based on the
    # current or specified controller/action.
    controller ||= params[:controller]
    action     ||= params[:action]
    path       ||= ACTION_MAPPING.dig(controller.to_sym, action.to_sym)
    return if path.blank?

    # If *path* was not given as a full URL, attempt to locate an associated
    # path within #BOOKSHARE_ACTION.  If one was not found then *path* is
    # assumed to be one or more parts of a literal URL.
    lookup_path = BOOKSHARE_ACTION.dig(*path)
    path = Array.wrap(lookup_path || path)
    path.unshift(BOOKSHARE_SITE) unless path.first.start_with?('http')
    path = path.join('/')

    # If the path contains format references (e.g., "%{id}" or "%<id>") then
    # they should be satisfied by the options passed in to the method.
    if (ref_keys = named_format_references(path)).present?
      ref_opt, path_opt = partition_options(path_opt, *ref_keys)
      ref_opt.reject! { |_, v| v.blank? }
      ref_opt.transform_values! do |v|
        v.is_a?(String) ? CGI.escape(v).gsub(/\./, '%2E') : v
      end
      ref_opt[:ids] ||= ref_opt[:id]
      ref_opt[:ids] = Array.wrap(ref_opt[:ids]).join(',')
      path = format(path, ref_opt)
    end

    # Before using the (remaining) options as URL parameters, apply parameter
    # name translations.
    param_map = PARAM_MAPPING[controller.to_sym] || {}
    path_opt =
      path_opt.map { |k, v|
        k = param_map[k] if param_map.key?(k)
        v = v.join(',')  if v.is_a?(Array)
        [k, v] unless k.blank? || v.blank?
      }.compact.to_h
    make_path(path, path_opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Create a link element to an application action target.
  #
  # @param [String, Symbol] controller    Default: `params[:controller]`.
  # @param [String, Symbol] action        Default: `params[:action]`.
  # @param [String]         label         Label passed to #make_link.
  # @param [Hash]           link_opt      Options passed to #make_link.
  # @param [Hash]           path_opt      Path options.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]
  #
  def link_to_action(
    controller = nil,
    action     = nil,
    label:    nil,
    link_opt: nil,
    **path_opt
  )
    controller, action = [action, nil] unless controller.present?
    controller ||= params[:controller]
    action     ||= params[:action]
    path_helper =
      case action.to_sym
        when :index then "#{controller}_index_path"
        when :show  then "#{controller}_path"
        else             "#{action}_#{controller}_path"
      end
    path = respond_to?(path_helper) && send(path_helper, path_opt)
    if path.blank?
      Log.warn("#{__method__}: invalid path #{path_helper.inspect}")
      return
    end

    label ||= i18n_lookup(controller, action, 'label') || path
    html_opt = { class: 'control' }
    html_opt[:target]  = '_blank' if path.match?(/^https?:/)
    html_opt[:method]  = :delete  if %i[delete destroy].include?(action)
    merge_html_options!(html_opt, link_opt)
    html_opt[:title] ||= i18n_lookup(controller, action, 'tooltip')
    # noinspection RubyYardParamTypeMatch
    make_link(label, path, html_opt)
  end

end

__loading_end(__FILE__)
