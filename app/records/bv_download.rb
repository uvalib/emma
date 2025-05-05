# app/records/bv_download.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Namespace for objects related to accessing the AWS S3 bucket containing the
# EMMA publisher collections.
#
module BvDownload
  module Api;     end
  module Message; end
  module Record;  end
  module Shared;  end
end

module BvDownload
  include BvDownload::Api::Common
end

__loading_end(__FILE__)
