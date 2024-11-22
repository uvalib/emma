# app/helpers/head_helper/stylesheets.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper methods for setting/getting '<link rel="stylesheet">' meta-tags.
#
# @see "en.emma.page._generic.head.stylesheets"
#
module HeadHelper::Stylesheets

  include HeadHelper::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # @type [Array<String,Hash,Array(String,Hash)>]
  DEFAULT_PAGE_STYLESHEETS =
    HEAD_CONFIG[:stylesheets]&.compact_blank&.deep_freeze || []

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Access the stylesheets for this page.
  #
  # If a block is given, this invocation is being used to accumulate stylesheet
  # sources; otherwise this invocation is being used to emit the stylesheet
  # '<link>' element(s).
  #
  # @return [ActiveSupport::SafeBuffer]               If no block given.
  # @return [Array<String,Hash,Array(String,Hash)>]   If block given.
  #
  # @yield To supply sources(s) to #set_page_stylesheets.
  # @yieldreturn [String,Hash,Array(String,Hash),Array<String,Hash,Array(String,Hash)>]
  #
  def page_stylesheets
    if block_given?
      set_page_stylesheets(*yield)
    else
      emit_page_stylesheets
    end
  end

  # Set the stylesheet(s) for this page, eliminating any previous value(s).
  #
  # @param [Array] sources
  #
  # @return [Array<String,Hash,Array(String,Hash)>] New @page_stylesheets array
  #
  # @yield To supply additional source(s) to @page_stylesheets.
  # @yieldreturn [String,Hash,Array(String,Hash),Array<String,Hash,Array(String,Hash)>]
  #
  def set_page_stylesheets(*sources)
    @page_stylesheets = sources
    @page_stylesheets.concat(Array.wrap(yield)) if block_given?
    @page_stylesheets
  end

  # Add to the stylesheet(s) for this page.
  #
  # @param [Array] sources
  #
  # @return [Array<String,Hash,Array(String,Hash)>] Updated @page_stylesheets.
  #
  # @yield To supply additional source(s) to @page_stylesheets.
  # @yieldreturn [String,Hash,Array(String,Hash),Array<String,Hash,Array(String,Hash)>]
  #
  # @note Currently unused.
  # :nocov:
  def append_page_stylesheets(*sources)
    @page_stylesheets ||= DEFAULT_PAGE_STYLESHEETS.dup
    @page_stylesheets.concat(sources)
    @page_stylesheets.concat(Array.wrap(yield)) if block_given?
    @page_stylesheets
  end
  # :nocov:

  # Emit the stylesheet '<link>' tag(s) appropriate for the current page.
  #
  # @param [Hash] opt                 Passed to #stylesheet_link_tag
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def emit_page_stylesheets(**opt)
    result = @page_stylesheets&.compact_blank || DEFAULT_PAGE_STYLESHEETS.dup
    result.map! do |src|
      case src
        when Hash  then source, options = src[:src], src.except(:src)
        when Array then source, options = src.first, src.last
        else            source, options = src
      end
      options = options&.reverse_merge(opt) || opt
      options = options.sort.to_h if options.present?
      stylesheet_link_tag(source, options)
    end
    result.uniq!
    result << app_stylesheet(**opt)
    safe_join(result, "\n")
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Main stylesheet for the application.
  #
  # @param [Hash] opt                 Passed to #stylesheet_link_tag
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def app_stylesheet(**opt)
    opt[:media]                   ||= 'all'
    opt[:'data-turbolinks-track'] ||= 'reload'
    stylesheet_link_tag('application', opt).prepend("\n")
  end

end

__loading_end(__FILE__)
