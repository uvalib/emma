# app/records/bs/shared/creator_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods mixed in to record elements related to authors, editors, etc.
#
module Bs::Shared::CreatorMethods

  include Api::Shared::CreatorMethods
  include Bs::Shared::CommonMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # @type [Array<String>]
  AUTHOR_TYPES = %w(author coWriter).freeze

  # @type [Array<String>]
  EDITOR_TYPES = %w(editor abridger adapter).freeze

  # @type [Array<String>]
  COMPOSER_TYPES = %w(composer).freeze

  # @type [Array<String>]
  LYRICIST_TYPES = %w(lyricist).freeze

  # @type [Array<String>]
  ARRANGER_TYPES = %w(arranger).freeze

  # @type [Array<String>]
  TRANSLATOR_TYPES = %w(translator transcriber).freeze

  # @type [Array<String>]
  CREATOR_TYPES = %w(
    author
    coWriter
    editor
    composer
    arranger
    lyricist
    abridger
    adapter
  ).freeze

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
    creator_list(*AUTHOR_TYPES, **opt)
  end

  # The editor(s) of this catalog title.
  #
  # @param [Hash] opt                 Passed to #creator_list.
  #
  # @return [Array<String>]
  #
  def editor_list(**opt)
    creator_list(*EDITOR_TYPES, **opt)
  end

  # The composer(s) of this catalog title.
  #
  # @param [Hash] opt                 Passed to #creator_list.
  #
  # @return [Array<String>]
  #
  def composer_list(**opt)
    creator_list(*COMPOSER_TYPES, **opt)
  end

  # The lyricist(s) of this catalog title.
  #
  # @param [Hash] opt                 Passed to #creator_list.
  #
  # @return [Array<String>]
  #
  def lyricist_list(**opt)
    creator_list(*LYRICIST_TYPES, **opt)
  end

  # The arranger(s) of this catalog title.
  #
  # @param [Hash] opt                 Passed to #creator_list.
  #
  # @return [Array<String>]
  #
  def arranger_list(**opt)
    creator_list(*ARRANGER_TYPES, **opt)
  end

  # The translator(s) of this catalog title.
  #
  # @param [Hash] opt                 Passed to #creator_list.
  #
  # @return [Array<String>]
  #
  def translator_list(**opt)
    creator_list(*TRANSLATOR_TYPES, **opt)
  end

  # The author(s)/creator(s) of this catalog title.
  #
  # @param [Array<String>] types      Default: `#CREATOR_TYPES`
  # @param [Hash]          opt        Passed to #contributor_list.
  #
  # @option opt [Boolean] :role       If *true*, append the contributor type.
  #
  # @return [Array<String>]
  #
  def creator_list(*types, **opt)
    types = types.compact.presence || CREATOR_TYPES
    list =
      %i[authors composers lyricists arrangers].flat_map do |field|
        next unless respond_to?(field)
        next unless types.include?((type = field.to_s.singularize))
        values = send(field) || []
        opt[:role] ? values.map { |v| "#{v} (#{type})" } : values
      end
    list += contributor_list(*types, **opt)
    list.compact.uniq
  end

  # All contributor(s) to this catalog title.
  #
  # @param [Array<String>] types      Default: all
  # @param [Api::Record]   target     Default: `self`.
  # @param [Hash]          opt
  #
  # @option opt [Boolean] :role       If *true*, append the contributor type.
  #
  # @return [Array<String>]
  #
  def contributor_list(*types, target: nil, **opt)
    result = find_items(:contributors, target: target)
    result = result.select { |c| types.include?(c.type) } if types.present?
    result.map { |c| c.label(opt[:role]) }
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # All contributors to this catalog title keyed by contributor type.
  #
  # @param [Array<String>] roles      Default: `BsContributorType#values`
  #
  # @return [Hash{Symbol=>Array<String>}]
  #
  def contributor_table(*roles)
    return {} unless respond_to?(:contributors)
    roles = roles.compact.presence || BsContributorType.values
    roles.map { |role|
      k = role.to_sym
      v = contributors.map { |c| c.label if c.type == role }.compact
      [k, v]
    }.to_h
  end

end

__loading_end(__FILE__)
