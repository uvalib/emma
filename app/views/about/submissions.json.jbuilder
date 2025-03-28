# app/views/about/submissions.json.jbuilder
#
# frozen_string_literal: true
# warn_indent:           true
#
# Leaderboard of EMMA submissions.

date   = recent_date
recent = org_submission_counts(since: date).transform_keys { _1.long_name }
total  = org_submission_counts.transform_keys { _1.long_name }

entries_for = ->(items) do
  items.transform_values do |counts|
    counts.reverse_merge(total: counts.values.sum)
  end
end

json.timestamp DateTime.now

json.set! :about do
  json.set! :recent, entries_for.(recent)
  json.set! :total,  entries_for.(total)
end
