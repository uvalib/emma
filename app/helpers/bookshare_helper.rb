# app/helpers/bookshare_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'bs'

# Methods supporting access and linkages to the Bookshare API.
#
# noinspection DuplicatedCode
module BookshareHelper

  def self.included(base)
    __included(base, '[BookshareHelper]')
  end

  include Emma::Common
  include HtmlHelper
  include I18nHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  BOOKSHARE_SITE    = 'https://www.bookshare.org'
  BOOKSHARE_CMS     = "#{BOOKSHARE_SITE}/cms".freeze
  BOOKSHARE_CATALOG = 'https://catalog.bookshare.org'
  BOOKSHARE_USER    = '%s@bookshare.org'

  # Bookshare actions.
  #
  # Any action not explicitly listed (or listed without a :url value) is
  # implicitly assumed to be a #BOOKSHARE_SITE endpoint.
  #
  # @type [Hash{Symbol=>Hash,String}]
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
  #   overriding :edit_title_path method which replaces the method generated by
  #   ActionDispatch with one that redirects to the Bookshare URL which serves
  #   to "implement" that action.
  #
  ACTION_MAPPING.each do |controller, actions|
    class_exec do
      actions.keys.each do |action|
        define_method(:"#{action}_#{controller}_path") do |**opt|
          path = { controller: controller, action: action }
          bookshare_url(path, **opt)
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
  # @overload bookshare_url(path, **path_opt)
  #   @param [String, nil] path
  #   @param [Hash]        path_opt   Passed to #make_path
  #
  # @overload bookshare_url(path, **path_opt)
  #   @param [Hash]        path       Controller/action.
  #   @param [Hash]        path_opt   Passed to #make_path
  #
  # @return [String]
  # @return [nil]                     If the URL could not be determined.
  #
  def bookshare_url(path, **path_opt)

    # If *path* was not given, get a #BOOKSHARE_ACTION reference based on the
    # current or specified controller/action.
    controller ||= params[:controller]
    action     ||= params[:action]
    unless path.is_a?(String)
      controller = path.is_a?(Hash) && path[:controller] || controller
      action     = path.is_a?(Hash) && path[:action]     || action
      path       = ACTION_MAPPING.dig(controller.to_sym, action.to_sym)
    end
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
      ref_opt.transform_values! { |v| v.is_a?(String) ? url_escape(v) : v }
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
  # @param [String, nil]    label         Label passed to #make_link.
  # @param [Hash]           link_opt      Options passed to #make_link.
  # @param [Hash, Array]    path          Default: params :controller/:action.
  # @param [Hash]           path_opt      Path options.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]
  #
  def link_to_action(label, link_opt: nil, path: nil, **path_opt)
    path ||= {}
    path = [path[:controller], path[:action]] unless path.is_a?(Array)
    controller, action = path
    controller = (controller || params[:controller])&.to_s
    action     = (action     || params[:action])&.to_sym
    method =
      case action
        when :index then "#{controller}_index_path"
        when :show  then "#{controller}_path"
        else             "#{action}_#{controller}_path"
      end
    if (path = (send(method, **path_opt) if respond_to?(method))).blank?
      Log.warn { "#{__method__}: invalid path helper #{method.inspect}" }
      return
    end
    label ||= i18n_lookup(controller, "#{action}.label") || path
    html_opt = prepend_css_classes(link_opt, 'control')
    html_opt[:target] ||= '_blank' if path.match?(/^https?:/)
    html_opt[:method] ||= :delete  if %i[delete destroy].include?(action)
    html_opt[:title]  ||= i18n_lookup(controller, "#{action}.tooltip")
    # noinspection RubyYardParamTypeMatch
    make_link(label, path, html_opt)
  end

  # A direct link to a Bookshare page to open in a new browser tab.
  #
  # @overload bookshare_link(item)
  #   @param [Bs::Api::Record] item
  #   @param [Hash]   path_opt        Passed to #bookshare_url.
  #
  # @overload bookshare_link(item, path, **path_opt)
  #   @param [String] item            Link label.
  #   @param [String] path            Passed as #bookshare_url *path* parameter
  #   @param [Hash]   path_opt        Passed to #bookshare_url.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def bookshare_link(item, path: nil, **path_opt)
    if item.is_a?(Bs::Api::Record)
      label = item.identifier
      tip   = 'View this item on the Bookshare website.' # TODO: I18n
      path  = "browse/book/#{label}"
    else
      label = item.to_s
      tip   = 'View on the Bookshare website.' # TODO: I18n
    end
    path = bookshare_url(path, **path_opt)
    make_link(label, path, title: tip, target: '_blank')
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Transform name(s) into Bookshare username(s).
  #
  # @overload bookshare_user(name)
  #   @param [String, Symbol] name
  #   @return [String]
  #
  # @overload bookshare_user(name)
  #   @param [Array<String,Symbol>] name
  #   @return [Array<String>]
  #
  def bookshare_user(name)
    return name.map { |n| bookshare_user(n) } if name.is_a?(Array)
    name = name.to_s.downcase
    (name.present? && !name.include?('@')) ? (BOOKSHARE_USER % name) : name
  end

end

__loading_end(__FILE__)
