# app/helpers/about_helper/downloads.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper methods for the Downloads page.
#
module AboutHelper::Downloads

  include AboutHelper::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # About Downloads configuration.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  ABOUT_DOWNLOADS_CONFIG = config_page_section(:about, :downloads)

  # About Downloads sections headings.
  #
  # @type [Hash{Symbol=>String}]
  #
  ABOUT_DOWNLOADS_HEADING = ABOUT_DOWNLOADS_CONFIG[:heading]

  # About Downloads sections configuration.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  ABOUT_DOWNLOADS_SECTION = ABOUT_DOWNLOADS_CONFIG[:section]

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # A list of in-page links to the section groups on the page.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def about_downloads_toc
    html_ul do
      ABOUT_DOWNLOADS_SECTION.map do |type, cfg|
        html_li do
          make_link("#by_#{type}", cfg[:label])
        end
      end
    end
  end

  # A page section target that is independent of the set of the related
  # page sections that follow it.
  #
  # @param [Symbol] by                One of `ABOUT_DOWNLOADS_SECTION.keys`.
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def downloads_section(by:, css: '.section-target', **opt)
    label = ABOUT_DOWNLOADS_SECTION.dig(by, :label)
    id    = opt[:id] ||= "by_#{by}"
    skip_nav_append(label => id)
    prepend_css!(opt, css)
    html_div(**opt)
  end

  # A page section for recent EMMA downloads, if any.
  #
  # @param [Boolean] heading          If *false*, do not include `h2` heading
  # @param [Hash]    opt              Passed to #project_downloads.
  #
  # @option opt [ActiveSupport::Duration, Date, Integer] :since   Default:
  #                                                               #recent_date
  #
  # @return [ActiveSupport::SafeBuffer, nil]
  #
  def recent_downloads_section(heading: true, **opt)
    opt[:since] ||= recent_date
    counts, _ = project_downloads(**opt)
    return if counts.blank?
    heading &&= downloads_heading(:recent, opt[:by])
    safe_join([heading, counts].compact_blank)
  end

  # A page section for all EMMA downloads.
  #
  # @param [Boolean] heading          If *false*, do not include `h2` heading
  # @param [Hash]    opt              Passed to #project_downloads.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def total_downloads_section(heading: true, **opt)
    counts, first_date = project_downloads(**opt)
    counts  ||= none_placeholder
    heading &&= downloads_heading(:total, opt[:by], earliest: first_date)
    safe_join([heading, counts].compact_blank)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # An element containing a list of EMMA downloads.
  #
  # @param [ActiveSupport::Duration, Date, Integer, nil] since
  # @param [Symbol] by                One of `ABOUT_DOWNLOADS_SECTION.keys`.
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt               Passed to the container element.
  #
  # @return [Array(ActiveSupport::SafeBuffer, String>]
  # @return [Array(ActiveSupport::SafeBuffer, nil>]
  # @return [Array(nil, nil>]
  #
  def project_downloads(since: nil, by: :org, css: '.project-downloads', **opt)
    items = download_counts(by: by, since: since)
    first = items.delete(:first)
    return if items.blank?
    since &&= recent_date(since)
    columns = downloads_columns(by)
    prepend_css!(opt, css)
    table =
      about_table(items, columns, **opt) do |key|
        p_opt = { by => key, start_date: since }.compact
        path  = downloads_url(**p_opt)
        name  = about_name(key, by: by)
        make_link(path, name)
      end
    return table, first
  end

  # Generate a table of download counts in descending order.
  #
  # @param [Symbol] by                One of `ABOUT_DOWNLOADS_SECTION.keys`.
  # @param [Hash]   opt               Passed to count method.
  #
  # @return [Hash{Org=>Integer}]
  #
  def download_counts(by: :org, **opt)
    case by
      when :org       then org_download_counts(**opt)
      when :source    then src_download_counts(**opt)
      when :publisher then pub_download_counts(**opt)
      else                 Log.error("#{__method__}: by #{by.inspect}")
    end
  end

  # Generate a table of organizations and their download counts in descending
  # order.
  #
  # @param [Hash] opt                 Passed to #filter_downloads except:
  #
  # @option opt [Boolean] :no_admin   If *false* include admin users in counts.
  # @option opt [Boolean] :first      If *false* do not include :first element.
  #
  # @return [Hash{Org=>Integer,Symbol=>String}]
  #
  def org_download_counts(**opt)
    fc_opt = opt.extract!(:no_admin)
    first  = ([] if opt.key?(:first) ? opt.delete(:first) : !opt[:since])
    Org.all.map { |org|
      records = filter_downloads(org.downloads, **opt)
      counts  = download_format_counts(records, **fc_opt)
      first << records.first if first
      [org, counts] if counts.present?
    }.compact.sort_by { |key, counts|
      about_sort(key, counts, **opt)
    }.to_h.tap { |result|
      if (first = first&.compact).present?
        result[:first] = about_date(first.min { _1.created_at })
      end
    }
  end

  # Generate a table of repository sources and their download counts in
  # descending order.
  #
  # @param [Hash] opt                 Passed to #filter_downloads except:
  #
  # @option opt [Boolean] :no_admin   If *false* include admin users in counts.
  # @option opt [Boolean] :first      If *false* do not include :first element.
  #
  # @return [Hash{String=>Integer,Symbol=>String}]
  #
  def src_download_counts(**opt)
    fc_opt = opt.extract!(:no_admin)
    first  = opt.key?(:first) ? opt.delete(:first) : !opt[:since]
    items  = filter_downloads(Download.all, **opt)
    items.group_by { _1.source }.map { |(source, records)|
      counts = download_format_counts(records, **fc_opt)
      [source, counts]
    }.sort_by { |key, counts|
      about_sort(key, counts, **opt)
    }.to_h.tap { |result|
      result[:first] = about_date(items.first) if first
    }
  end

  # Generate a table of publishers and their download counts in descending
  # order.
  #
  # @param [Hash] opt                 Passed to #filter_downloads except:
  #
  # @option opt [Boolean] :no_admin   If *false* include admin users in counts.
  # @option opt [Boolean] :first      If *false* do not include :first element.
  #
  # @return [Hash{String=>Integer,Symbol=>String}]
  #
  def pub_download_counts(**opt)
    fc_opt = opt.extract!(:no_admin)
    first  = opt.key?(:first) ? opt.delete(:first) : !opt[:since]
    items  = filter_downloads(Download.all, **opt)
    items.group_by { _1.publisher }.map { |(publisher, records)|
      publisher ||= Download::NO_PUBLISHER
      counts = download_format_counts(records, **fc_opt)
      [publisher, counts]
    }.sort_by { |key, counts|
      about_sort(key, counts, **opt)
    }.to_h.tap { |result|
      result[:first] = about_date(items.first) if first
    }
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # Generate an EMMA downloads table header based on the category and section.
  #
  # @param [Symbol] kind              One of `ABOUT_DOWNLOADS_HEADING.keys`.
  # @param [Symbol] section           One of `ABOUT_DOWNLOADS_SECTION.keys`.
  # @param [String] earliest          Date of earliest record.
  # @param [Hash]   opt               Passed to heading element.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def downloads_heading(kind, section, earliest: nil, **opt)
    heading = ABOUT_DOWNLOADS_HEADING[kind]
    values  = downloads_values(section).merge!(earliest: earliest)
    html_h2(id: "#{kind}_by_#{section}", **opt) do
      interpolate(heading, values)
    end
  end

  # Generate EMMA downloads table columns based on the section.
  #
  # @param [Symbol] section           One of `ABOUT_DOWNLOADS_SECTION.keys`.
  #
  # @return [Array<String>]
  #
  def downloads_columns(section)
    columns = ABOUT_DOWNLOADS_CONFIG[:columns]
    values  = downloads_values(section)
    deep_interpolate(columns, **values)
  end

  # EMMA downloads interpolation values based on the section.
  #
  # @param [Symbol] section           One of `ABOUT_DOWNLOADS_SECTION.keys`.
  #
  # @return [Hash]
  #
  def downloads_values(section)
    ABOUT_DOWNLOADS_SECTION[section].reverse_merge(recent: RECENT)
  end

  # Create a query to filter download items.
  #
  # @param [ActiveRecord::Relation]                      items
  # @param [ActiveSupport::Duration, Date, Integer, nil] since
  # @param [Hash]                                        opt    Added terms.
  #
  # @return [ActiveRecord::Relation, ActiveRecord::QueryMethods::WhereChain]
  #
  def filter_downloads(items, since: nil, **opt)
    since &&= recent_date(since)
    query1 = (items.where(**opt) if opt.present?)
    query2 = (items.where('downloads.created_at >= ?', since) if since)
    (query1 && query2) ? query1.and(query2) : (query1 || query2 || items)
  end

  # Generate a table of formats and their counts in descending order.
  #
  # @param [*]       items            Records or relation.
  # @param [Boolean] no_admin         If *false* include admin users in counts.
  #
  # @return [Hash{String=>Integer}]
  #
  def download_format_counts(items, no_admin: production_deployment?, **)
    counts = {}
    items.each do |item|
      next if no_admin && item.user.administrator?
      format = DublinCoreFormat(item.fmt)&.label || 'unknown'
      counts[format] ||= 0
      counts[format] += 1
    end
    counts.sort_by { |fmt, cnt| [-cnt, fmt] }.to_h
  end

end

__loading_end(__FILE__)
