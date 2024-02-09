# app/helpers/aws_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper methods supporting access and linkages to AWS S3.
#
# @see file:app/assets/stylesheets/feature/_aws.scss
#
module AwsHelper

  include Emma::Unicode

  include HtmlHelper
  include LinkHelper
  include ParamsHelper
  include SerializationHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  S3_EMPTY_BUCKET  = config_text(:aws, :bucket, :empty).freeze
  S3_PREFIX_LIMIT  = 10
  S3_OBJECT_VALUES = %i[key size last_modified].freeze

  AWS_CONSOLE_URL  = 'https://console.aws.amazon.com'
  AWS_BUCKET_URL   = "#{AWS_CONSOLE_URL}/s3/buckets"

  AWS_SORT_OPT     = %i[sort].freeze
  AWS_FILTER_OPT   = %i[after before prefix prefix_limit].freeze
  AWS_RENDER_OPT   = %i[heading html object].freeze

  # noinspection RubyMismatchedConstantType
  S3_BUCKET_DEFAULT_SORT = I18n.t('emma.upload.search_filters.sort.default')
  S3_BUCKET_PRIMARY_SORT = :prefix

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Return the AWS console URL for a given AWS S3 bucket.
  #
  # @param [String, Aws::S3::Bucket] bucket
  # @param [String, nil]             region   Default: `#AWS_REGION`
  #
  # @return [String]
  #
  def s3_bucket_url(bucket, region: nil)
    bucket   = bucket.name if bucket.is_a?(Aws::S3::Bucket)
    region ||= AWS_REGION
    make_path(AWS_BUCKET_URL, bucket, region: region)
  end

  # Generate an HTML link to display the AWS console for a given AWS S3 bucket
  # in a new browser tab.
  #
  # @param [String, Aws::S3::Bucket] bucket
  # @param [String]                  css      Characteristic CSS class/selector
  # @param [Hash]                    opt      Passed to #external_link
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def s3_bucket_link(bucket, css: '.aws-link', **opt)
    label  = opt.delete(:label) || config_text(:aws, :bucket, :label)
    region = opt.delete(:region)
    url    = s3_bucket_url(bucket, region: region)
    prepend_css!(opt, css)
    opt[:title] ||= 'Go to the AWS S3 console page for this bucket'
    external_link(label, url, **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Render a table of S3 buckets and objects as HTML.
  #
  # @param [Hash{String=>Array<Aws::S3::Object>}] table
  # @param [Hash]                                 opt     To #render_s3_bucket
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def html_s3_bucket_table(table, **opt)
    opt.except!(:erb, :html)
    bucket_opt = opt.slice!(*AWS_RENDER_OPT).presence || s3_bucket_params
    bucket_opt.merge!(opt)
    table.map { |bucket, objects|
      render_s3_bucket(bucket, objects, **bucket_opt)
    }.join("\n").html_safe
  end

  # Render a table of S3 buckets and objects as JSON.
  #
  # @param [Hash{String=>Array<Aws::S3::Object>}] table
  # @param [Hash]                                 opt     To #render_s3_bucket
  #                                                         except:
  #
  # @option opt [Boolean] :erb            If *true*, prepare for use within an
  #                                         ERB template.
  #
  # @return [ActiveSupport::SafeBuffer]   If :erb is *true*.
  # @return [String]                      Otherwise.
  #
  def json_s3_bucket_table(table, **opt)
    for_erb    = opt.delete(:erb)
    bucket_opt = opt.slice!(*AWS_RENDER_OPT).presence || s3_bucket_params
    bucket_opt.merge!(opt).merge!(html: false)
    result =
      table.map { |bucket, objects|
        [bucket, render_s3_bucket(bucket, objects, **bucket_opt)]
      }.to_h.to_json
    for_erb ? result.delete_prefix('{').delete_suffix('}').html_safe : result
  end

  # Render a table of S3 buckets and objects as JSON.
  #
  # @param [Hash{String=>Array<Aws::S3::Object>}] table
  # @param [Hash]                                 opt     To #render_s3_bucket
  #                                                         except:
  #
  # @option opt [Boolean] :erb            If *true*, prepare for use within an
  #                                         ERB template.
  #
  # @return [ActiveSupport::SafeBuffer]   If :erb is *true*.
  # @return [String]                      Otherwise.
  #
  def xml_s3_bucket_table(table, **opt)
    serializer = opt.delete(:serializer) || AwsS3::Api::Serializer::Xml.new
    xml_opt    = { serializer: serializer }
    for_erb    = opt.delete(:erb)
    bucket_opt = opt.slice!(*AWS_RENDER_OPT).presence || s3_bucket_params
    bucket_opt.merge!(opt).merge!(html: false)
    result =
      table.map do |bucket, objects|
        html_tag(:bucket, name: bucket) do
          render_s3_bucket(bucket, objects, **bucket_opt).map do |object|
            html_tag(:object, name: object[:key]) do
              make_xml(object, **xml_opt).html_safe
            end
          end
        end
      end
    for_erb ? safe_join(result, "\n") : result.join("\n")
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # URL parameters which modify the behavior of #render_s3_bucket.
  #
  # @param [Hash, nil] opt            Default: `#url_parameters`.
  #
  # @return [Hash]
  #
  def s3_bucket_params(opt = nil)
    (opt || url_parameters).slice(*AWS_SORT_OPT, *AWS_FILTER_OPT)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  AWS_BUCKET_OPT = (AWS_SORT_OPT + AWS_FILTER_OPT + AWS_RENDER_OPT).freeze

  # Show the contents of an S3 bucket.
  #
  # @param [String, Aws::S3::Bucket, nil] bucket
  # @param [Array<Aws::S3::Object>]       objects
  # @param [String]                       css       Characteristic CSS class.
  # @param [Hash]                         opt       Passed to #html_div except:
  #
  # @option opt [Date, DateTime]   :after           Date range minimum.
  # @option opt [Date, DateTime]   :before          Date range maximum.
  # @option opt [String, Regexp]   :prefix          Only matching objects.
  # @option opt [Integer, Boolean] :prefix_limit    Max shown per prefix; if
  #                                                   *false*, no limit if nil
  #                                                   or *true*, the default
  #                                                   #S3_PREFIX_LIMIT is used.
  # @option opt [Hash]             :object          Passed to #render_s3_object
  # @option opt [Boolean]          :html            Default: *true*.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [Array<Hash>]                           If *html* is *false*.
  #
  #--
  # noinspection RubyMismatchedArgumentType
  #++
  def render_s3_bucket(bucket, objects, css: '.aws-bucket', **opt)
    local  = opt.extract!(*AWS_BUCKET_OPT)
    after  = local[:after].try(:to_datetime)
    before = local[:before].try(:to_datetime)
    prefix = local[:prefix]&.to_s
    prefix = "#{prefix}/" if prefix && !prefix.end_with?('/')
    limit  = local[:prefix_limit]
    limit  = S3_PREFIX_LIMIT if limit.nil? || limit.is_a?(TrueClass)
    limit  = positive(limit)
    html   = !false?(local[:html])
    o_opt  = (local[:object] || {}).merge(html: html)

    # Transform object instances into value hashes and eliminate non-matches.
    objects.map! { |obj|
      obj = s3_object_values(obj)
      p, date = obj.values_at(:prefix, :last_modified)
      next if prefix && (p != prefix)
      next if after  && (date.nil? || (date < after))
      next if before && (date.nil? || (date > before))
      obj
    }.compact!

    # Transform the object instances into a sorted array of value hashes.
    sort_objects!(objects, local[:sort])

    # Render each object as HTML.
    total = limit ? objects.map { |obj| obj[:prefix] }.tally : {}
    prev  = nil
    row   = 0
    objects.map! { |obj|
      p     = obj[:prefix]
      start = ((p != prev) if prev)
      prev  = p || ''
      row   = start ? 0 : row.succ
      if limit && (row > limit)
        more = (row == limit.succ) ? (total[p] - row + 1) : 0
        next unless more.positive?
        more = config_text(:aws, :bucket, :more, count: more)
        more = link_to(more, '#') if html # TODO: JavaScript
        obj  = { prefix: more }
      end
      render_s3_object_row(obj, section: start, row: row, **o_opt)
    }.compact!

    # Produce a placeholder if no objects are present at this point.
    if objects.blank?
      label =
        case
          when after && before then "NONE BETWEEN #{after} and #{before}"
          when after           then "NONE AFTER #{after}"
          when before          then "NONE BEFORE #{before}"
        end
      objects << render_s3_object_placeholder(label: label, html: html)
    end

    # Return the hashes themselves if not rendering HTML.
    # noinspection RubyMismatchedReturnType
    return objects unless html

    # Generate a heading if a bucket (name) was provided.
    parts = []
    title = local[:heading]
    if title || bucket
      name  = bucket.is_a?(Aws::S3::Bucket) ? bucket.name : bucket
      title = name if title.blank?
      skip_nav_append(title => name)
      title = html_span(title) << s3_bucket_link(name)
      parts << html_h3(title, class: 'aws-bucket-hdg', id: "##{name}")
    end

    # Generate the table of objects with column headings.
    column_headings = render_s3_object_headings(**o_opt)
    prepend_css!(opt, css)
    parts << html_div(column_headings, *objects, **opt)

    safe_join(parts, "\n")
  end

  # Show column headings for an S3 object.
  #
  # @param [String] css                       Characteristic CSS class/selector
  # @param [Hash]   opt                       Passed to #render_s3_object
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [Hash]                            If *html* is *false*.
  #
  def render_s3_object_headings(css: '.column-headings', **opt)
    headings = s3_object_values(nil)
    prepend_css!(opt, css)
    render_s3_object(headings, **opt)
  end

  # Show an S3 object table row.
  #
  # @param [Aws::S3::Object, Hash] obj
  # @param [String]                css        Characteristic CSS class/selector
  # @param [Hash]                  opt        Passed to #render_s3_object
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [Hash]                            If *html* is *false*.
  #
  def render_s3_object_row(obj, css: '.row', **opt)
    prepend_css!(opt, css)
    render_s3_object(obj, **opt)
  end

  # Show the contents of an S3 object.
  #
  # @param [Aws::S3::Object, Hash] obj
  # @param [String]                css        Characteristic CSS class/selector
  # @param [Hash]                  opt        Passed to #html_div except for:
  #
  # @option opt [Boolean] :section            Start of a new section.
  # @option opt [Integer] :row                Row counter for this object.
  # @option opt [Hash]    :column             Passed to inner #html_div.
  # @option opt [Boolean] :html               Default: *true*.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [Hash]                            If *html* is *false*.
  #
  def render_s3_object(obj, css: '.aws-object', **opt)
    section = opt.delete(:section)
    row     = opt.delete(:row)
    col_opt = opt.delete(:column)
    html    = !false?(opt.delete(:html))
    values  = obj.is_a?(Hash) ? obj.dup : s3_object_values(obj)

    # If not rendering HTML then just return with the column values.
    # noinspection RubyMismatchedReturnType
    return values unless html

    # Render each column value.
    prefix  = values[:prefix].presence
    key     = values[:key]&.delete_prefix(prefix.to_s)&.presence
    entries =
      values.map do |k, v|
        value_opt = prepend_css(col_opt, k)
        value_opt.merge!('data-value': v) unless k == :placeholder
        value = (k == :key) ? key : value_format(v, k)
        unless value == v
          tooltip = value_format(v)
          tooltip = "#{tooltip} bytes" if k == :size
          value_opt[:title] = tooltip
        end
        value = EN_DASH if value.blank?
        html_div(value, **value_opt)
      end

    # Render an element containing the column values.
    opt.except!(:object)
    prepend_css!(opt, css)
    append_css!(opt, 'first-prefix') if section
    opt[:'data-row'] = row           if row
    html_div(entries, **opt)
  end

  # Show an S3 object placeholder indicating an empty S3 bucket.
  #
  # @param [String, nil] label
  # @param [Boolean]     html         Default: *true*
  # @param [Hash]        opt          For *label*.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [Hash]                        If *html* is *false*.
  #
  def render_s3_object_placeholder(label: nil, html: nil, **opt)
    html  = !false?(html)
    unless label.is_a?(ActiveSupport::SafeBuffer)
      label = html_bold(**opt) { html_italic(label || S3_EMPTY_BUCKET) }
    end
    entry = { placeholder: label }
    render_s3_object(entry, html: html)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Extract values from an S3 object.
  #
  # @param [Aws::S3::Object, Hash, nil] obj
  # @param [Array<Symbol>]              methods
  #
  # @return [Hash]
  #
  def s3_object_values(obj, methods = S3_OBJECT_VALUES)
    value_hash(obj, methods)
  end

  # Extract values from an item.
  #
  # @param [any, nil]      item
  # @param [Array<Symbol>] methods
  #
  # @return [Hash]
  #
  def value_hash(item, methods)
    if item.is_a?(Hash)
      item.dup
    elsif item.nil?
      methods.map { |m| [m, m.to_s.titleize] }.to_h
    else
      methods.map { |m| [m, item.send(m)] if item.respond_to?(m) }.compact.to_h
    end.tap do |result|
      key = result[:key] || result[:object_key]
      if key.present? && result[:prefix].blank?
        result[:prefix] = item ? prefix_of(key) : config_text(:aws, :prefix)
      end
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  NUM_SIZE_OPT = { precision: 1, significant: false, delimiter: ',' }.freeze

  # Format a value for display.
  #
  # @param [any, nil]    item
  # @param [Symbol, nil] hint
  #
  # @return [any, nil]
  #
  def value_format(item, hint = nil)
    if item.is_a?(Array)
      item.map { |v| send(__method__, v, hint) }.join(', ')
    elsif item.is_a?(Integer) && (hint == :size)
      number_to_human_size(item, **NUM_SIZE_OPT)
    elsif item.is_a?(Integer)
      number_with_delimiter(item)
    elsif item.respond_to?(:getlocal) && hint
      item.getlocal.strftime('%Y-%b-%d %H:%M:%S %Z')
    elsif item.is_a?(BoolType)
      item.to_s
    else
      item
    end
  end

  # Return the prefix of the given object key.
  #
  # @param [String] key
  #
  # @return [String]
  #
  def prefix_of(key)
    key = key.to_s
    if key.end_with?('/')
      key
    elsif key.include?('/')
      key.split('/').tap { |a| a[-1] = nil }.join('/')
    else
      ''
    end
  end

  # Sort an array of hashes based on the sort keys and their direction (forward
  # sort if *true*; reverse sort if *false).
  #
  # @param [Array<Hash>]                                 array
  # @param [Array<Symbol>, Hash{Symbol=>String,Boolean}] sort_keys
  #
  # @return [Array<Hash>]
  #
  #--
  # noinspection RubyMismatchedArgumentType, RubyMismatchedReturnType
  #++
  def sort_objects!(array, sort_keys = nil)
    primary_sort   = transform_sort_keys(S3_BUCKET_PRIMARY_SORT)
    secondary_sort = transform_sort_keys(sort_keys || S3_BUCKET_DEFAULT_SORT)
    sort_keys      = primary_sort.merge(secondary_sort)
    array.sort! do |a, b|
      sort_keys.find do |key, ascending|
        comparison = ascending ? (a[key] <=> b[key]) : (b[key] <=> a[key])
        break comparison if comparison&.nonzero?
      end || 0
    end
  end

  # Normalize sort keys.
  #
  # @param [Symbol, Array<Symbol>, Hash{Symbol=>String,Boolean}] sort_keys
  #
  # @return [Hash{Symbol=>Boolean}]
  #
  def transform_sort_keys(sort_keys)
    SortOrder.wrap(sort_keys).transform_values { |dir| dir == :asc }
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
