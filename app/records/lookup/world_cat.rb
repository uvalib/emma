# app/records/lookup/world_cat.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Namespace for objects de-serialized from an external service API.
#
module Lookup::WorldCat
  module Api;     end
  module Message; end
  module Record;  end
  module Shared;  end
end

module Lookup::WorldCat
  include Lookup::WorldCat::Api::Common
end

__loading_end(__FILE__)
