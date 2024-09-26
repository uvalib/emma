# lib/tasks/emma_stats.rake
#
# frozen_string_literal: true
# warn_indent:           true
#
# EMMA code base statistics

namespace :emma do

  desc 'Report code statistics (KLOCs, etc) from the application or engine'
  task :stats do
    CodeStatistics.new(*EMMA_STATS_DIRECTORIES).to_s
  end

end

# Replacement for the directories hard-wired into the standard :stats task in
# order to report on code in "non-standard" directories and to report on SCSS.
#
# @type [Array<(String,String)>]
#
# === Implementation Notes
# Overrides of ::CodeStatistics and ::CodeStatisticsCalculator are required
# to report on CSS/SCSS/SASS.
#
EMMA_STATS_DIRECTORIES ||= [
  %w[Controllers        app/controllers],
  %w[Decorators         app/decorators],
  %w[Helpers            app/helpers],
  %w[Models             app/models],
  %w[Records            app/records],
  %w[Services           app/services],
  %w[Channels           app/channels],
# %w[Mailers            app/mailers],
# %w[Mailboxes          app/mailboxes],
  %w[Jobs               app/jobs],
  %w[Libraries          lib],
  %w[APIs               app/apis],

  %w[Views              app/views],
  %w[Stylesheets        app/assets/stylesheets],
  %w[JavaScripts        app/assets/javascripts],
# %w[JavaScript         app/javascript],

  %w[Controller\ tests  test/controllers],
  %w[Decorator\ tests   test/decorators],
  %w[Helper\ tests      test/helpers],
  %w[Model\ tests       test/models],
  %w[Record\ tests      test/records],
  %w[Service\ tests     test/services],
  %w[Channel\ tests     test/channels],
# %w[Mailer\ tests      test/mailers],
# %w[Mailbox\ tests     test/mailboxes],
  %w[Job\ tests         test/jobs],
  %w[Integration\ tests test/integration],
  %w[System\ tests      test/system],
  %w[Test\ helpers      test/test_helper],

  %w[Configuration      config/locales],
].map { |name, dir|
  base = File.dirname(Rake.application.rakefile_location)
  dir  = File.join(base, dir)
  [name, dir] if File.directory?(dir)
}.compact
