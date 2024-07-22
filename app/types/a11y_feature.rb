# app/types/a11y_feature.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# API schema - SchemaOrgFields - AccessibilityFeature
#
# "Accessibility features of this instance derived from schema.org"
#
# @see "en.emma.type.search.A11yFeature"
# @see https://schema.org/accessibilityFeature
# @see https://www.w3.org/community/reports/a11y-discov-vocab/CG-FINAL-vocabulary-20230718/#accessibilityFeature                                  W3C WebSchemas Accessibility Terms
# @see https://api.swaggerhub.com/domains/bus/emma-federated-shared-components/0.0.5#/components/schemas/SchemaOrgFields/s_accessibilityFeature   JSON schema specification
#
class A11yFeature < EnumType

  define_enumeration(SEARCH_TYPES[name.to_sym])

end

__loading_end(__FILE__)
