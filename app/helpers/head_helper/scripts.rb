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
  DEFAULT_PAGE_JAVASCRIPTS = HEAD_CONFIG[:javascripts] || []

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
    # noinspection RubyMismatchedArgumentType
    sources << meta_options(**opt)
    javascript_include_tag(*sources)
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
    RAILS_ENV: Rails.env.to_s,
    DEPLOYED:  application_deployed?,
  }.deep_freeze

  # The set of overrides to JavaScript client settings.
  #
  # @return [Hash{Symbol=>Any}]
  #
  # @see #SCRIPT_SETTINGS_OVERRIDES
  #
  def script_settings
    # noinspection RubyMismatchedReturnType
    @script_settings ||= SCRIPT_SETTINGS_OVERRIDES.deep_dup
  end

  # Add override(s) to JavaScript client settings.
  #
  # @param [Hash] opt                 Settings override values.
  #
  # @return [Hash{Symbol=>Any}]
  #
  # @see #script_settings
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
  # @see #script_settings
  # @see file:app/assets/javascripts/shared/assets.js.erb
  #
  def page_script_settings(**opt)
    asset_overrides = {
      OverrideScriptSettings:  script_settings,
      Image_placeholder_asset: asset_path(ImageHelper::PLACEHOLDER_IMAGE_ASSET)
    }.merge!(**opt)
    <<~HEREDOC.squish.html_safe
      <script type="text/javascript">
        window.ASSET_OVERRIDES = #{js(asset_overrides)};
      </script>
    HEREDOC
  end

end

__loading_end(__FILE__)
