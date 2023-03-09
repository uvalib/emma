# app/models/upload/render_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods to support rendering Upload records.
#
module Upload::RenderMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # menu_label
  #
  # @param [Upload, nil] item         Default: self.
  #
  # @return [String, nil]
  #
  # @see BaseDecorator::Menu#items_menu_label
  #
  def menu_label(item = nil)
    item ||= self
    name   = item.submission_id.presence
    file   = item.filename.presence
    (name && file) ? "#{name} (#{file})" : (name || file)
  end

end

__loading_end(__FILE__)
