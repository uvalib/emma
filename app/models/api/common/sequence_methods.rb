# app/models/api/common/sequence_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods mixed in to record elements with links.
#
module Api::Common::SequenceMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Return the indicated link if present.
  #
  # @param [String, Symbol] rel_name
  #
  # @return [String, nil]
  #
  def get_link(rel_name)
    return unless respond_to?(:links) && links.is_a?(Array)
    links.find { |link|
      break link.href if (link.rel == rel_name) && link.href.present?
    }
  end

end

__loading_end(__FILE__)
