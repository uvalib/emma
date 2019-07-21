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
    bookActionHistory:        "#{BOOKSHARE_CATALOG}/bookActionHistory",
    submitBook:               "#{BOOKSHARE_CATALOG}/submitBook",
    bookEditMetadata:         "#{BOOKSHARE_CATALOG}/bookEditMetadata",
    bookWithdrawal:           "#{BOOKSHARE_CATALOG}/bookWithdrawal",
    myReadingListsCreate:     "#{BOOKSHARE_SITE}/myReadingLists/create",                    # TODO: controller
    myReadingListsEdit:       "#{BOOKSHARE_SITE}/myReadingLists/%{id}/edit",                # TODO: controller
    myReadingListsDelete:     "#{BOOKSHARE_SITE}/myReadingLists/%{id}?delete",              # TODO: controller, HTTP DELETE
    orgAccountMembersAdd:     "#{BOOKSHARE_SITE}/orgAccountMembers/edit",                   # TODO: ???
    orgAccountMembersEdit:    "#{BOOKSHARE_SITE}/orgAccountMembers/edit",
    orgAccountMembersRemove:  "#{BOOKSHARE_SITE}/orgAccountMembers/remove?userIds=%{ids}",  # TODO: array param insertion, HTTP POST
    orgAccountSponsorsAdd:    "#{BOOKSHARE_SITE}/orgAccountSponsors/edit",                  # TODO: ???
    orgAccountSponsorsEdit:   "#{BOOKSHARE_SITE}/orgAccountSponsors/edit",                  # TODO: controller, model
    orgAccountSponsorsRemove: "#{BOOKSHARE_SITE}/orgAccountSponsors/remove?userIds=%{ids}", # TODO: controller, model, array param insertion, HTTP POST

=begin # TODO: ???
    myReadingLists: {
      Create: "#{BOOKSHARE_SITE}/%{KEY}/create",
      Edit:   "#{BOOKSHARE_SITE}/%{KEY}/%{id}/edit",
      Delete: "#{BOOKSHARE_SITE}/%{KEY}/%{id}?delete",
    },
    orgAccountMembers: {
      Add:    "#{BOOKSHARE_SITE}/%{KEY}/edit",
      Edit:   "#{BOOKSHARE_SITE}/%{KEY}/edit",
      Remove: "#{BOOKSHARE_SITE}/%{KEY}/remove?userIds=%{ids}",
    },
    orgAccountSponsors: {
      Add:    "#{BOOKSHARE_SITE}/%{KEY}/edit",
      Edit:   "#{BOOKSHARE_SITE}/%{KEY}/edit",
      Remove: "#{BOOKSHARE_SITE}/%{KEY}/remove?userIds=%{ids}",
    },
=end

  }.deep_freeze

  # Mapping of application URL parameters to Bookshare URL parameters.
  #
  # @type [Hash{Symbol=>Symbol}]
  #
  PARAM_MAPPING = {
    id: :titleInstanceId
  }.freeze

  # Mapping of an application action (expressed as "controller-action") to the
  # associated Bookshare action (expressed as a #BOOKSHARE_ACTION key).
  #
  # @type [Hash{Symbol=>Symbol}]
  #
  ACTION_MAPPING = {
    title: {
      history: :bookActionHistory,
      new:     :submitBook,               # TODO: Bookshare way to create a catalog title without uploading an artifact?
      create:  :submitBook,               # TODO: ditto
      edit:    :bookEditMetadata,
      update:  :bookEditMetadata,
      delete:  :bookWithdrawal,
      destroy: :bookWithdrawal,
    },
    reading_list: {                       # TODO: controller
      new:     :myReadingListsCreate,
      create:  :myReadingListsCreate,
      edit:    :myReadingListsEdit,
      update:  :myReadingListsEdit,
      delete:  :myReadingListsDelete,
      destroy: :myReadingListsDelete,
    },
    member: {
      new:     :orgAccountMembersAdd,
      create:  :orgAccountMembersAdd,
      edit:    :orgAccountMembersEdit,
      update:  :orgAccountMembersEdit,
      delete:  :orgAccountMembersRemove,  # TODO: method
      destroy: :orgAccountMembersRemove,  # TODO: method
    },
    sponsor: {                            # TODO: controller, model
      new:     :orgAccountSponsorsAdd,
      create:  :orgAccountSponsorsAdd,
      edit:    :orgAccountSponsorsEdit,
      update:  :orgAccountSponsorsEdit,
      delete:  :orgAccountSponsorsRemove,
      destroy: :orgAccountSponsorsRemove,
    },

=begin # TODO: ???
    reading_list: {                           # TODO: controller
      new:     %i[myReadingLists Create],
      create:  %i[myReadingLists Create],
      edit:    %i[myReadingLists Edit],
      update:  %i[myReadingLists Edit],
      delete:  %i[myReadingLists Delete],
      destroy: %i[myReadingLists Delete],
    },
    member: {
      new:     %i[orgAccountMembers Add],
      create:  %i[orgAccountMembers Add],
      edit:    %i[orgAccountMembers Edit],
      update:  %i[orgAccountMembers Edit],
      delete:  %i[orgAccountMembers Remove],  # TODO: method
      destroy: %i[orgAccountMembers Remove],  # TODO: method
    },
    sponsor: {                                # TODO: controller, model
      new:     %i[orgAccountSponsors Add],
      create:  %i[orgAccountSponsors Add],
      edit:    %i[orgAccountSponsors Edit],
      update:  %i[orgAccountSponsors Edit],
      delete:  %i[orgAccountSponsors Remove],
      destroy: %i[orgAccountSponsors Remove],
    },
=end

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
    actions.keys.each do |action|
      class_eval <<~EOS
        def #{action}_#{controller}_path(**opt)
          bookshare_url(controller: :#{controller}, action: :#{action}, **opt)
        end
      EOS
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
  # @param [Hash, nil]      path_opt    Passed to #make_bookshare_path.
  #
  # @return [String]
  # @return [nil]                     If the URL could not be determined.
  #
  def bookshare_url(path = nil, controller: nil, action: nil, **path_opt)
    parts = []
    path ||= bookshare_action(controller: controller, action: action)

    if path.blank?
      return

    elsif path.match?(/^https?:/)
      parts << path

    elsif (entry = BOOKSHARE_ACTION[path.to_sym]).is_a?(String)
      keys = parameter_references(entry)
      path_opt, ref_opt = extract_options(path_opt, *keys)
      parts << (entry % ref_opt)

    elsif entry.is_a?(Array)
      parts +=
        entry.map do |e|
          keys = parameter_references(e)
          path_opt, ref_opt = extract_options(path_opt, *keys)
          e % ref_opt
        end

=begin # TODO: should the BOOKSHARE_ACTION value always just be a String?
    elsif entry.is_a?(Hash)
      url  = entry[:url] || BOOKSHARE_SITE
      keys = parameter_references(url)
      path_opt, ref_opt = extract_options(path_opt, *keys)
      parts << (url % ref_opt)
      parts << path
=end

    else
      Log.warn { "#{__method__}: unexpected #{path.inspect}" }
      parts << path
    end

    make_bookshare_path(*parts, path_opt)
  end

  # Report the Bookshare action for the current context.
  #
  # @param [String, Symbol] controller    Default: `params[:controller]`.
  # @param [String, Symbol] action        Default: `params[:action]`.
  #
  # @return [Symbol]
  # @return [nil]                     If the action could not be determined.
  #
  def bookshare_action(controller: nil, action: nil)
    controller ||= params[:controller]
    action     ||= params[:action]
    ACTION_MAPPING.dig(controller&.to_sym, action&.to_sym)
  end

  # Generate a Bookshare URL path from components.
  #
  # @param [Array] args               URL path components, except:
  #
  # @option args.last [Hash]          URL options to include in the result.
  #
  # @return [String]
  #
  def make_bookshare_path(*args)
    if args.last.is_a?(Hash)
      args << args.pop.transform_keys { |k| PARAM_MAPPING[k] || k }
    end
    make_path(*args)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Create a link element to an application action target.
  #
  # @param [String, Symbol] controller    Default: `params[:controller]`.
  # @param [String, Symbol] action        Default: `params[:action]`.
  # @param [String]         label         Label passed to #link_to.
  # @param [Hash]           link_opt      Options passed to #link_to.
  # @param [Hash, nil]      path_opt      Path options.
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
    path =
      case action.to_sym
        when :index then "#{controller}_index_path"
        when :show  then "#{controller}_path"
        else             "#{action}_#{controller}_path"
      end
    path =
      if !respond_to?(path)
        Log.warn("#{__method__}: invalid path #{path.inspect}")
      elsif (path_result = send(path, path_opt)).blank?
        Log.warn("#{__method__}: invalid path #{path.inspect}")
      else
        path_result
      end
    return if path.blank?

    label ||= action_label(action, controller)
    html_opt = { class: 'control' }
    html_opt[:target]  = '_blank' if path.match?(/^https?:/)
    html_opt[:method]  = :delete  if %i[delete destroy].include?(action)
    merge_html_options!(html_opt, link_opt)
    html_opt[:rel]     = 'noopener' if html_opt[:target] == '_blank'
    html_opt[:title] ||= action_tooltip(action, controller)
    link_to(label, path, html_opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # Extract the named references in a format string.
  #
  # @param [String] format_string
  #
  # @return [Array<Symbol>]
  #
  def parameter_references(format_string)
    [].tap do |keys|
      if format_string.present?
        format_string.scan(/%<([^>]+)>/) { |k| keys << k }
        format_string.scan(/%{([^}]+)}/) { |k| keys << k }
        keys.reject!(&:blank?)
        keys.map!(&:to_sym)
      end
    end
  end

end

__loading_end(__FILE__)
