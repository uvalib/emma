# app/types/a11y_access_mode.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# API schema - SchemaOrgFields - AccessMode
#
# "How the user can perceive this instance of the work"
#
# @see "en.emma.type.search.A11yAccessMode"
# @see https://schema.org/accessMode
# @see https://www.w3.org/community/reports/a11y-discov-vocab/CG-FINAL-vocabulary-20230718/#accessMode                                  W3C WebSchemas Accessibility Terms
# @see https://api.swaggerhub.com/domains/bus/emma-federated-shared-components/0.0.5#/components/schemas/SchemaOrgFields/s_accessMode   JSON schema specification
#
class A11yAccessMode < EnumType

  define_enumeration(SEARCH_TYPES[name.to_sym])

end

__loading_end(__FILE__)
