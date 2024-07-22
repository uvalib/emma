# app/types/a11y_api.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# API schema - SchemaOrgFields - AccessibilityAPI
#
# "Accessibility APIs of this instance derived from schema.org"
#
# @see "en.emma.type.search.A11yAPI"
# @see https://schema.org/accessibilityAPI
# @see https://www.w3.org/community/reports/a11y-discov-vocab/CG-FINAL-vocabulary-20230718/#accessibilityAPI                                  W3C WebSchemas Accessibility Terms
# @see https://api.swaggerhub.com/domains/bus/emma-federated-shared-components/0.0.5#/components/schemas/SchemaOrgFields/s_accessibilityAPI   JSON schema specification
#
# === Usage Notes
# Because only ever has the value of "ARIA", it is generally ignored.
#
class A11yAPI < EnumType

  define_enumeration(SEARCH_TYPES[name.to_sym])

end

__loading_end(__FILE__)
