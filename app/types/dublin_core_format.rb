# app/types/dublin_core.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# API schema - DublinCoreFields - Format
#
# "Format of this instance of the work"
#
# @see "en.emma.type.search.DublinCoreFormat"
# @see https://www.dublincore.org/specifications/dublin-core/dcmi-terms/terms/format                                        DCMI Metadata Terms Format
# @see https://api.swaggerhub.com/domains/bus/emma-federated-shared-components/0.0.5#/components/schemas/DublinCoreFormat   JSON schema specification
#
class DublinCoreFormat < EnumType

  define_enumeration(SEARCH_TYPES[name.to_sym])

end

__loading_end(__FILE__)
