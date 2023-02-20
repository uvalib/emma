# app/controllers/concerns/bookshare_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Controller support methods for access to the Bookshare API service.
#
module BookshareConcern

  extend ActiveSupport::Concern

  include ApiConcern
  include PaginationConcern

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Access the Bookshare API service.
  #
  # @return [BookshareService]
  #
  def bs_api
    # noinspection RubyMismatchedReturnType
    api_service(BookshareService)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # A Bookshare item identifier.
  #
  # @return [String, nil]
  #
  attr_accessor :bs_id

  # A Bookshare journal/periodical series identifier.
  #
  # @return [String, nil]
  #
  attr_accessor :bs_series

  # A Bookshare journal/periodical edition identifier.
  #
  # @return [String, nil]
  #
  attr_accessor :bs_edition

  # A Bookshare artifact format.
  #
  # @return [String, nil]
  #
  attr_accessor :bs_format

  # A Bookshare reading list identifier.
  #
  # @return [String, nil]
  #
  attr_accessor :bs_list

  # A Bookshare member identifier.
  #
  # @return [String, nil]
  #
  attr_accessor :bs_member

  # A remote URL path for retrieving an artifact (download).
  #
  # @return [String, nil]
  #
  attr_accessor :item_download_url

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # A Bookshare API search starting offset.
  #
  # @return [Integer, nil]
  #
  def bs_start
    @bs_start ||= positive(paginator.page_offset)
  end

  # A Bookshare API search limit (page size).
  #
  # @return [Integer, nil]
  #
  def bs_limit
    @bs_limit ||= positive(paginator.page_size)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Return a member associated with the given user.
  #
  # @param [User, String] for_user    Default: `#current_user`.
  # @param [String]       _name       Member name (future).
  #
  # @return [String]
  # @return [nil]
  #
  def get_member(for_user = nil, _name = nil)
    for_user = User.find_record(for_user || current_user)
    case for_user&.bookshare_uid
      when BookshareService::TEST_ACCOUNT
        BookshareService::TEST_MEMBER
      else
        # TODO: Member lookup
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Local names for Bookshare API parameters mapped on to the actual URL
  # parameters(s).
  #
  # @type [Hash{Symbol=>Array<Symbol>}]
  #
  BS_PARAMETERS = {
    bs_edition: %i[editionId     edition],
    bs_format:  %i[fmt],
    bs_id:      %i[bookshareId],
    bs_list:    %i[readingListId reading_list],
    bs_member:  %i[forUser       member],
    bs_series:  %i[seriesId      series],
  }.deep_freeze

  # Local names for Bookshare API parameters.
  #
  # @type [Array<Symbol>]
  #
  BS_KEYS = BS_PARAMETERS.keys.freeze

  # Parameter aliases mapping on to the true Bookshare API parameters.
  #
  # @type [Hash{Symbol=>Symbol}]
  #
  BS_PARAM_ALIAS =
    BS_PARAMETERS.values.flat_map { |keys|
      key, aliases = keys[0], keys[1..-1]
      aliases&.map { |key_alias| [key_alias, key] }
    }.compact.to_h.freeze

  # Build up Bookshare API parameters.
  #
  # @param [Array<Symbol>] keys   Required Bookshare API keys.
  # @param [Hash]          prm    Other parameters.
  #
  # @return [Hash{Symbol=>*}]
  #
  def bs_params(*keys, **prm)
    keys.map! { |k| BS_PARAMETERS[k]&.first || k } if keys.intersect?(BS_KEYS)
    if prm.except!(:format).present?
      BS_PARAM_ALIAS.each_pair do |key_alias, key_name|
        prm[key_name] = prm.delete(key_alias) if prm.key?(key_alias)
      end
      keys -= prm.keys
    end
    bs_params =
      keys.map { |k|
        case k
          when :bookshareId   then v = bs_id
          when :editionId     then v = bs_edition
          when :format        then v = bs_format
          when :limit         then v = bs_limit
          when :member        then v = bs_member
          when :readingListId then v = bs_list
          when :seriesId      then v = bs_series
          when :start         then v = bs_start
          else                     v = nil
        end
        [k, v] if v.present?
      }.compact.to_h
    prm.merge!(bs_params)
  end

  # ===========================================================================
  # :section: Callbacks
  # ===========================================================================

  protected

  # Extract the best-match URL parameter which represents an item identifier.
  #
  # @return [String, nil]
  #
  def set_bs_id
    self.bs_id = get_bs_param(:bs_id) || params[:id]
  end

  # Extract the URL parameter which specifies a journal/periodical series.
  #
  # @return [String, nil]
  #
  def set_bs_series
    self.bs_series = get_bs_param(:bs_series) || params[:id]
  end

  # Extract the URL parameter which specifies a journal/periodical edition.
  #
  # @return [String, nil]
  #
  def set_bs_edition
    self.bs_edition = get_bs_param(:bs_edition) || params[:id]
  end

  # Extract the best-match URL parameter which represents an item format.
  #
  # @return [String, nil]
  #
  def set_bs_format
    self.bs_format = get_bs_param(:bs_format) || BsFormatType.default
  end

  # Extract the URL parameter which specifies a reading list.
  #
  # @return [String, nil]
  #
  def set_bs_list
    self.bs_list = get_bs_param(:bs_list) || params[:id]
  end

  # Extract the URL parameter which indicates a Bookshare member.
  #
  # @return [String, nil]
  #
  def set_bs_member
    self.bs_member = get_bs_param(:bs_member) || get_member
  end

  # Extract the URL parameter which indicates a remote URL path.
  #
  # @return [String, nil]
  #
  def set_item_download_url
    self.item_download_url = params[:url]
  end

  # ===========================================================================
  # :section: Callbacks
  # ===========================================================================

  private

  # Get the value of the associated URL parameter.
  #
  # @param [Symbol] name
  #
  # @return [String, nil]
  #
  def get_bs_param(name)
    request_parameters.slice(*BS_PARAMETERS[name]).values.first
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  THIS_MODULE = self

  included do |base|
    __included(base, THIS_MODULE)
    if respond_to?(:helper_attr)
      helper_attr :bs_id, :bs_series, :bs_edition, :bs_format, :bs_list
    end
  end

end

__loading_end(__FILE__)
