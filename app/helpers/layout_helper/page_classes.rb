# app/helpers/layout_helper/page_classes.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# LayoutHelper::PageClasses
#
module LayoutHelper::PageClasses

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Access the classes for the "<body>" element.
  #
  # If a block is given, this invocation is being used to accumulate CSS class
  # names; otherwise this invocation is being used to emit the CSS classes for
  # inclusion in the "<body>" element definition.
  #
  # @yield Supplies CSS class(es) to #set_page_classes.
  # @yieldreturn [String, Array<String>]
  #
  # @return [String]                      If no block given.
  # @return [Array<String>]               If block given.
  #
  def page_classes
    if block_given?
      set_page_classes(*yield)
    else
      emit_page_classes
    end
  end

  # Set the classes for the "<body>" element, eliminating any previous value.
  #
  # @yield Supplies additional CSS classes to @page_classes.
  # @yieldreturn [String, Array<String>]
  #
  # @param [Array] values
  #
  # @return [Array<String>]           The current @page_classes contents.
  #
  def set_page_classes(*values)
    @page_classes = []
    @page_classes += values
    @page_classes += Array.wrap(yield) if block_given?
    @page_classes
  end

  # Add to the classes for the "<body>" element.
  #
  # @yield Supplies additional CSS classes to @page_classes.
  # @yieldreturn [String, Array<String>]
  #
  # @param [Array] values
  #
  # @return [Array<String>]           The current @page_classes contents.
  #
  def append_page_classes(*values)
    @page_classes ||= default_page_classes
    @page_classes += values
    @page_classes += Array.wrap(yield) if block_given?
    @page_classes
  end

  # Emit the CSS classes for inclusion in the "<body>" element definition.
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
    @page_classes.reject!(&:blank?)
    @page_classes.map! { |c| c.to_s.gsub(/[^a-z_0-9-]/i, '_') }
    @page_classes.join(' ')
  end

  # default_page_classes
  #
  # @param [Hash] p                   Default: `#params`.
  #
  # @return [Array<String>]
  #
  def default_page_classes(p = nil)
    p ||= defined?(params) ? params : {}
    c = p[:controller].to_s.presence
    a = p[:action].to_s.presence
    result = []
    result << "#{c}-#{a}" if c && a
    result << c           if c
    result << a           if a
    result
  end

end

__loading_end(__FILE__)