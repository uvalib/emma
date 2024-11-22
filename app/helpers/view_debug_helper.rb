# app/helpers/view_debug_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper support methods for debugging display generation.
#
module ViewDebugHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether debugging of view files is active.
  #
  def view_debug?
    DEBUG_VIEW
  end

  # Output to STDERR.
  #
  # @param [String] template
  # @param [Array]  arg
  # @param [String] separator
  #
  # @return [void]
  #
  def view_debug(template, *arg, separator: ' ')
    return unless view_debug?
    template = template.to_s.delete_prefix(Rails.root.to_s)
    __output arg.prepend("--- VIEW TEMPLATE #{template}").join(separator)
  end

  # Used to annotate a view template that is not expected to be used.
  #
  # @param [String] template
  # @param [Array]  arg
  # @param [String] separator
  #
  def view_abort(template, *arg, separator: ' ')
    template = template.to_s.delete_prefix(Rails.root.to_s)
    message  = "#{template} - %s" % arg.join(separator)
    if application_deployed?
      raise message
    else
      abort message
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    __included(base, self)
  end

end

__loading_end(__FILE__)
