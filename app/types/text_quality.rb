# app/types/text_quality.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# API schema - RemediationFields - TextQuality
#
# @see "en.emma.type.search.TextQuality"
# @see https://api.swaggerhub.com/domains/bus/emma-federated-shared-components/0.0.5#/components/schemas/RemediationFields/rem_textQquality   JSON schema specification
#
class TextQuality < EnumType

  define_enumeration(SEARCH_TYPES[name.to_sym])

end

__loading_end(__FILE__)
