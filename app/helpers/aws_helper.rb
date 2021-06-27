# app/helpers/aws_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper methods supporting access and linkages to AWS S3.
#
module AwsHelper

  # @private
  def self.included(base)
    __included(base, 'AwsHelper')
  end

  include HtmlHelper
  include LayoutHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  S3_EMPTY_BUCKET  = 'EMPTY' # TODO: I18n
  S3_PREFIX_LIMIT  = 10
  S3_OBJECT_VALUES = %i[key size last_modified].freeze

  AWS_CONSOLE_URL  = 'https://console.aws.amazon.com'
  AWS_BUCKET_URL   = "#{AWS_CONSOLE_URL}/s3/buckets"

  AWS_SORT_OPT     = %i[sort sortOrder direction].freeze
  AWS_FILTER_OPT   = %i[after before prefix prefix_limit].freeze
  AWS_RENDER_OPT   = %i[heading html object].freeze

  S3_BUCKET_PRIMARY_SORT = :prefix
  S3_BUCKET_DEFAULT_SORT = I18n.t('emma.upload.search_filters.sort.default')

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
  # @param [Hash]                    opt      Passed to #external_link
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def s3_bucket_link(bucket, **opt)
    css_selector  = '.aws-link'
    label         = opt.delete(:label) || 'AWS' # TODO: I18n
    region        = opt.delete(:region)
    url           = s3_bucket_url(bucket, region: region)
    opt[:title] ||= 'Go to the AWS S3 console page for this bucket'
    external_link(label, url, **prepend_classes!(opt, css_selector))
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
    opt, render_opt = partition_hash(opt, :erb, *AWS_RENDER_OPT)
    opt.except!(:erb, :html)
    render_opt = s3_bucket_params if render_opt.blank?
    render_opt.merge!(opt)
    table.map { |bucket, objects|
      render_s3_bucket(bucket, objects, **render_opt)
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
    opt, render_opt = partition_hash(opt, :erb, *AWS_RENDER_OPT)
    for_erb    = opt.delete(:erb)
    render_opt = s3_bucket_params if render_opt.blank?
    render_opt.merge!(opt).merge!(html: false)
    result =
      table.map { |bucket, objects|
        [bucket, render_s3_bucket(bucket, objects, **render_opt)]
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
    opt, render_opt = partition_hash(opt, :erb, *AWS_RENDER_OPT)
    for_erb    = opt.delete(:erb)
    render_opt = s3_bucket_params if render_opt.blank?
    render_opt.merge!(opt).merge!(html: false)
    result =
      table.map do |bucket, objects|
        html_tag(:bucket, name: bucket) do
          render_s3_bucket(bucket, objects, **render_opt).map do |object|
            html_tag(:object, name: object[:key]) do
              make_xml(object).html_safe
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
  def render_s3_bucket(bucket, objects, **opt)
    css_selector  = '.aws-bucket'
    opt, html_opt = partition_hash(opt, *AWS_BUCKET_OPT)
    after   = opt[:after]&.to_datetime
    before  = opt[:before]&.to_datetime
    prefix  = opt[:prefix]&.to_s
    prefix  = "#{prefix}/" if prefix && !prefix.end_with?('/')
    limit   = opt[:prefix_limit]&.to_i
    limit   = S3_PREFIX_LIMIT if limit.nil? || limit.is_a?(TrueClass)
    limit   = nil if limit.is_a?(Numeric) && limit.negative?
    title   = opt[:heading]
    html    = !false?(opt[:html])
    obj_opt = (opt[:object] || {}).merge(html: html)
    parts   = []

    # Generate a heading if a bucket (name) was provided.
    if html && (title || bucket)
      # noinspection RubyNilAnalysis
      name    = bucket.is_a?(Aws::S3::Bucket) ? bucket.name : bucket
      title ||= name
      parts <<
        html_tag(:h3, class: 'aws-bucket-hdg', id: "##{name}") do
          # noinspection RubyYardParamTypeMatch
          html_span(title) << s3_bucket_link(name)
        end
      skip_nav_append(title => name)
    end

    # Transform object instances into value hashes and eliminate non-matches.
    objects.map! { |obj| s3_object_values(obj) }
    objects.reject! do |obj|
      m = obj[:last_modified]
      (m.nil? || (m < after)  if after)  ||
      (m.nil? || (m > before) if before) ||
      (obj[:prefix] != prefix if prefix)
    end
    objects.compact!

    # Transform the object instances into a sorted array of value hashes.
    # noinspection RubyYardParamTypeMatch
    if opt[:sortOrder] || opt[:direction]
      sort_order = opt[:sortOrder] || opt[:sort]
      direction  = opt[:direction] || is_reverse?(sort_order)
      sort_objects!(objects, sort_order => direction)
    else
      sort_objects!(objects, opt[:sort])
    end

    # Prepare for per-prefix limits.
    total = {}
    if limit
      objects.each do |obj|
        p = obj[:prefix]
        total[p] = total[p].to_i + 1
      end
    end

    # Render each object as HTML.
    prev    = nil
    count   = 0
    objects.map! do |obj|
      start = ((obj[:prefix] != prev) if prev)
      prev  = obj[:prefix] || ''
      count = 0 if start
      count += 1
      if limit && (count > limit)
        more = (count == (limit + 1)) ? (total[obj[:prefix]] - count + 1) : 0
        next unless more.positive?
        more = "[#{more} more]" # TODO: I18n
        more = link_to(more, '#') if html # TODO: JavaScript
        obj  = { prefix: more }
      end
      render_s3_object_row(obj, section: start, row: count, **obj_opt)
    end
    objects.compact!

    # Produce a placeholder if no objects are present at this point.
    if objects.blank?
      after  &&= after.to_date
      before &&= before.to_date
      label =
        if after && before
          "NONE BETWEEN #{after} and #{before}"
        elsif after
          "NONE AFTER #{after}"
        elsif before
          "NONE BEFORE #{before}"
        end
      objects << render_s3_object_placeholder(label: label, html: html)
    end

    # Return the hashes themselves if not rendering HTML.
    # noinspection RubyYardReturnMatch
    return objects unless html

    # Prepend column headings.
    column_headings = render_s3_object_headings(**obj_opt)
    objects.unshift(column_headings)

    # Generate the table of objects.
    parts << html_div(objects, prepend_classes!(html_opt, css_selector))

    safe_join(parts, "\n")
  end

  # Show column headings for an S3 object.
  #
  # @param [Hash] opt                         Passed to #render_s3_object
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [Hash]                            If *html* is *false*.
  #
  def render_s3_object_headings(**opt)
    css_selector = '.column-headings'
    headings     = s3_object_values(nil)
    render_s3_object(headings, **prepend_classes!(opt, css_selector))
  end

  # Show an S3 object table row.
  #
  # @param [Hash] opt                         Passed to #render_s3_object
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [Hash]                            If *html* is *false*.
  #
  def render_s3_object_row(obj, **opt)
    css_selector = '.row'
    render_s3_object(obj, **prepend_classes!(opt, css_selector))
  end

  # Show the contents of an S3 object.
  #
  # @param [Aws::S3::Object, Hash] obj
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
  def render_s3_object(obj, **opt)
    css_selector = '.aws-object'
    section = opt.delete(:section)
    row     = opt.delete(:row)
    col_opt = opt.delete(:column)
    html    = !false?(opt.delete(:html))
    values  = obj.is_a?(Hash) ? obj.dup : s3_object_values(obj)

    # If not rendering HTML then just return with the column values.
    # noinspection RubyYardReturnMatch
    return values unless html

    # Render each column value.
    prefix  = values[:prefix].presence
    key     = values[:key]&.delete_prefix(prefix.to_s)&.presence
    entries =
      values.map do |k, v|
        value_opt = prepend_classes(col_opt, k)
        value_opt.merge!('data-value': v) unless k == :placeholder
        # noinspection RubyYardParamTypeMatch
        value = (k == :key) ? key : value_format(v, k)
        unless value == v
          tooltip = value_format(v)
          tooltip = "#{tooltip} bytes" if k == :size
          value_opt[:title] = tooltip
        end
        value = EN_DASH if value.blank?
        html_div(value, value_opt)
      end

    # Render an element containing the column values.
    opt.except!(:object)
    prepend_classes!(opt, css_selector)
    append_classes!(opt, 'first-prefix') if section
    opt[:'data-row'] = row               if row
    html_div(entries, opt)
  end

  # Show an S3 object placeholder indicating an empty S3 bucket.
  #
  # @param [String, ActiveSupport::SafeBuffer, nil] label
  # @param [Boolean]                                html    Default: *true*
  # @param [Hash]                                   opt     For *label*.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [Hash]                        If *html* is *false*.
  #
  def render_s3_object_placeholder(label: nil, html: nil, **opt)
    html    = !false?(html)
    label ||= S3_EMPTY_BUCKET
    if html && !label.is_a?(ActiveSupport::SafeBuffer)
      label = html_tag(:strong, label)
      label = html_tag(:em, label, opt)
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
  # @param [*, Hash, nil]  item
  # @param [Array<Symbol>] methods
  #
  # @return [Hash]
  #
  def value_hash(item, methods)
    result =
      (item.dup if item.is_a?(Hash)) ||
      (methods.map { |m| [m, m.to_s.titleize] } if item.nil?) ||
      (methods.map { |m| [m, item.send(m)] if item.respond_to?(m) })
    result = result.compact.to_h if result.is_a?(Array)
    key    = result[:key] || result[:object_key]
    if key.present? && result[:prefix].blank?
      prefix = item ? prefix_of(key) : 'Prefix' # TODO: I18n
      result = { prefix: prefix }.merge!(result)
    end
    # noinspection RubyYardReturnMatch
    result
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  NUM_SIZE_OPT = { precision: 1, significant: false, delimiter: ',' }.freeze

  # Format a value for display.
  #
  # @param [*]           item
  # @param [Symbol, nil] hint
  #
  # @return [*]
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
    elsif item.is_a?(TrueClass) || item.is_a?(FalseClass)
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
  def sort_objects!(array, sort_keys = nil)
    primary_sort = transform_sort_keys(S3_BUCKET_PRIMARY_SORT)
    sort_keys    = transform_sort_keys(sort_keys || S3_BUCKET_DEFAULT_SORT)
    sort_keys    = primary_sort.merge(sort_keys)
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
    if sort_keys.is_a?(Hash)
      sort_keys.compact.map { |name, dir|
        ascending = !dir.is_a?(FalseClass) && !dir.to_s.casecmp?('desc')
        [name.to_sym, ascending]
      }.to_h
    else
      Array.wrap(sort_keys).compact.map { |name|
        name      = name.is_a?(String) ? name.dup : name.to_s
        ascending = !name.delete_suffix!('_rev')
        [name.to_sym, ascending]
      }.to_h
    end
  end

end

__loading_end(__FILE__)
