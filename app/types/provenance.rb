# app/types/provenance.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# API schema - DublinCoreFields - Provenance
#
# "Source of this instance of the work"
#
# @note Deprecated with API 0.0.5
#
# @see "en.emma.type.search.Provenance"
# @see https://www.dublincore.org/specifications/dublin-core/dcmi-terms/terms/provenance                                                  DCMI Metadata Terms Format
# @see https://api.swaggerhub.com/domains/bus/emma-federated-shared-components/0.0.5#/components/schemas/DublinCoreFields/dc_provenance   JSON schema specification
#
class Provenance < EnumType

  define_enumeration(SEARCH_TYPES[name.to_sym])

end

__loading_end(__FILE__)
