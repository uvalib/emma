# app/models/artifact.rb
#
# frozen_string_literal: true
# warn_indent:           true
#

__loading_begin(__FILE__)

# Base class for database record models.
#
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end

__loading_end(__FILE__)
