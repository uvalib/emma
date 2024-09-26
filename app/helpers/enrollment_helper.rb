# app/helpers/enrollment_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Support methods for working with enrollment requests.
#
module EnrollmentHelper

  include LinkHelper

  extend self

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Make a link to the enrollment page for anonymous users.
  #
  # @param [String, nil] label
  # @param [String]      css        Characteristic CSS class/selector.
  # @param [Hash]        opt        Passed to #make_link except:
  #
  # @option opt [String] :path      Override default path.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def enroll_link(label = nil, css: '.enroll-link', **opt)
    label ||= config_term(:enrollment, :enroll, :link)
    path    = opt.delete(:path) || enroll_path
    opt.reverse_merge!('data-turbolinks': false)
    prepend_css!(opt, css)
    make_link(path, label, **opt)
  end

  # Make a link to the enrollment page on the production system.
  #
  # @param [String, nil] label
  # @param [String]      css        Characteristic CSS class/selector.
  # @param [Hash]        opt        Passed to #enroll_link.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def production_enroll_link(label = nil, css: '.production', **opt)
    label      ||= config_term(:enrollment, :enroll, :production, :link)
    opt[:path] ||= make_path(PRODUCTION_URL, enroll_path)
    append_css!(opt, css)
    enroll_link(label, **opt)
  end

  alias :production_enroll_link :enroll_link if production_deployment?

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    __included(base, self)
    base.extend(self)
  end

end

__loading_end(__FILE__)
