# app/helpers/layout_helper/main.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper methods for the '<main>' section..
#
module LayoutHelper::Main

  include LayoutHelper::Common

  include HelpHelper
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
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @yield To supply (additional) 'heading-bar' control elements.
  # @yieldreturn [String,Array]
  #
  #--
  # == Variations
  #++
  #
  # @overload page_heading(title)
  #   Render just the title text; e.g.: `
  #     <h1 class="heading">*title*</h1>
  #   `
  #   @param [ActiveSupport::SafeBuffer, String] title
  #   @return [ActiveSupport::SafeBuffer]
  #
  # @overload page_heading(title, help: help_span)
  #   Include a help icon next to the title text; e.g.: `
  #     <h1 class="heading"><span class="text">*title*</span>*help_span*</h1>
  #   `
  #   @param [ActiveSupport::SafeBuffer, String]                title
  #   @param [ActiveSupport::SafeBuffer, Array<Symbol>, Symbol] help
  #   @return [ActiveSupport::SafeBuffer]
  #
  # @overload page_heading(title, logo: logo_div)
  #   Create a container with the heading to the logo element; e.g.: `
  #     <div class="heading container">
  #       <h1 class="heading">*title*</h1>*logo_div*
  #     </div>
  #   `
  #   @param [ActiveSupport::SafeBuffer, String] title
  #   @param [ActiveSupport::SafeBuffer, Symbol] logo
  #   @return [ActiveSupport::SafeBuffer]
  #
  # @overload page_heading(title, *controls)
  #   Create a 'heading-bar' container with the heading and other divs; e.g.: `
  #     <div class="heading-bar">
  #       <h1 class="heading">*title*</h1>*controls*
  #     </div>
  #   `
  #   @param [ActiveSupport::SafeBuffer, String] title
  #   @param [Array<ActiveSupport::SafeBuffer>]  controls
  #   @return [ActiveSupport::SafeBuffer]
  #
  # @overload page_heading(title, *controls, help: help, logo: logo)
  #   All features combined; e.g.: `
  #     <div class="heading-bar">
  #       <div class="heading container">
  #         <h1 class="heading">
  #           <span class="text">*title*</span>
  #           *help*
  #         </h1>
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
  #--
  # noinspection RubyMismatchedArgumentType
  #++
  def page_heading(title, *controls, help: nil, logo: nil, **)
    help  &&= help_popup(*Array.wrap(help).first(2)) unless help.html_safe?
    logo  &&= repository_source_logo(logo)           unless logo.html_safe?

    added   = (yield if block_given?)
    added   = [*controls, *added].compact.presence

    title   = ERB::Util.h(title)
    title   = html_span(title, class: 'text') << help if help

    heading = html_tag(:h1, title, class: 'heading')
    heading = html_div(class: 'heading container') { heading << logo } if logo
    heading = html_div(heading, *added, class: 'heading-bar')          if added
    heading
  end

end

__loading_end(__FILE__)
