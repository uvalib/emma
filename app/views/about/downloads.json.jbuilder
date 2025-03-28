# app/views/about/downloads.json.jbuilder
#
# frozen_string_literal: true
# warn_indent:           true
#
# Leaderboard of EMMA downloads.

date       = recent_date
org_recent = org_download_counts(since: date).transform_keys { _1.long_name }
org_total  = org_download_counts.transform_keys { _1.long_name }
src_recent = src_download_counts(since: date)
src_total  = src_download_counts
pub_recent = pub_download_counts(since: date)
pub_total  = pub_download_counts

entries_for = ->(items) do
  items.transform_values do |counts|
    counts.reverse_merge(total: counts.values.sum)
  end
end

json.timestamp DateTime.now

json.set! :about do
  json.set! :recent_by_org,       entries_for.(org_recent)
  json.set! :total_by_org,        entries_for.(org_total)
  json.set! :recent_by_source,    entries_for.(src_recent)
  json.set! :total_by_source,     entries_for.(src_total)
  json.set! :recent_by_publisher, entries_for.(pub_recent)
  json.set! :total_by_publisher,  entries_for.(pub_total)
end
