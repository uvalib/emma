# app/views/about/submissions.json.jbuilder
#
# frozen_string_literal: true
# warn_indent:           true
#
# Leaderboard of EMMA submissions.

recent ||= org_submission_counts(since: recent_date)
total  ||= org_submission_counts

json.timestamp DateTime.now

json.set! :about do
  json.set! :recent, recent
  json.set! :total,  total
end
