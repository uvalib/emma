# app/models/action/_single.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Base class for actions that are not part of compound actions.
#
class Action::Single < Action
  include Record::Sti::Branch
end

__loading_end(__FILE__)
