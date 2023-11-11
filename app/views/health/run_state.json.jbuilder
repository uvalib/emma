# app/views/health/run_state.json.jbuilder
#
# frozen_string_literal: true
# warn_indent:           true
#
# System availability.

state ||= @state || RunState.current

json.run_state state
