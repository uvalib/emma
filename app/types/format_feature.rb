# app/types/format_feature.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# API schema - FormatFeature
#
# "Feature of the format used by this instance of this work"
#
# @see "en.emma.type.search.FormatFeature"
# @see https://api.swaggerhub.com/domains/bus/emma-federated-shared-components/0.0.5#/components/schemas/EmmaCommonFields/emma_formatFeature  JSON schema specification
#
class FormatFeature < EnumType

  define_enumeration(SEARCH_TYPES[name.to_sym])

end

__loading_end(__FILE__)
