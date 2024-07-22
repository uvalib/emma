# app/types/rights.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# API schema - DublinCoreFields - Rights
#
# "Ownership-based usage rights"
#
# @see "en.emma.type.search.Rights"
# @see https://www.dublincore.org/specifications/dublin-core/dcmi-terms/terms/rights                                                  DCMI Metadata Terms Format
# @see https://api.swaggerhub.com/domains/bus/emma-federated-shared-components/0.0.5#/components/schemas/DublinCoreFields/dc_rights   JSON schema specification
#
class Rights < EnumType

  define_enumeration(SEARCH_TYPES[name.to_sym])

end

__loading_end(__FILE__)
