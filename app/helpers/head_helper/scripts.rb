# app/helpers/head_helper/scripts.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper methods for setting/getting <script> meta-tags.
#
module HeadHelper::Scripts

  include HeadHelper::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # @type [Array<String>]
  DEFAULT_PAGE_JAVASCRIPTS = HEAD_CONFIG[:javascripts]

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Access the scripts for this page.
  #
  # If a block is given, this invocation is being used to accumulate script
  # sources; otherwise this invocation is being used to emit the JavaScript
  # "<script>" element(s).
  #
  # @return [ActiveSupport::SafeBuffer]   If no block given.
  # @return [Array<String>]               If block given.
  #
  # @yield To supply source(s) to #set_page_javascripts.
  # @yieldreturn [String, Array<String>]
  #
  def page_javascripts
    if block_given?
      set_page_javascripts(*yield)
    else
      emit_page_javascripts
    end
  end

  # Set the script(s) for this page, eliminating any previous value(s).
  #
  # @param [Array] sources
  #
  # @return [Array<String>]           The updated @page_javascript contents.
  #
  # @yield To supply additional source(s) to @page_javascript.
  # @yieldreturn [String, Array<String>]
  #
  def set_page_javascripts(*sources)
    @page_javascript = []
    @page_javascript += sources
    @page_javascript += Array.wrap(yield) if block_given?
    @page_javascript
  end

  # Add to the script(s) for this page.
  #
  # @param [Array] sources
  #
  # @return [Array<String>]           The updated @page_javascript contents.
  #
  # @yield To supply additional source(s) to @page_javascript.
  # @yieldreturn [String, Array<String>]
  #
  def append_page_javascripts(*sources)
    @page_javascript ||= DEFAULT_PAGE_JAVASCRIPTS.dup
    @page_javascript += sources
    @page_javascript += Array.wrap(yield) if block_given?
    @page_javascript
  end

  # Emit the "<script>" tag(s) appropriate for the current page.
  #
  # @param [Hash] opt                 Passed to #javascript_include_tag
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def emit_page_javascripts(**opt)
    @page_javascript ||= DEFAULT_PAGE_JAVASCRIPTS.dup
    @page_javascript.flatten!
    @page_javascript.compact_blank!
    @page_javascript.uniq!
    sources = @page_javascript.dup
    sources << meta_options(**opt)
    javascript_include_tag(*sources)
  end

end

__loading_end(__FILE__)
