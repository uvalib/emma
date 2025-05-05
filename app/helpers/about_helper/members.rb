# app/helpers/about_helper/members.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper methods for the Members page.
#
module AboutHelper::Members

  include AboutHelper::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # An element containing a list of EMMA member organizations.
  #
  # @param [Boolean] heading          If *false*, do not include `<h2>` heading
  # @param [String]  css              Characteristic CSS class/selector.
  # @param [Hash]    opt              Passed to the container element.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def project_members_section(heading: true, css: '.project-members', **opt)
    orgs   = org_names.presence
    orgs &&= html_div(**prepend_css!(opt, css)) { orgs.map { html_div(_1) } }
    orgs ||= none_placeholder
    heading &&= config_page(:about, :members, :section, :list)
    heading &&= html_h2(heading)
    safe_join([heading, orgs].compact_blank)
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

end

__loading_end(__FILE__)
