# app/models/manifest_item/emma_data.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

module ManifestItem::EmmaData

  extend ActiveSupport::Concern

  include Record::EmmaData

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  module InstanceMethods

    include ManifestItem::EmmaData

    # =========================================================================
    # :section: Record::EmmaData overrides
    # =========================================================================

    public

    # Present EMMA data as a structured object.
    #
    # @param [Boolean, nil] refresh   If *false* avoid regeneration.
    #
    # @return [Search::Record::MetadataRecord]
    #
    def emma_record(refresh: nil)
      if refresh.nil?
        refresh   = @emma_record.blank?
        refresh ||= @emma_record.emma_repository.blank?
        refresh ||= @emma_record.emma_repositoryRecordId.blank?
      end
      @emma_record = nil if refresh
      @emma_record ||= make_emma_record(emma_metadata(refresh: refresh))
    end

    # Present EMMA data as a hash.
    #
    # @param [Boolean, nil] refresh   If *false* avoid regeneration.
    #
    # @return [Hash]
    #
    def emma_metadata(refresh: nil)
      if refresh.nil?
        refresh   = @emma_metadata.blank?
        refresh ||= @emma_metadata[:emma_repository].blank?
        refresh ||= @emma_metadata[:emma_repositoryRecordId].blank?
      end
      @emma_metadata = nil if refresh
      @emma_metadata ||=
        parse_emma_data(self).tap do |res|
          res[:emma_repository] ||=
            self.repository || EmmaRepository.default
          res[:emma_repositoryRecordId] ||=
            self.submission_id || generate_submission_id
          res[:emma_retrievalLink] ||=
            make_retrieval_link(res[:emma_repositoryRecordId])
        end
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # emma_repository
    #
    # @return [EmmaRepository]
    #
    def emma_repository
      emma_record.emma_repository
    end

  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  THIS_MODULE = self

  included do |base|
    __included(base, THIS_MODULE)
    assert_record_class(base, THIS_MODULE)
    include InstanceMethods
  end

end

__loading_end(__FILE__)
