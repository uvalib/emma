# app/helpers/bookshare_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper methods supporting access and linkages to the Bookshare API.
#
module BookshareHelper

  # @private
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
  #--
  # noinspection LongLine
  #++
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
      id: :userAccountId
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
  # @param [Hash, String, nil] path
  # @param [Hash]              path_opt   Passed to #make_path.
  #
  # @return [String]                      A full URL.
  # @return [nil]                         If the URL could not be determined.
  #
  # == Variations
  #
  # @overload bookshare_url(url, **path_opt)
  #   @param [String, nil] url        Full or partial URL.
  #   @param [Hash]        path_opt
  #
  # @overload bookshare_url(hash, **path_opt)
  #   @param [Hash]        hash       Controller/action.
  #   @param [Hash]        path_opt
  #
  #--
  # noinspection RubyNilAnalysis
  #++
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
    path.unshift(BOOKSHARE_SITE) unless path.first.to_s.start_with?('http')
    path = path.join('/')

    # If the path contains format references (e.g., "%{id}" or "%<id>") then
    # they should be satisfied by the options passed in to the method.
    # noinspection RubyYardParamTypeMatch
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

    # noinspection RubyYardParamTypeMatch
    make_path(path, path_opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # A direct link to a Bookshare page to open in a new browser tab.
  #
  # @param [Bs::Api::Record, String] item
  # @param [String]                  path
  # @param [Hash]                    path_opt   Passed to #bookshare_url.
  #
  # @return [ActiveSupport::SafeBuffer]         HTML link element.
  # @return [nil]                               If no *path* was found.
  #
  # == Variations
  #
  # @overload bookshare_link(item)
  #   @param [Bs::Api::Record] item
  #
  # @overload bookshare_link(item, path, **path_opt)
  #   @param [String] item            Link label.
  #   @param [String] path            Passed as #bookshare_url *path* parameter
  #   @param [Hash]   path_opt
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
    external_link(label, path, title: tip) if path.present?
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Transform name(s) into Bookshare username(s).
  #
  # @param [String, Symbol, Array<String,Symbol>] name
  #
  # @return [String]
  # @return [Array<String>]
  #
  # == Variations
  #
  # @overload bookshare_user(name)
  #   @param [String, Symbol] name
  #   @return [String]
  #
  # @overload bookshare_user(names)
  #   @param [Array<String,Symbol>] names
  #   @return [Array<String>]
  #
  def bookshare_user(name)
    return name.map { |v| send(__method__, v) } if name.is_a?(Array)
    name = name.to_s.downcase
    # noinspection RubyYardReturnMatch
    (name.present? && !name.include?('@')) ? (BOOKSHARE_USER % name) : name
  end

end

__loading_end(__FILE__)
