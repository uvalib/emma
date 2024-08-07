# app/records/lookup/_remote_service.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Namespace for common definitions for objects de-serialized from an external
# service API.
#
# === Implementation Notes
# There are no ./_remote_service/{message,record} directories because there are
# no classes defined within this namespace, only mixin modules.
#
module Lookup::RemoteService
  module Api;     end
  module Message; end
  module Record;  end
  module Shared;  end
end

module Lookup::RemoteService
  include Lookup::RemoteService::Api::Common
end

__loading_end(__FILE__)
