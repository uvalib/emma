# app/helpers/about_helper/submissions.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper methods for the Submissions page.
#
module AboutHelper::Submissions

  include AboutHelper::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # About Submissions configuration.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  ABOUT_SUBMISSIONS_CONFIG = config_page_section(:about, :submissions)

  # About Submissions sections headings.
  #
  # @type [Hash{Symbol=>String}]
  #
  ABOUT_SUBMISSIONS_HEADING = ABOUT_SUBMISSIONS_CONFIG[:heading]

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # A list of in-page links to the section groups on the page.
  #
  # @param [Hash] opt                 Passed to #about_toc.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def about_submissions_toc(**opt)
    about_toc(**opt)
  end

  # A page section for recent EMMA submissions, if any.
  #
  # @param [Boolean] heading          If *false*, do not include `h2` heading
  # @param [Hash]    opt              Passed to #project_submissions.
  #
  # @option opt [ActiveSupport::Duration, Date, Integer] :since   Default:
  #                                                               #recent_date
  #
  # @return [ActiveSupport::SafeBuffer, nil]
  #
  def recent_submissions_section(heading: true, **opt)
    opt[:since] ||= recent_date
    counts, _ = project_submissions(**opt)
    return if counts.blank?
    heading &&= submissions_heading(:recent)
    safe_join([heading, counts].compact_blank)
  end

  # A page section for all EMMA submissions.
  #
  # @param [Boolean] heading          If *false*, do not include `h2` heading
  # @param [Hash]    opt              Passed to #project_submissions.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def total_submissions_section(heading: true, **opt)
    counts, first_date = project_submissions(**opt)
    counts  ||= none_placeholder
    heading &&= submissions_heading(:total, earliest: first_date)
    safe_join([heading, counts].compact_blank)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # An element containing a list of EMMA submissions.
  #
  # @param [ActiveSupport::Duration, Date, Integer, nil] since
  # @param [Boolean] fast             Passed to #org_submission_counts.
  # @param [String]  css              Characteristic CSS class/selector.
  # @param [Hash]    opt              Passed to the container element.
  #
  # @return [Array(ActiveSupport::SafeBuffer, String>]
  # @return [Array(ActiveSupport::SafeBuffer, nil>]
  # @return [Array(nil, nil>]
  #
  def project_submissions(since: nil, fast: false, css: '.project-submissions', **opt)
    items = org_submission_counts(since: since, fast: fast)
    first = items.delete(:first)
    return if items.blank?
    columns = submissions_columns
    prepend_css!(opt, css)
    table =
      about_table(items, columns, fast: fast, **opt) do |key|
        about_name(key, by: :org)
      end
    return table, first
  end

  # Generate a table of organizations and their submission counts in descending
  # order.
  #
  # @param [Hash] opt                 Passed to #filter_submissions except:
  #
  # @option opt [Boolean] :fast       If *true* do not generate format counts.
  # @option opt [Boolean] :no_admin   If *false* include admin users in counts.
  # @option opt [Boolean] :first      If *false* do not include :first element.
  #
  # @return [Hash{Org=>Integer,Symbol=>String}]
  #
  def org_submission_counts(**opt)
    fc_opt = opt.extract!(:fast, :no_admin)
    first  = ([] if opt.key?(:first) ? opt.delete(:first) : !opt[:since])
    items  = filter_submissions(Upload.all.order(:created_at), **opt)
    org_records(items).map { |org, records|
      next if org.nil?
      next if (counts = submission_format_counts(records, **fc_opt)).blank?
      first << records.first if first
      [org, counts]
    }.compact.sort_by { |key, counts|
      about_sort(key, counts, **opt)
    }.to_h.tap { |result|
      if (first = first&.compact).present?
        result[:first] = about_date(first.min { _1.created_at })
      end
    }
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # Generate an EMMA submissions table header based on the category.
  #
  # @param [Symbol] kind              One of `ABOUT_DOWNLOADS_HEADING.keys`.
  # @param [String] earliest          Date of earliest record.
  # @param [Hash]   opt               Passed to heading element.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def submissions_heading(kind, earliest: nil, **opt)
    heading = ABOUT_SUBMISSIONS_HEADING[kind]
    values  = submissions_values.merge!(earliest: earliest)
    html_h2(id: "#{kind}_heading", **opt) do
      interpolate(heading, values)
    end
  end

  # Generate EMMA submissions table columns.
  #
  # @return [Array<String>]
  #
  def submissions_columns
    columns = ABOUT_SUBMISSIONS_CONFIG[:columns]
    values  = submissions_values
    deep_interpolate(columns, **values)
  end

  # EMMA submissions interpolation values.
  #
  # @return [Hash]
  #
  def submissions_values
    { recent: RECENT }
  end

  # Create a query to filter submitted items.
  #
  # @param [ActiveRecord::Relation]                      items
  # @param [ActiveSupport::Duration, Date, Integer, nil] since
  # @param [Hash]                                        opt    Added terms.
  #
  # @return [ActiveRecord::Relation, ActiveRecord::QueryMethods::WhereChain]
  #
  def filter_submissions(items, since: nil, **opt)
    since &&= recent_date(since)
    query1 = items.where(state: :completed, **opt)
    query2 = (items.where('uploads.created_at >= ?', since) if since)
    (query1 && query2) ? query1.and(query2) : (query1 || query2 || items)
  end

  # Generate a table of formats and their counts in descending order.
  #
  # @param [*]    items               Records or relation.
  # @param [Hash] opt                 Passed to #download_format_counts.
  #
  # @return [Hash{String=>Integer}]
  #
  def submission_format_counts(items, **opt)
    download_format_counts(items, **opt)
  end

end

__loading_end(__FILE__)
