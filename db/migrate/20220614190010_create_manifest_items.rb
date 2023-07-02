# db/migrate/*_create_manifest_items.rb
#
# frozen_string_literal: true
# warn_indent:           true

class CreateManifestItems < ActiveRecord::Migration[6.1]

  def change

    create_table(:manifest_items) do |t|

      t.belongs_to :manifest, type: :uuid
      t.integer    :row,   default: 0
      t.integer    :delta, default: 0

      # === Internal record state

      t.boolean    :editing
      t.boolean    :deleting
      t.timestamp  :last_saved
      t.timestamp  :last_lookup
      t.timestamp  :last_submit
      t.timestamps

      # === Synthetic metadata

      t.string     :data_status
      t.string     :file_status
      t.string     :ready_status

      # === File metadata

      t.json       :file_data

      # === Repository information (emma_data)

      t.string     :repository              # TODO: may go away...
      t.date       :emma_publicationDate

      # === Bibliographic information (emma_data)

      t.string     :dc_title
      t.string     :emma_version
      t.string     :bib_seriesType
      t.string     :bib_series
      t.string     :bib_seriesPosition
      t.string     :dc_publisher
      t.text       :dc_creator
      t.text       :dc_identifier
      t.text       :dc_relation
      t.string     :dc_language,            array: true
      t.string     :dc_rights
      t.text       :dc_description
      t.text       :dc_subject
      t.string     :dc_type
      t.string     :dc_format
      t.string     :emma_formatFeature,     array: true
      t.date       :dcterms_dateAccepted
      t.string     :dcterms_dateCopyright

      # === Remediation information (emma_data)

      t.string     :rem_source
      t.text       :rem_metadataSource
      t.text       :rem_remediatedBy
      t.boolean    :rem_complete
      t.text       :rem_coverage
      t.string     :rem_remediatedAspects,  array: true
      t.string     :rem_textQuality
      t.string     :rem_status
      t.date       :rem_remediationDate
      t.text       :rem_comments

      # === Accessibility information (emma_data)

      t.string     :s_accessibilityFeature, array: true
      t.string     :s_accessibilityControl, array: true
      t.string     :s_accessibilityHazard,  array: true
      t.string     :s_accessMode,           array: true
      t.string     :s_accessModeSufficient, array: true
      t.text       :s_accessibilitySummary

      # === Internal record state

      t.jsonb      :backup

    end

  end

end
