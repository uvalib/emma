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

  # About Downloads sections configuration.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  ABOUT_DOWNLOADS =
    ABOUT_DOWNLOADS_CONFIG[:section].select { |_, cfg| cfg.is_a?(Hash) }

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
      ABOUT_DOWNLOADS.map do |type, cfg|
        html_li do
          make_link("#by_#{type}", cfg[:label])
        end
      end
    end
  end

  # A page section target that is independent of the set of the related
  # page sections that follow it.
  #
  # @param [Symbol] by
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def downloads_section(by:, css: '.section-target', **opt)
    label = ABOUT_DOWNLOADS.dig(by, :label)
    id    = opt[:id] ||= "by_#{by}"
    skip_nav_append(label => id)
    prepend_css!(opt, css)
    html_div(**opt)
  end

  # A page section for recent EMMA downloads, if any.
  #
  # @param [Boolean] heading          If *false*, do not include `<h2>` heading
  # @param [Hash]    opt              Passed to #project_downloads.
  #
  # @option opt [ActiveSupport::Duration, Date, Integer] :since   Default:
  #                                                               #recent_date
  #
  # @return [ActiveSupport::SafeBuffer, nil]
  #
  def recent_downloads_section(heading: true, **opt)
    since  = opt.delete(:since) || recent_date
    counts = project_downloads(since: since, **opt)
    return if counts.blank?
    heading &&= ABOUT_DOWNLOADS.dig(opt[:by], :recent)
    heading &&= html_h2(heading, id: "recent_by_#{opt[:by]}")
    safe_join([heading, counts].compact_blank)
  end

  # A page section for all EMMA downloads.
  #
  # @param [Boolean] heading          If *false*, do not include `<h2>` heading
  # @param [Hash]    opt              Passed to #project_submissions.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def total_downloads_section(heading: true, **opt)
    counts = project_downloads(**opt) || none_placeholder
    heading &&= ABOUT_DOWNLOADS.dig(opt[:by], :total)
    heading &&= html_h2(heading, id: "all_by_#{opt[:by]}")
    safe_join([heading, counts].compact_blank)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # An element containing a list of EMMA downloads.
  #
  # @param [ActiveSupport::Duration, Date, Integer, nil] since
  # @param [Symbol] by                Either :org or :source
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt               Passed to the container element.
  #
  # @return [ActiveSupport::SafeBuffer, nil]
  #
  def project_downloads(since: nil, by: :org, css: '.project-downloads', **opt)
    return if (items = download_counts(by: by, since: since)).blank?
    cols    = ABOUT_DOWNLOADS_CONFIG[:columns]
    since &&= recent_date(since)
    prepend_css!(opt, css)
    about_table(items, cols, **opt) do |key|
      p_opt = { by => key, start_date: since }.compact
      path  = downloads_url(**p_opt)
      name  = name_of(key, by: by)
      make_link(path, name)
    end
  end

  # Generate a table of download counts in descending order.
  #
  # @param [Symbol] by                Either :org or :source
  # @param [Hash]   opt
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
  # @param [Hash] opt                 Passed to #filter_downloads.
  #
  # @return [Hash{Org=>Integer}]
  #
  def org_download_counts(**opt)
    Org.all.map { |org|
      items  = filter_downloads(org.downloads, **opt)
      counts = format_counts(items)
      [org, counts] if counts.present?
    }.compact.sort_by { |key, counts| about_sort(key, counts, **opt) }.to_h
  end

  # Generate a table of repository sources and their download counts in
  # descending order.
  #
  # @param [Hash] opt                 Passed to #filter_downloads.
  #
  # @return [Hash{Org=>Integer}]
  #
  def src_download_counts(**opt)
    items = filter_downloads(Download.all, **opt)
    items.group_by { _1.source }.map { |item|
      repo   = item.shift
      recs   = item.first
      counts = format_counts(recs)
      [repo, counts]
    }.sort_by { |key, counts| about_sort(key, counts, **opt) }.to_h
  end

  # Generate a table of publishers and their download counts in descending
  # order.
  #
  # @param [Hash] opt                 Passed to #filter_downloads.
  #
  # @return [Hash{Org=>Integer}]
  #
  def pub_download_counts(**opt)
    items = filter_downloads(Download.all, **opt)
    items.group_by { _1.publisher }.map { |item|
      pub    = item.shift.presence || Download::NO_PUBLISHER
      recs   = item.first
      counts = format_counts(recs)
      [pub, counts]
    }.sort_by { |key, counts| about_sort(key, counts, **opt) }.to_h
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

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
    query1 = (items.where('downloads.created_at >= ?', since) if since)
    query2 = (items.where(**opt) if opt.present?)
    (query1 && query2 && query1.and(query2)) || query1 || query2 || items
  end

  # Generate a table of formats and their counts in descending order.
  #
  # @param [*] items
  #
  # @return [Hash{String=>Integer}]
  #
  def format_counts(items)
    counts = {}
    items.each do |item|
      format = DublinCoreFormat(item.fmt)&.label || 'unknown'
      counts[format] ||= 0
      counts[format] += 1
    end
    counts.sort_by { |fmt, cnt| [-cnt, fmt] }.to_h
  end

end

__loading_end(__FILE__)
