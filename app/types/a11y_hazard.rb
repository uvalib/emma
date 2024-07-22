# app/types/a11y_hazard.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# API schema - SchemaOrgFields - AccessibilityHazard
#
# "Accessibility hazards of this instance derived from schema.org"
#
# @see "en.emma.type.search.A11yHazard"
# @see https://schema.org/accessibilityHazard
# @see https://www.w3.org/community/reports/a11y-discov-vocab/CG-FINAL-vocabulary-20230718/#accessibilityHazard                                 W3C WebSchemas Accessibility Terms
# @see https://api.swaggerhub.com/domains/bus/emma-federated-shared-components/0.0.5#/components/schemas/SchemaOrgFields/s_accessibilityHazard  JSON schema specification
#
class A11yHazard < EnumType

  define_enumeration(SEARCH_TYPES[name.to_sym])

end

__loading_end(__FILE__)
