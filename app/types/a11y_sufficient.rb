# app/types/a11y_sufficient.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# API schema - SchemaOrgFields - AccessModeSufficient
#
# "A list of single or combined access modes that are sufficient to understand"
# "all the intellectual content of a resource"
#
# @see "en.emma.type.search.A11ySufficient"
# @see https://schema.org/accessModeSufficient
# @see https://www.w3.org/community/reports/a11y-discov-vocab/CG-FINAL-vocabulary-20230718/#accessModeSufficient                                  W3C WebSchemas Accessibility Terms
# @see https://api.swaggerhub.com/domains/bus/emma-federated-shared-components/0.0.5#/components/schemas/SchemaOrgFields/s_accessModeSufficient   JSON schema specification
#
class A11ySufficient < EnumType

  define_enumeration(SEARCH_TYPES[name.to_sym])

end

__loading_end(__FILE__)
