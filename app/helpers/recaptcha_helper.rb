# app/helpers/recaptcha_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'recaptcha'

# Support methods for managing reCAPTCHA authorization.
#
# @see https://www.google.com/recaptcha/admin/site/698256122
#
module RecaptchaHelper

  include IdentityHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The older version of reCAPTCHA is better for selective use on specific
  # pages.  Version 3 is better for websites where *every* form submission is
  # reCAPTCHA-validated.
  #
  # @type [Integer]
  #
  RECAPTCHA_VERSION = ENV_VAR['RECAPTCHA_VERSION'].to_i

  # So-called "invisible" reCAPTCHA involves display of reCAPTCHA branding but
  # is easier for cases where validation needs to work alongside existing logic
  # triggered by the submit button. Standard reCAPTCHA v2 is better where the
  # submit button can be freely managed by client-side reCAPTCHA logic.
  #
  # @type [Boolean]
  #
  RECAPTCHA_INVISIBLE = true

  # By default, the "recaptcha" gem injects the script element along with the
  # reCAPTCHA tags.  If this constant is *true*, that script element is added
  # to `<head>` instead.
  #
  # @type [Boolean]
  #
  RECAPTCHA_HEAD = true

  if sanity_check?
    v = RECAPTCHA_VERSION
    unless [2, 3].include?(v)
      raise "Invalid RECAPTCHA_VERSION: #{v.inspect}"
    end
    if RECAPTCHA_INVISIBLE && (v != 2)
      __output("WARNING: RECAPTCHA_INVISIBLE ignored for version #{v.inspect}")
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether reCAPTCHA would be in use on forms that require it.
  #
  # @note This is never *true* for the test environment.
  #
  # @param [Hash] opt                 Passed to Recaptcha#skip_env?.
  #
  def recaptcha_active?(**opt)
    !administrator? && !Rails.env.test? && !Recaptcha.skip_env?(opt[:env])
  end

  # Emit reCAPTCHA tags.
  #
  # If reCAPTCHA is not in use, an empty string is returned.
  #
  # @param [String, nil] css        Characteristic CSS class.
  # @param [Hash]        opt        Options passed to the reCAPTCHA tags.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see app/assets/javascripts/feature/model-form.js
  #
  def recaptcha(css: '.recaptcha', **opt)
    return ''.html_safe unless recaptcha_active?(**opt)
    if RECAPTCHA_HEAD
      service = Recaptcha.configuration.api_server_url
      append_page_javascripts({ src: service, async: true, defer: true })
      opt[:script] = false
    end
    opt.reverse_merge!('data-badge': 'inline')
    prepend_css!(opt, css)
    if RECAPTCHA_INVISIBLE
      opt[:ui]       = :invisible
      opt[:callback] = 'successfulRecaptcha'
      # opt[:'error-callback'] = 'failedRecaptcha'
      append_css!(opt, 'recaptcha-invisible')
      invisible_recaptcha_tags(opt)
    elsif RECAPTCHA_VERSION == 3
      recaptcha_v3(opt)
    else
      recaptcha_tags(opt)
    end
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
