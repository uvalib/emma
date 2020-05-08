# app/records/ingest.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Namespace for objects de-serialized from the EMMA Unified Search API.
#
# @see https://app.swaggerhub.com/apis/kden/emma-federated-ingestion-api/0.0.3
# @see https://api.swaggerhub.com/apis/kden/emma-federated-ingestion-api/0.0.3
# @see https://api.swaggerhub.com/domains/kden/emma-federated-shared-components/0.0.2
#
module Ingest
  module Api;     end
  module Message; end
  module Record;  end
  module Shared;  end
end

require 'ingest/api/common'

module Ingest
  include Ingest::Api::Common
end

__loading_end(__FILE__)
