# app/views/about/downloads.xml.builder
#
# frozen_string_literal: true
# warn_indent:           true
#
# Leaderboard of EMMA downloads as XML.

date       = recent_date
org_recent = org_download_counts(since: date).transform_keys { _1.long_name }
org_total  = org_download_counts.transform_keys { _1.long_name }
src_recent = src_download_counts(since: date)
src_total  = src_download_counts
pub_recent = pub_download_counts(since: date)
pub_total  = pub_download_counts

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
  xml.recent_by_org       { entries_for.(org_recent) }
  xml.total_by_org        { entries_for.(org_total) }
  xml.recent_by_source    { entries_for.(src_recent) }
  xml.total_by_source     { entries_for.(src_total) }
  xml.recent_by_publisher { entries_for.(pub_recent) }
  xml.total_by_publisher  { entries_for.(pub_total) }
end
