# app/views/health/run_state.xml.builder
#
# frozen_string_literal: true
# warn_indent:           true
#
# System availability.

state ||= @state || RunState.current

xml.run_state do
  state.each_pair do |k, v|
    xml.tag! k, v
  end
end
