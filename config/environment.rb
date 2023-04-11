# config/environment.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Set key environment variables and operational settings then start the Rails
# application.

# =============================================================================
# Verify required environment variables
# =============================================================================

if respond_to?(:rails_application?) && rails_application?
  vars = [
    # === Bookshare authentication
    :BOOKSHARE_AUTH_URL,

    # === Bookshare API
    :BOOKSHARE_API_KEY,
    :BOOKSHARE_API_VERSION,
    :BOOKSHARE_API_URL,

    # === EMMA Unified Ingest API
    :INGEST_API_KEY,

    # === Internet Archive downloads
    :IA_DOWNLOAD_BASE_URL,
    :IA_ACCESS,
    :IA_SECRET,
    :IA_SIG_COOKIE,
    :IA_USER_COOKIE,
  ]
  if false # if application_deployed? || !development_build?
    # == Amazon Web Services
    vars += %i[AWS_REGION AWS_BUCKET AWS_ACCESS_KEY_ID AWS_SECRET_KEY]
  end
  vars.each do |var|
    if self.class.const_defined?(var)
      v = self.class.const_get(var)
      STDERR.puts "Empty #{var}" if v.respond_to?(:empty?) ? v.empty? : v.nil?
    else
      STDERR.puts "Missing #{var}"
    end
  end
end

# =============================================================================
# Load and initialize the Rails application
# =============================================================================

require_relative 'application'

Rails.application.initialize!
