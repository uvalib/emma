# app/models/phase/_single.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Base class for phases that are not part of bulk operations.
#
class Phase::Single < Phase
  include Record::Sti::Branch
end

__loading_end(__FILE__)
