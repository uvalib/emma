# app/views/about/submissions.xml.builder
#
# frozen_string_literal: true
# warn_indent:           true
#
# Leaderboard of EMMA submissions as XML.

recent ||= org_submission_counts(since: recent_date)
total  ||= org_submission_counts

xml.instruct!
xml.about do
  xml.recent do
    recent.each do |name, count|
      xml.member do
        xml.tag! :name,  name
        xml.tag! :count, count
      end
    end
  end
  xml.total do
    total.each do |name, count|
      xml.member do
        xml.tag! :name,  name
        xml.tag! :count, count
      end
    end
  end
end
