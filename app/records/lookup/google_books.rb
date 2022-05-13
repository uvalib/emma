# app/records/lookup/google_books.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Namespace for objects de-serialized from an external service API.
#
module Lookup::GoogleBooks
  module Api;     end
  module Message; end
  module Record;  end
  module Shared;  end
end

module Lookup::GoogleBooks
  include Lookup::GoogleBooks::Api::Common
end

__loading_end(__FILE__)
