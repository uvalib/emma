# app/records/lookup/crossref.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Namespace for objects de-serialized from an external service API.
#
module Lookup::Crossref
  module Api;     end
  module Message; end
  module Record;  end
  module Shared;  end
end

module Lookup::Crossref
  include Lookup::Crossref::Api::Common
end

__loading_end(__FILE__)
