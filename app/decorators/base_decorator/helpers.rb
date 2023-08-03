# app/decorators/base_decorator/helpers.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Definitions to support inclusion of helpers.
#
# === Implementation Notes
# This approach avoids `include Draper::LazyHelpers` because this can make it
# difficult to pin down where problems with the use of Draper::ViewContext
# originate when including /app/helpers/**.
#
module BaseDecorator::Helpers

  include Draper::ViewHelpers

  include BaseDecorator::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Explicit overrides for the sake of those helpers which still rely on direct
  # access to controller-related items.
  #
  # @!method cookies
  # @!method params
  # @!method request
  # @!method session
  # @!method current_ability
  # @!method current_user
  #
  CONTROLLER_METHODS = %i[
    cookies
    params
    request
    session
    current_user
    current_ability
  ].freeze

  CONTROLLER_METHODS.each do |meth|
    define_method(meth) do
      controller_context.send(meth)
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Direct access to the controller.
  #
  # @return [ApplicationController]
  #
  # === Implementation Notes
  # This probably isn't "cricket" but app/helpers/**.rb generally expect access
  # to controller values, and while the decorator subclasses are relying on
  # including these helpers, there is a need to access these values directly.
  #
  # While you *can* access these from Draper::ViewContext#current (via
  # Draper::ViewHelpers#helpers [i.e., prefixing with "h."] or via
  # Draper::LazyHelpers#method_missing), the values don't seem to be coming
  # back correctly.
  #
  def controller_context
    Draper::ViewContext.controller
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Helper methods explicitly generated for the sake of avoiding LazyHelpers.
  #
  # @!method asset_path(*args)
  #   @see ActionView::Helpers::AssetUrlHelper#asset_path
  #
  # @!method safe_join(*args)
  #   @see ActionView::Helpers::OutputSafetyHelper#safe_join
  #
  HELPER_METHODS = %i[asset_path safe_join].freeze

  HELPER_METHODS.each do |meth|
    define_method(meth) do |*args|
      helpers.send(meth, *args)
    end
    ruby2_keywords(meth)
  end

  # Helper methods explicitly generated for the sake of avoiding LazyHelpers.
  #
  # @!method button_tag(*args, &block)
  #   @see ActionView::Helpers::FormTagHelper#button_tag
  #
  # @!method content_tag(*args, &block)
  #   @see ActionView::Helpers::TagHelper#content_tag
  #
  # @!method form_tag(*args, &block)
  #   @see ActionView::Helpers::FormTagHelper#form_tag
  #
  # @!method image_tag(*args, &block)
  #   @see ActionView::Helpers::AssetTagHelper#image_tag
  #
  # @!method link_to(*args, &block)
  #   @see ActionView::Helpers::UrlHelper#link_to
  #
  # @!method submit_tag(*args, &block)
  #   @see ActionView::Helpers::FormTagHelper#submit_tag
  #
  VIEW_HELPER_METHODS = %i[
    button_tag
    content_tag
    form_tag
    image_tag
    link_to
    submit_tag
  ].freeze

  VIEW_HELPER_METHODS.each do |meth|
    define_method(meth) do |*args, &block|
      helpers.send(meth, *args, &block)
    end
    ruby2_keywords(meth)
  end

  # Defined here for the sake of RepositoryHelper.
  #
  def retrieval_path(*args)
    h.retrieval_path(*args)
  end

  # @private
  FORM_WITH_OPTIONS = %i[
    allow_method_names_outside_object
    authenticity_token
    builder
    class
    data
    id
    index
    local
    method
    multipart
    namespace
    remote
    skip_default_ids
  ].freeze

  # Due to #html_options_for_form_with only certain #form_with options are
  # actually passed on to the <form> element.
  #
  # Data attributes of the form `opt['data-xxx']` are expected to be passed as
  # `opt[:data][:xxx]`, and HTML element options are expected to be passed via
  # `opt[:html]`.
  #
  # This shim coalesces 'data-xxx' options into opt[:data], and other non-form
  # options into opt[:html], creating either as needed.
  #
  # @param [Model, nil]           model
  # @param [Symbol, String, nil]  scope
  # @param [String, Hash, nil]    url
  # @param [Symbol, String, nil]  format
  # @param [Hash]                 opt
  #
  # @option opt [Hash] :html
  # @option opt [Hash] :data
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @yield form
  # @yieldparam [ActionView::Helpers::FormBuilder] form
  # @yieldreturn ActiveSupport::SafeBuffer
  #
  def form_with(model: nil, scope: nil, url: nil, format: nil, **opt, &block)
    if (data_opt = opt.select { |k, _| k.start_with?('data-') }).present?
      opt.except!(*data_opt.keys)
      data_opt.transform_keys! { |k| k.to_s.delete_prefix('data-').to_sym }
      opt[:data] = opt[:data]&.merge(data_opt) || data_opt
    end
    if (html_opt = remainder_hash!(opt, *FORM_WITH_OPTIONS)).present?
      opt[:html] = opt[:html]&.merge(html_opt) || html_opt
    end
    opt.merge!(model: model, scope: scope, url: url, format: format)
    h.form_with(**opt, &block)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  include ConfigurationHelper
  include FormHelper
  include HtmlHelper
  include IdentityHelper
  include ImageHelper
  include LinkHelper
  include PanelHelper
  include PopupHelper
  include RepositoryHelper
  include ScrollHelper
  include SearchModesHelper
  include SessionDebugHelper
  include TreeHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    __included(base, self)
  end

end

__loading_end(__FILE__)
