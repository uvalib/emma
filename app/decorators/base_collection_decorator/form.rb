# app/decorators/base_collection_decorator/form.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods supporting the deletion of Model instances.
#
module BaseCollectionDecorator::Form

  include BaseDecorator::Form

  include BaseCollectionDecorator::Common

  # ===========================================================================
  # :section: Item forms (delete pages)
  # ===========================================================================

  public

  # Generate a form with controls for deleting a model instance.
  #
  # @param [String] label             Label for the submit button.
  # @param [Hash]   outer             HTML options for outer div container.
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt               Passed to '.model-form.delete' except:
  #
  # @option opt [String] :cancel      Cancel button redirect URL passed to
  #                                     #delete_cancel_button.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def delete_form(label: nil, outer: nil, css: '.model-form.delete', **opt)
    trace_attrs!(opt, __method__)
    t_opt     = trace_attrs_from(opt)
    inner_opt = opt.slice!(:cancel, *delete_submit_option_keys)

    cancel    = delete_cancel_button(url: opt[:cancel], **t_opt)
    submit    = delete_submit_button(label: label, **opt, **t_opt)

    outer_css = '.form-container.delete'
    outer_opt = outer&.merge(t_opt) || t_opt
    prepend_css!(outer_opt, outer_css, model_type)
    html_div(**outer_opt) do
      prepend_css!(inner_opt, css, model_type)
      html_div(**inner_opt) do
        submit << cancel
      end
    end
  end

  # delete_submit_option_keys
  #
  # @return [Array<Symbol>]
  #
  def delete_submit_option_keys
    []
  end

  # delete_submit_options
  #
  # @param [Hash] opt                 Optional option value overrides.
  #
  # @return [Hash]
  #
  def delete_submit_options(**opt)
    keys = delete_submit_option_keys
    opt.slice!(*keys)
    opt.merge!(options.slice(*keys)) if (keys -= opt.keys).present?
    opt
  end

  # delete_submit_path
  #
  # @param [Array<Model,String>, Model, String, nil] ids
  # @param [Hash]                                    opt
  #
  # @return [String, nil]
  #
  def delete_submit_path(ids = nil, **opt)
    ids = item_ids(ids, **opt).join(',')
    destroy_path(id: ids, **opt) if ids.present?
  end

  # Submit button for the delete model form.
  #
  # @param [String, Symbol, nil] action
  # @param [String, nil]         label    Override button label.
  # @param [String, Hash, nil]   url
  # @param [String]              css      Characteristic CSS class/selector.
  # @param [Hash]                opt      Passed to #button_to.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def delete_submit_button(
    action: nil,
    label:  nil,
    url:    nil,
    css:    '.submit-button',
    **opt
  )
    path_opt       = opt.extract!(*delete_submit_option_keys)
    url          ||= delete_submit_path(**path_opt)
    if_enabled     = (:if_enabled if url)
    action         = action&.to_sym || :delete
    # noinspection RubyMismatchedArgumentType
    config         = form_actions.dig(action, :submit) || {}
    label        ||= config[:label]
    opt[:title]  ||= config.dig((if_enabled || :if_disabled), :tooltip)
    opt[:role]   ||= 'button'
    opt[:method] ||= :delete
    trace_attrs!(opt, __method__)
    append_css!(opt, (if_enabled ? 'best-choice' : 'forbidden'))
    prepend_css!(opt, css)
    h.button_to(label, url, opt)
  end

  # Cancel button for the delete form.
  #
  # @param [Hash] opt                 Passed to #cancel_button
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def delete_cancel_button(**opt)
    opt[:action] ||= :delete
    trace_attrs!(opt, __method__)
    cancel_button(**opt)
  end

  # ===========================================================================
  # :section: Item forms (delete pages)
  # ===========================================================================

  protected

  # item_ids
  #
  # @param [Array<Model,String>, Model, String, nil] items  Def: `#object`.
  #
  # @return [Array<String>]
  #
  def item_ids(items = nil, **)
    items   = Array.wrap(items).presence
    items &&= items.map { positive(_1) || _1.try(:id) || _1.try(:[], :id) }
    items ||= object.map(&:id)
    items.compact.map(&:to_s).uniq
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
