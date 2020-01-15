# app/helpers/file_format_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'search'

# File format display methods.
#
module FileFormatHelper

  def self.included(base)
    __included(base, '[FileFormatHelper]')
  end

  include HtmlHelper
  include FileNameHelper
  include DebugHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Separator between values of a multi-valued field.
  #
  # @type [String]
  #
  FF_SEPARATOR = FileFormat::FILE_FORMAT_SEP

  # Match format extensions at the end of a path name.
  #
  # @type [Regexp]
  #
  FORMAT_EXTENSION_RE = /\.(#{FORMAT_EXTENSIONS.join('|')})$/

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Display file metadata.
  #
  # @param [Search::Api::Record, Hash] info
  # @param [String] path              Overrides `info.emma_retrievalLink`.
  # @param [String] id                HTML ID of label element.
  # @param [Hash]   opt               Passed to #file_info_list.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]
  #
  # @see #file_info_values
  # @see #file_info_label
  # @see #file_info_list
  #
  def file_info(info, path: nil, id: nil, **opt)
    __debug_args(binding, "info = '#{info}'", except: :info)
    prop = nil
    if (item = info).is_a?(Search::Api::Record)
      path ||= item.record_download_url
      prop   = item.file_properties
    elsif info.is_a?(Hash)
      path ||= info[:path]
      prop   = opt.slice(:fmt).merge(info).except(:path)
    end
    prop   = extract_file_properties(path, prop)
    values = file_info_values(path, **prop)
    return if values.blank?

    id ||= file_identifier(prop) || "info-#{rand(1_000_000)}-#{prop.fmt}"
    opt[:id]  = ERB::Util.u(id)
    opt[:fmt] = prop.fmt
    label  = file_info_label(**opt.except(*GRID_OPTS))
    values = file_info_list(values, **opt)
    label << values
  end

  # Get metadata values.
  #
  # @param [String] path              URL or directory path to the file.
  # @param [Hash]   opt               Passed to RemoteFile#initialize.
  #
  # @return [Hash]
  # @return [nil]
  #
  # @see FileNameHelper#FF_CLASS
  #
  def file_info_values(path, **opt)
    __debug_args(binding)
    get_file(opt[:fmt], path, **opt)
      &.metadata
      &.transform_values { |v| v.is_a?(Array) ? v.map(&:to_s) : v.to_s }
  end

  # file_info_label
  #
  # @param [String] label             Override default label value.
  # @param [Symbol] fmt               File format type.
  # @param [String] id                HTML ID of label element.
  # @param [Hash]   opt               Passed to #content_tag.
  #
  # @option opt [String, Symbol] :fmt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def file_info_label(label: nil, fmt: nil, id: nil, **opt)
    label ||= "#{fmt&.to_s&.underscore&.humanize&.upcase || 'FILE'} INFO" # TODO: I18n
    opt = prepend_css_classes(opt, *fmt_css_classes('file-info-label', fmt))
    opt[:id] = id if id.present?
    content_tag(:div, label, opt)
  end

  # file_info_list
  #
  # @param [Hash]   info
  # @param [Symbol] fmt           File format type.
  # @param [String] id            HTML ID of label element.
  # @param [Hash]   opt           Passed to #content_tag except for #GRID_OPTS.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]
  #
  # @see HtmlHelper#grid_cell_classes
  #
  def file_info_list(info, fmt: nil, id: nil, **opt)
    __debug_args(binding)
    return unless info.present? && info.is_a?(Hash)
    opt, html_opt = partition_options(opt, *GRID_OPTS)
    prepend_css_classes!(html_opt, *fmt_css_classes('file-info', fmt))
    html_opt[:'aria-labelledby'] ||= id if id.present?
    content_tag(:div, html_opt) do
      opt[:row] = 0
      info.map { |label, value|
        opt[:row] += 1
        # noinspection RubyYardParamTypeMatch
        file_info_list_entry(label, value, **opt)
      }.join("\n").html_safe
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # A single file info list entry.
  #
  # @param [String] label
  # @param [*]      value
  # @param [Hash]   opt               #GRID_OPTS.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see HtmlHelper#grid_cell_classes
  #
  def file_info_list_entry(label, value, **opt)
    field = label.to_s.gsub(/\s+|s$/, '').to_sym
    l_opt = { class: "label field-#{field}" }
    v_opt = { class: "value field-#{field}" }
    append_grid_cell_classes!(l_opt, **opt.merge!(col: 1))
    append_grid_cell_classes!(v_opt, **opt.merge!(col: 2))

    if field == :CoverImage
      append_css_classes!(l_opt, 'logo')
      append_css_classes!(v_opt, 'logo')
      value = Array.wrap(value).map { |v| image_tag(v) }

    elsif value.is_a?(Array)
      append_css_classes!(v_opt, 'array')
      value = value.map { |v| content_tag(:div, v) }

    elsif (value = value.to_s).include?(FF_SEPARATOR)
      value = value.split(FF_SEPARATOR).map { |v| content_tag(:li, v) }
      value = content_tag(:ul, safe_join(value))

    end
    value = safe_join(value) if value.is_a?(Array)
    content_tag(:div, label, l_opt) << content_tag(:div, value, v_opt)
  end

  # Create an HTML identifier from a search record.
  #
  # @param [Search::Api::Record, FileProperties, Hash] item
  #
  # @return [String]
  #
  def file_identifier(item)
    __debug_args(binding)
    prop = item.is_a?(Search::Api::Record) ? item.file_properties : item
    FileObject.make_file_name(prop).sub(FORMAT_EXTENSION_RE, '')
  end

  # Break symbol format names into CSS class names.  (E.g. :daisy -> 'daisy')
  # Names which are already strings are passed through unaffected.
  #
  # @param [Array<String,Symbol,Array<String,Symbol>>] names
  #
  # @return [Array<String>]
  #
  # @example :daisy
  #   => %w(daisy)
  #
  # @example :daisyAudio
  #   => %w(daisy audio)
  #
  def fmt_css_classes(*names)
    names.flatten.flat_map { |v|
      v.is_a?(Symbol) ? v.to_s.underscore.split('_') : v
    }.reject(&:blank?).uniq
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Create an instance of the indicated file format type.
  #
  # @param [Symbol, String, nil] fmt
  # @param [String]              path
  # @param [Boolean]             fetch  Require the contents of the file.
  # @param [Hash]                opt    Passed to class initializer.
  #
  # @return [RemoteFile]
  # @return [nil]
  #
  def get_file(fmt, path, fetch: true, **opt)
    fmt ||= opt[:fmt]
    fmt &&= fmt.to_sym
    FileNameHelper::FF_CLASS[fmt]&.new(path, fetch: fetch, **opt)
  end

end

__loading_end(__FILE__)
