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
  # :section: Callbacks
  # ===========================================================================

  protected

  # Extract the best-match URL parameter which represents an item identifier.
  #
  # @return [String]                  Value of `params[:id]`.
  # @return [nil]                     No :id, :bookshareId found.
  #
  def set_bs_id
    self.bs_id = params[:bookshareId] || params[:id]
  end

  # Extract the URL parameter which specifies a journal/periodical series.
  #
  # @return [String]                  Value of `params[:series]`.
  # @return [nil]                     No :series, :seriesId found.
  #
  def set_bs_series
    self.bs_series = params[:seriesId] || params[:series] || params[:id]
  end

  # Extract the URL parameter which specifies a journal/periodical edition.
  #
  # @return [String]                  Value of `params[:id]`.
  # @return [nil]                     No :id, :edition, :editionId found.
  #
  def set_bs_edition
    self.bs_edition = params[:editionId] || params[:edition] || params[:id]
  end

  # Extract the best-match URL parameter which represents an item format.
  #
  # @return [String]                  Value of `params[:fmt]`.
  # @return [nil]                     No :fmt found.
  #
  def set_bs_format
    self.bs_format = params[:fmt] || BsFormatType.default
  end

  # Extract the URL parameter which specifies a reading list.
  #
  # @return [String]                  Value of `params[:id]`.
  # @return [nil]                     No :id, :readingListId found.
  #
  def set_bs_list
    self.bs_list = params[:readingListId] || params[:id]
  end

  # Extract the URL parameter which indicates a Bookshare member.
  #
  # @return [String]                  Value of `params[:member]`.
  # @return [nil]                     No :member, :forUser found.
  #
  def set_bs_member
    self.bs_member = params[:forUser] || params[:member] || get_member
  end

  # Extract the URL parameter which indicates a remote URL path.
  #
  # @return [String]                  Value of `params[:url]`.
  # @return [nil]                     No :url found.
  #
  def set_item_download_url
    self.item_download_url = params[:url]
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
