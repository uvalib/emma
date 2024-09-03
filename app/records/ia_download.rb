# app/records/ia_download.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Namespace for objects related to the Internet Archive
# "Printdisabled Unencrypted Ebook API".
#
module IaDownload
  module Api;     end
  module Message; end
  module Record;  end
  module Shared;  end
end

module IaDownload
  include IaDownload::Api::Common
end

__loading_end(__FILE__)
