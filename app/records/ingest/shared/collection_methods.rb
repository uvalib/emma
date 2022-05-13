# app/records/ingest/shared/collection_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# This is included in record classes that define :LIST_ELEMENT to confirm that
# they are intended to function as collections.
#
# @see Model::ClassMethods#validate_relations
#
module Ingest::Shared::CollectionMethods
  include Api::Shared::CollectionMethods
  include Ingest::Shared::CommonMethods
end

__loading_end(__FILE__)
