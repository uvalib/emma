# app/types/dcmi_type.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# API schema - DublinCoreFields - Type
#
# "Type of this instance of the work"
#
# @see "en.emma.type.search.DcmiType"
# @see https://www.dublincore.org/specifications/dublin-core/dcmi-terms/terms/type                                                  DCMI Metadata Terms Type
# @see https://api.swaggerhub.com/domains/bus/emma-federated-shared-components/0.0.5#/components/schemas/DublinCoreFields/dc_type   JSON schema specification
#
class DcmiType < EnumType

  define_enumeration(SEARCH_TYPES[name.to_sym])

end

__loading_end(__FILE__)
