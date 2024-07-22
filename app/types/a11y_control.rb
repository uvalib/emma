# app/types/a11y_control.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# API schema - SchemaOrgFields - AccessibilityControl
#
# "Accessibility controls of this instance derived from schema.org"
#
# @see "en.emma.type.search.A11yControl"
# @see https://schema.org/accessibilityControl
# @see https://www.w3.org/community/reports/a11y-discov-vocab/CG-FINAL-vocabulary-20230718/#accessibilityControl                                  W3C WebSchemas Accessibility Terms
# @see https://api.swaggerhub.com/domains/bus/emma-federated-shared-components/0.0.5#/components/schemas/SchemaOrgFields/s_accessibilityControl   JSON schema specification
#
class A11yControl < EnumType

  define_enumeration(SEARCH_TYPES[name.to_sym])

end

__loading_end(__FILE__)
