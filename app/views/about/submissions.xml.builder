# app/views/about/submissions.xml.builder
#
# frozen_string_literal: true
# warn_indent:           true
#
# Leaderboard of EMMA submissions as XML.

date   = recent_date
recent = org_submission_counts(since: date).transform_keys { _1.long_name }
total  = org_submission_counts.transform_keys { _1.long_name }

entries_for = ->(items) do
  items.each do |name, counts|
    xml.entry(name: name, total: counts.values.sum) do
      counts.each do |format, count|
        xml.format(name: format, count: count)
      end
    end
  end
end

xml.instruct!
xml.about do
  xml.recent { entries_for.(recent) }
  xml.total  { entries_for.(total) }
end
