# app/records/bs.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Namespace for objects serialized to and de-serialized from the Bookshare API.
#
#--
# noinspection RubyClassModuleNamingConvention
#++
module Bs
  module Api;     end
  module Message; end
  module Record;  end
  module Shared;  end
end

require 'bs/api/common'

#--
# noinspection RubyClassModuleNamingConvention
#++
module Bs
  include Bs::Api::Common
end

__loading_end(__FILE__)
