# app/records/lookup/crossref/shared/creator_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods mixed in to record elements related to authors, editors, etc.
#
module Lookup::Crossref::Shared::CreatorMethods

  include Lookup::RemoteService::Shared::CreatorMethods
  include Lookup::Crossref::Shared::CommonMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # @type [Hash{Symbol=>Boolean,String}]
  CREATOR_ROLE = {
    author:     false,
    editor:     true,
    translator: true,
  }.freeze

  # @type [Array<Symbol>]
  CREATOR_TYPES = CREATOR_ROLE.keys.freeze

  # ===========================================================================
  # :section: Api::Shared::CreatorMethods overrides
  # ===========================================================================

  public

  # The author(s) of this catalog title.
  #
  # @param [Hash] opt                 Passed to #creator_list.
  #
  # @return [Array<String>]
  #
  def author_list(**opt)
    creator_list(:author, **opt)
  end

  # The editor(s) of this catalog title.
  #
  # @param [Hash] opt                 Passed to #creator_list.
  #
  # @return [Array<String>]
  #
  def editor_list(**opt)
    opt[:role] = true unless opt.key?(:role)
    creator_list(:editor, **opt)
  end

  # The translator(s) of this catalog title.
  #
  # @param [Hash] opt                 Passed to #creator_list.
  #
  # @return [Array<String>]
  #
  def translator_list(**opt)
    opt[:role] = true unless opt.key?(:role)
    creator_list(:translator, **opt)
  end

  # The author(s)/creator(s) of this catalog title.
  #
  # @param [Array<Symbol>] types      Default: `#CREATOR_TYPES`
  # @param [Hash]          opt
  #
  # @option opt [Boolean] :role       If *true*, append the contributor type.
  #
  # @return [Array<String>]
  #
  def creator_list(*types, **opt)
    types = types.compact.presence || CREATOR_TYPES
    types.flat_map { |type|
      find_record_items(type)
        .map { |item| [item.given, item.family].join(' ').squish }
        .compact_blank!
        .presence&.tap do |names|
          if (role = opt.key?(:role) ? opt[:role] : CREATOR_ROLE[type])
            role  = type if role.is_a?(TrueClass)
            regex = /(^|\W)#{role}(\W|$)/i
            names.map! { |v| v.match?(regex) ? v : "#{v} (#{role})" }
          end
        end
    }.compact.uniq
  end

end

__loading_end(__FILE__)
