# app/helpers/layout_helper/page_modal.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper methods to support adding '.modal-popup' elements to the '<body>'
# element.
#
module LayoutHelper::PageModals

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Emit the page modals for inclusion in the '<body>' element definition.
  #
  # @return [ActiveSupport::SafeBuffer, nil]
  #
  def page_modals
    modals = page_modal.values
    safe_join(modals.flatten, "\n") if modals.present?
  end

  # Access the '.modal-popup' children of the '<body>' element.
  #
  # @return [Hash{String=>ActiveSupport::SafeBuffer}]
  #
  # @yield To supply CSS class(es) to #set_page_modal.
  # @yieldreturn [String, Array<String>]
  #
  def page_modal
    @page_modal ||= {}
  end

  # Indicate whether a modal has been defined for the given selector.
  #
  # @param [String] selector
  #
  # @note Currently unused.
  # :nocov:
  def page_modal?(selector)
    page_modal[selector].present?
  end
  # :nocov:

  # Add a modal definition associated with the given selector.  If a definition
  # already exists, the block will not be executed.
  #
  # @param [String]                         selector
  # @param [ActiveSupport::SafeBuffer, nil] definition
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @yield Supply the definition of the modal if *definition* is *nil*.
  # @yieldreturn [ActiveSupport::SafeBuffer]
  #
  def add_page_modal(selector, definition = nil)
    page_modal[selector] ||= definition || yield
  end

  # Remove the modal definition associated with the given selector.
  #
  # @param [String] selector
  #
  # @return [Boolean]                 True if the definition existed.
  #
  # @note Currently unused.
  # :nocov:
  def remove_page_modal(selector)
    page_modal.delete(selector).present?
  end
  # :nocov:

end

__loading_end(__FILE__)
