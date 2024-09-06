# app/helpers/about_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper methods for rendering application information.
#
module AboutHelper

  include CssHelper
  include HtmlHelper
  include EmmaHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # An element containing useful project-related links.
  #
  # @param [Boolean] heading          If *false*, do not include `<h2>` heading
  # @param [String]  css              Characteristic CSS class/selector.
  # @param [Hash]    opt              Passed to the container element.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def project_links_section(heading: true, css: '.project-links', **opt)
    links   = project_links.presence
    heading = (config_page(:about, :index, :section, :links) if heading)
    prepend_css!(opt, css)
    # noinspection RubyMismatchedArgumentType
    project_table_section(links, heading, **opt)
  end

  # An element containing links to project-related reference material.
  #
  # @param [Boolean] heading          If *false*, do not include `<h2>` heading
  # @param [String]  css              Characteristic CSS class/selector.
  # @param [Hash]    opt              Passed to the container element.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def project_references_section(heading: true, css: '.project-refs', **opt)
    links   = project_refs.presence
    heading = (config_page(:about, :index, :section, :refs) if heading)
    prepend_css!(opt, css)
    # noinspection RubyMismatchedArgumentType
    project_table_section(links, heading, **opt)
  end

  # An element containing a list of EMMA member organizations.
  #
  # @param [Boolean] heading          If *false*, do not include `<h2>` heading
  # @param [String]  css              Characteristic CSS class/selector.
  # @param [Hash]    opt              Passed to the container element.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def project_members_section(heading: true, css: '.project-members', **opt)
    orgs = org_names.presence
    orgs &&=
      html_div(**prepend_css!(opt, css)) do
        orgs.map { |org| html_div(org) }
      end
    orgs ||= none_placeholder
    heading &&= config_page(:about, :members, :section, :list)
    heading &&= html_h2(heading)
    safe_join([heading, orgs].compact_blank)
  end

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

  # Generate a table of useful project-related links.
  #
  # @param [Hash] opt                 Passed to #project_table.
  #
  # @return [Hash]
  #
  def project_links(**opt)
    html = opt[:format].nil? || (opt[:format].to_sym == :html)
    data = {
      'Mailing list email': html ? mailing_list_email : MAILING_LIST_EMAIL,
      'Mailing list site':  html ? mailing_list_site  : MAILING_LIST_SITE,
      'Project web site':   html ? project_site       : PROJECT_SITE,
    }
    project_table(data, **opt)
  end

  # Generate a table of links to project-related reference material.
  #
  # @param [Hash] opt                 Passed to #project_table.
  #
  # @return [Hash]
  #
  def project_refs(**opt)
    paper = white_paper
    if opt[:format] && (opt[:format].to_sym != :html)
      title = strip_links(paper).sub(/^"(.*)"$/, '\1')
      url   = paper.sub(/^.*href="([^"]+)".*$/, '\1')
      paper = { title: title, url: url }
    end
    data = {
      'EMMA white paper': paper,
    }
    project_table(data, **opt)
  end

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
    cols  = config_page(:about, :submissions, :columns)
    thead =
      html_thead do
        html_tr do
          cols.map { |column| html_th(column) }
        end
      end
    tbody =
      html_tbody do
        items.map { |name, count|
          html_tr do
            html_th(name) << html_td(count)
          end
        }
      end
    prepend_css!(opt, css)
    html_table(thead, *tbody, **opt)
  end

  # Generate a list of EMMA member organizations
  #
  # @param [Hash] opt                 Passed to 'orgs' #where clause.
  #
  # @return [Array<String>]
  #
  def org_names(**opt)
    orgs = Org.active
    orgs = orgs.where(**opt) if opt.present?
    orgs.pluck(:long_name).sort
  end

  # Generate a table of organizations and their submission counts in descending
  # order.
  #
  # @param [ActiveSupport::Duration, Date, Integer, nil] since
  # @param [Hash] opt                 Passed to 'uploads' #where clause.
  #
  # @return [Hash]
  #
  def org_submission_counts(since: nil, **opt)
    since &&= recent_date(since)
    Org.all.map { |org|
      items = org.uploads.where(state: :completed, **opt)
      items = items.and(items.where('uploads.created_at >= ?', since)) if since
      count = items.count
      [org.long_name, count] if count.positive?
    }.compact.sort_by { |_, count| -count }.to_h
  end

  # The past date indicated by the argument.
  #
  # @param [ActiveSupport::Duration, Date, Integer, nil] since
  #
  # @return [Date, nil]
  #
  def recent_date(since = 30.days)
    # noinspection RubyMismatchedReturnType
    case since
      when ActiveSupport::Duration then Date.today - since.in_days
      when Integer                 then Date.today - since.days
      when Date, nil               then since
      else Log.error("#{__method__}: unexpected: #{since.inspect}")
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Generate a table of values with keys modified according to the *format*.
  #
  # @param [Hash]        data
  # @param [Symbol, nil] format       One of :json, :xml, or :html (default).
  #
  # @return [Hash]
  #
  def project_table(data, format: nil, **)
    data = data.compact.stringify_keys!
    html = format.nil? || (format.to_sym == :html)
    html ? data : data.transform_keys! { |name| name.tr(' ', '_').underscore }
  end

  # An element containing a table of project-related information.
  #
  # @param [Hash, nil]   content
  # @param [String, nil] heading
  # @param [Hash]        opt          Passed to the container element.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def project_table_section(content, heading = nil, **opt)
    heading   = (html_h2(heading) if heading.present?)
    content   = content.presence
    content &&=
      html_div(**opt) do
        content.map { |k, v| html_dt(k.to_s) << html_dd(v) }
      end
    content ||= none_placeholder
    safe_join([heading, content].compact)
  end

  # A fallback element indicating "NONE".
  #
  # @param [Hash] opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def none_placeholder(**opt)
    html_div(**opt) do
      config_term(:none).upcase
    end
  end

end

__loading_end(__FILE__)