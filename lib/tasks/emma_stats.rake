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
# @type [Hash{String=>String}]
#
# == Implementation Notes
# Overrides of ::CodeStatistics and ::CodeStatisticsCalculator are required
# to report on CSS/SCSS/SASS.
#
EMMA_STATS_DIRECTORIES ||= [
  %w(Controllers        app/controllers),
  %w(Helpers            app/helpers),
  %w(Models             app/models),
  %w(Records            app/records),
  %w(Services           app/services),
# %w(Channels           app/channels),
# %w(Mailers            app/mailers),
# %w(Mailboxes          app/mailboxes),
  %w(Jobs               app/jobs),
  %w(Libraries          lib),
  %w(APIs               app/apis),
  %w(Stylesheets        app/assets/stylesheets),
  %w(JavaScripts        app/assets/javascripts),
# %w(JavaScript         app/javascript),
  %w(Controller\ tests  test/controllers),
  %w(Helper\ tests      test/helpers),
  %w(Model\ tests       test/models),
# %w(Channel\ tests     test/channels),
# %w(Mailer\ tests      test/mailers),
# %w(Mailbox\ tests     test/mailboxes),
  %w(Job\ tests         test/jobs),
  %w(Integration\ tests test/integration),
  %w(System\ tests      test/system),
].map { |name, dir|
  [name, "#{File.dirname(Rake.application.rakefile_location)}/#{dir}"]
 }.select { |_name, dir| File.directory?(dir) }
