# app/types/deployment.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Application deployment type.
#
# @see "en.emma.application.deployment"
#
class Deployment < EnumType

  define_enumeration do
    config_section(:application, :deployment).transform_values { |v| v[:name] }
  end

end

__loading_end(__FILE__)
