# app/helpers/layout_helper/page_classes.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper methods support CSS class annotation of the '<body>' element.
#
module LayoutHelper::PageClasses

  include ParamsHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Access the classes for the '<body>' element.
  #
  # If a block is given, this invocation is being used to accumulate CSS class
  # names; otherwise this invocation is being used to emit the CSS classes for
  # inclusion in the '<body>' element definition.
  #
  # @return [String]                      If no block given.
  # @return [Array<String>]               If block given.
  #
  # @yield To supply CSS class(es) to #set_page_classes.
  # @yieldreturn [String, Array<String>]
  #
  def page_classes
    if block_given?
      set_page_classes(*yield)
    else
      emit_page_classes
    end
  end

  # Set the classes for the '<body>' element, eliminating any previous value.
  #
  # @param [Array] values
  #
  # @return [Array<String>]           The current @page_classes contents.
  #
  # @yield To supply additional CSS classes to @page_classes.
  # @yieldreturn [String, Array<String>]
  #
  def set_page_classes(*values)
    @page_classes = []
    @page_classes += values
    @page_classes += Array.wrap(yield) if block_given?
    @page_classes
  end

  # Add to the classes for the '<body>' element.
  #
  # @param [Array] values
  #
  # @return [Array<String>]           The current @page_classes contents.
  #
  # @yield To supply additional CSS classes to @page_classes.
  # @yieldreturn [String, Array<String>]
  #
  def append_page_classes(*values)
    @page_classes ||= default_page_classes
    @page_classes += values
    @page_classes += Array.wrap(yield) if block_given?
    @page_classes
  end

  # Emit the CSS classes for inclusion in the '<body>' element definition.
  #
  # @return [String]
  #
  # == Implementation Notes
  # Invalid CSS name characters are converted to '_'; e.g.:
  # 'user/sessions' -> 'user_sessions'.
  #
  def emit_page_classes
    @page_classes ||= default_page_classes
    @page_classes.flatten!
    @page_classes.compact_blank!
    @page_classes.map! { |c| c.to_s.gsub(/[^a-z_0-9-]/i, '_') }
    @page_classes.uniq!
    @page_classes.join(' ')
  end

  # default_page_classes
  #
  # @param [Hash, nil] p              Default: `#request_parameters`.
  #
  # @return [Array<String>]
  #
  def default_page_classes(p = nil)
    p ||= request_parameters
    c = p[:controller].to_s.presence
    a = p[:action].to_s.presence
    [].tap do |result|
      result << "#{c}-#{a}" if c && a
      result << c           if c
      result << a           if a
      result << 'modal'     if modal?
    end
  end

end

__loading_end(__FILE__)
