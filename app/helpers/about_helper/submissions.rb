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

  # A page section for recent EMMA submissions, if any.
  #
  # @param [Boolean] heading          If *false*, do not include `<h2>` heading
  # @param [Hash]    opt              Passed to #project_submissions.
  #
  # @option opt [ActiveSupport::Duration, Date, Integer] :since   Default:
  #                                                               #recent_date
  #
  # @return [ActiveSupport::SafeBuffer, nil]
  #
  def recent_submissions_section(heading: true, **opt)
    since  = opt.delete(:since) || recent_date
    counts = project_submissions(since: since, **opt)
    return if counts.blank?
    heading &&= config_page(:about, :submissions, :section, :recent)
    heading &&= html_h2(heading)
    safe_join([heading, counts].compact_blank)
  end

  # A page section for all EMMA submissions.
  #
  # @param [Boolean] heading          If *false*, do not include `<h2>` heading
  # @param [Hash]    opt              Passed to #project_submissions.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def total_submissions_section(heading: true, **opt)
    counts = project_submissions(**opt) || none_placeholder
    heading &&= config_page(:about, :submissions, :section, :total)
    heading &&= html_h2(heading)
    safe_join([heading, counts].compact_blank)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # An element containing a list of EMMA submissions.
  #
  # @param [ActiveSupport::Duration, Date, Integer, nil] since
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt               Passed to the container element.
  #
  # @return [ActiveSupport::SafeBuffer, nil]
  #
  def project_submissions(since: nil, css: '.project-submissions', **opt)
    return if (items = org_submission_counts(since: since)).blank?
    cols = config_page(:about, :submissions, :columns)
    prepend_css!(opt, css)
    about_table(items, cols, **opt) do |key|
      name_of(key, by: :org)
    end
  end

  # Generate a table of organizations and their submission counts in descending
  # order.
  #
  # @param [ActiveSupport::Duration, Date, Integer, nil] since
  # @param [Hash] opt                 Passed to 'uploads' #where clause.
  #
  # @return [Hash{Org=>Integer}]
  #
  def org_submission_counts(since: nil, **opt)
    since &&= recent_date(since)
    Org.all.map { |org|
      items = org.uploads.where(state: :completed, **opt)
      items = items.and(items.where('uploads.created_at >= ?', since)) if since
      counts = format_counts(items)
      [org, counts] if counts.present?
    }.compact.sort_by { |key, counts|
      # noinspection RubyMismatchedArgumentType
      about_sort(key, counts, since: since)
    }.to_h
  end

end

__loading_end(__FILE__)
