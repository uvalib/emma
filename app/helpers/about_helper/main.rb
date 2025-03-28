# app/helpers/about_helper/main.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'loofah'

# View helper methods for the main About page.
#
module AboutHelper::Main

  include AboutHelper::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Default source for #external_content_section.
  #
  # @type [String]
  #
  EXTERNAL_CONTENT_URL = config_page(:about, :content_url).freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # An element containing content acquired from an external source.
  #
  # By default, a section heading is prepended only if the content does not
  # have a heading element.
  #
  # @param [Boolean,nil] heading      If *false*, do not include `<h2>` heading
  # @param [String]      css          Characteristic CSS class/selector.
  # @param [Hash]        opt          Passed to the container element.
  #
  # @return [ActiveSupport::SafeBuffer, nil]
  #
  def external_content_section(heading: nil, css: '.project-external', **opt)
    url   = opt.extract!(:url, :src).values.first || EXTERNAL_CONTENT_URL
    resp  = Faraday.get(url)
    error =
      if (stat = resp.status) != 200
        "status #{stat}"
      elsif (body = resp.body.strip).blank?
        'missing/blank content'
      elsif (content = scrub_content(body)).blank?
        "invalid content: #{body.inspect}"
      end
    return Log.warn { "#{__method__}: #{url.inspect}: #{error}" } if error

    content   = html_div(content, **prepend_css!(opt, css))
    heading   = true if heading.nil? && !content.match?(/<h[1-6]/)
    heading &&= config_page(:about, :index, :section, :content)
    heading &&= html_h2(heading)
    safe_join([heading, content].compact_blank)
  end

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

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # A scrubber for ensuring that the content does not have `<h1>`.
  #
  # @type [Loofah::Scrubber]
  #
  SCRUB_H1 = Loofah::Scrubber.new { _1.name = 'h2' if _1.name == 'h1' }

  # Remove undesirable HTML from received content.
  #
  # @param [String] body
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def scrub_content(body)
    fragment = Loofah.html5_fragment(body)
    fragment.scrub!(:prune)
    fragment.scrub!(:unprintable)
    fragment.scrub!(:targetblank)
    fragment.scrub!(SCRUB_H1)
    fragment.to_s.html_safe
  end

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
    html ? data : data.transform_keys! { _1.tr(' ', '_').underscore }
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
        content.map { html_dt(_1.to_s) << html_dd(_2) }
      end
    content ||= none_placeholder
    safe_join([heading, content].compact)
  end

end

__loading_end(__FILE__)
