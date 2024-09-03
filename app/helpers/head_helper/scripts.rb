# app/helpers/head_helper/scripts.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper methods for setting/getting '<script>' meta-tags.
#
module HeadHelper::Scripts

  include HeadHelper::Common
  include ImageHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # @type [Array<String,Hash,Array(String,Hash)>]
  DEFAULT_PAGE_JAVASCRIPTS =
    HEAD_CONFIG[:javascripts]&.compact_blank&.deep_freeze || []

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Access the scripts for this page.
  #
  # If a block is given, this invocation is being used to accumulate script
  # sources; otherwise this invocation is being used to emit the JavaScript
  # '<script>' element(s).
  #
  # @return [ActiveSupport::SafeBuffer]               If no block given.
  # @return [Array<String,Hash,Array(String,Hash)>]   If block given.
  #
  # @yield To supply source(s) to #set_page_javascripts.
  # @yieldreturn [String,Hash,Array(String,Hash),Array<String,Hash,Array(String,Hash)>]
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
  # @return [Array<String,Hash,Array(String,Hash)>] New @page_javascript array.
  #
  # @yield To supply additional source(s) to @page_javascript.
  # @yieldreturn [String,Hash,Array(String,Hash),Array<String,Hash,Array(String,Hash)>]
  #
  def set_page_javascripts(*sources)
    @page_javascript = sources
    @page_javascript.concat(Array.wrap(yield)) if block_given?
    @page_javascript
  end

  # Add to the script(s) for this page.
  #
  # @param [Array] sources
  #
  # @return [Array<String,Hash,Array(String,Hash)>] Updated @page_javascript.
  #
  # @yield To supply additional source(s) to @page_javascript.
  # @yieldreturn [String,Hash,Array(String,Hash),Array<String,Hash,Array(String,Hash)>]
  #
  def append_page_javascripts(*sources)
    @page_javascript ||= DEFAULT_PAGE_JAVASCRIPTS.dup
    @page_javascript.concat(sources)
    @page_javascript.concat(Array.wrap(yield)) if block_given?
    @page_javascript
  end

  # Emit the '<script>' tag(s) appropriate for the current page.
  #
  # @param [Hash] opt                 Passed to #javascript_include_tag
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def emit_page_javascripts(**opt)
    result = @page_javascript&.compact_blank! || DEFAULT_PAGE_JAVASCRIPTS.dup
    result.map! do |src|
      case src
        when Hash  then source, options = src[:src], src.except(:src)
        when Array then source, options = src.first, src.last
        else            source, options = src
      end
      options = options&.reverse_merge(opt) || opt
      options = options.sort.to_h if options.present?
      javascript_include_tag(source, options)
    end
    result.uniq!
    result << app_javascript(**opt)
    if Rails.env.test?
      result << capybara_lockstep(opt)              if CapybaraLockstep.active
    else
      result << Matomo.script_element(current_user) if Matomo.enabled?
    end
    safe_join(result, "\n")
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Main JavaScript for the application.
  #
  # @param [Hash] opt                 Passed to #javascript_include_tag
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def app_javascript(**opt)
    opt[:'data-turbolinks-track'] ||= 'reload'
    javascript_include_tag('application', opt).prepend("\n")
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Dynamic overrides for JavaScript settings that are otherwise supplied at
  # the time of asset compilation.  Setting values here makes it possible to
  # change values that were in effect at that time -- particularly useful for
  # settings that are based on environment variable settings.
  #
  # @see #page_script_settings
  #
  SCRIPT_SETTINGS_OVERRIDES = {
    RAILS_ENV:       Rails.env.to_s,
    DEPLOYED:        application_deployed?,
    SEARCH_ANALYSIS: SearchesDecorator::SEARCH_ANALYSIS,
    APP_DEBUG:       not_deployed? && (Rails.env.to_s != 'test'),
  }.deep_freeze

  # The set of overrides to JavaScript client settings.
  #
  # @return [Hash]
  #
  def script_settings
    @script_settings ||= SCRIPT_SETTINGS_OVERRIDES.deep_dup
  end

  # Add override(s) to JavaScript client settings.
  #
  # @param [Hash] opt                 Settings override values.
  #
  # @return [Hash]
  #
  def script_setting(**opt)
    script_settings.merge!(opt)
  end

  # Produce inline JavaScript to setup dynamic constant values on the client.
  #
  # The values set here override the values "baked in" to the JavaScript when
  # assets were compiled -- this allows the values of environment variables
  # for the running server to be used in place of the values of those
  # variables when the assets were compiled.
  #
  # Also, this provides a way to override any number of settings in the
  # JavaScript (e.g., enabling or disabling features).
  #
  # @param [Hash] opt                 Optional additional settings overrides.
  #
  # @return [ActiveSupport::SafeBuffer, nil]
  #
  # @see file:app/assets/javascripts/shared/assets.js.erb
  #
  def page_script_settings(**opt)
    opt[:OverrideScriptSettings]  ||= script_settings
    opt[:Image_placeholder_asset] ||= image_placeholder_asset
    <<~HEREDOC.squish.html_safe
      <script type="text/javascript">
        window.ASSET_OVERRIDES = #{js(opt)};
      </script>
    HEREDOC
  end

end

__loading_end(__FILE__)
