# app/models/kurzweil_file.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# A Kurzweil file object.
#
class KurzweilFile < CachedFile

  include KurzweilFormat

end

__loading_end(__FILE__)
