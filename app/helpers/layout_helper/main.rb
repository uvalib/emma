# app/helpers/layout_helper/main.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper methods for the '<main>' section..
#
module LayoutHelper::Main

  include LayoutHelper::Common

  include LogoHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Render the *h1* heading for the page.
  #
  # @param [ActiveSupport::SafeBuffer, String]                     title
  # @param [Array<ActiveSupport::SafeBuffer>]                      controls
  # @param [ActiveSupport::SafeBuffer, Array<Symbol>, Symbol, nil] help
  # @param [ActiveSupport::SafeBuffer, Symbol, nil]                logo
  # @param [Hash]                                                  opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @yield To supply (additional) 'heading-bar' control elements.
  # @yieldreturn [String,Array]
  #
  #--
  # === Variations
  #++
  #
  # @overload page_heading(title)
  #   Render just the title text; e.g.: `
  #     <h1 class="heading plain">*title*</h1>
  #   `
  #   @param [ActiveSupport::SafeBuffer, String] title
  #   @return [ActiveSupport::SafeBuffer]
  #
  # @overload page_heading(title, help: help_span)
  #   Include a help icon next to the title text; e.g.: `
  #     <div class="heading and-help">
  #       <h1 class="text">*title*</h1>*help_span*
  #     </div>
  #   `
  #   @param [ActiveSupport::SafeBuffer, String]                title
  #   @param [ActiveSupport::SafeBuffer, Array<Symbol>, Symbol] help
  #   @return [ActiveSupport::SafeBuffer]
  #
  # @overload page_heading(title, logo: logo_div)
  #   Create a container with the heading to the logo element; e.g.: `
  #     <div class="heading and-logo">
  #       <h1 class="text">*title*</h1>*logo_div*
  #     </div>
  #   `
  #   @param [ActiveSupport::SafeBuffer, String] title
  #   @param [ActiveSupport::SafeBuffer, Symbol] logo
  #   @return [ActiveSupport::SafeBuffer]
  #
  # @overload page_heading(title, *controls)
  #   Create a 'heading-bar' container with the heading and other divs; e.g.: `
  #     <div class="heading-bar">
  #       <h1 class="heading plain">*title*</h1>*controls*
  #     </div>
  #   `
  #   @param [ActiveSupport::SafeBuffer, String] title
  #   @param [Array<ActiveSupport::SafeBuffer>]  controls
  #   @return [ActiveSupport::SafeBuffer]
  #
  # @overload page_heading(title, *controls, help: help, logo: logo)
  #   All features combined; e.g.: `
  #     <div class="heading-bar">
  #       <div class="heading and-logo">
  #         <div class="heading and-help">
  #           <h1 class="text">*title*</h1>
  #           *help*
  #         </div>
  #         *logo*
  #       </div>
  #       *controls*
  #     </div>
  #   `
  #   @param [ActiveSupport::SafeBuffer, String]                title
  #   @param [Array<ActiveSupport::SafeBuffer>]                 controls
  #   @param [ActiveSupport::SafeBuffer, Array<Symbol>, Symbol] help
  #   @param [ActiveSupport::SafeBuffer, Symbol]                logo
  #   @return [ActiveSupport::SafeBuffer]
  #
  # @yield Additional controls if provided.
  # @yieldreturn [Array,ActiveSupport::SafeBuffer,nil]
  #
  def page_heading(title, *controls, help: nil, logo: nil, **opt)
    help &&= page_heading_help(help)      unless help.html_safe?
    logo &&= repository_source_logo(logo) unless logo.html_safe?
    controls.concat(Array.wrap(yield))    if block_given?
    added  = controls.compact.presence

    prepend_css!(opt, ((help || logo) ? 'text' : 'heading plain'))
    result = html_h1(title, **opt)
    result = html_div(class: 'heading and-help') { result << help } if help
    result = html_div(class: 'heading and-logo') { result << logo } if logo
    result = html_div(result, *added, class: 'heading-bar')         if added
    result
  end

  # page_heading_help
  #
  # @param [ActiveSupport::SafeBuffer, Array<Symbol>, Symbol, nil] help
  #
  # @return [ActiveSupport::SafeBuffer, nil]
  #
  def page_heading_help(help)
    # noinspection RubyMismatchedReturnType
    return help if help.html_safe?
    topic = Array.wrap(help).first(2).compact
    help_popup(*topic) if topic.present?
  end

end

__loading_end(__FILE__)
