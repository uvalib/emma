# app/models/concerns/import/ia_bulk.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Definitions for the pre-release bulk upload of items gathered by Internet
# Archive.
#
module Import::IaBulk

  include Import
  include IsbnHelper

  extend self

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Import schema.
  #
  # @type [Hash{Symbol=>Symbol,Array<(Symbol,(Symbol,Proc))>}]
  #
  #--
  # noinspection LongLine
  #++
  SCHEMA = {
    #-------------------- --------------------------- -------------------------
    # Underscored name    Translator method or field  Value translator method
    #-------------------- --------------------------- -------------------------
    collection:           [:emma_collection,          :values],
    contributed_format:   :translate_formats,
    contributor:          [:rem_source,               :string_value],
    date:                 [:dcterms_dateCopyright,    :year_value],
    description:          [:dc_description,           :string_value],
    doi:                  [:dc_identifier,            :doi_values],
    free_to_download:     :skip,
    free_to_view:         :skip,
    identifier:           :skip,
    'identifier-access':  :skip,
    imagecount:           [:rem_image_count,          :ordinal_value],
    isbn:                 [:dc_identifier,            :isbn_values],
    issn:                 [:dc_identifier,            :issn_values],
    language:             [:dc_language,              :language_values],
    mediatype:            [:dc_type,                  :media_type_values],
    metadata_source:      [:rem_metadataSource,       :values],
    neverindex:           :skip,
    noindex:              :skip,
    portion:              [:rem_complete,             ->(v) { !true?(v) }],
    portion_description:  [:rem_coverage,             :values],
    publisher:            [:dc_publisher,             :string_value],
    remediated_aspects:   [:rem_remediation,          :values],
    remediated_by:        [:rem_remediatedBy,         :values],
    remediation_comments: [:emma_lastRemediationNote, :string_value],
    remediation_status:   [:rem_status,               :values],
    series_type:          [:bib_seriesType,           :string_value],
    subject:              [:dc_subject,               :array_value],
    text_quality:         [:rem_quality,              :values],
    title:                [:dc_title,                 :string_value],
    version:              [:bib_version,              :string_value],
    volume:               [:bib_seriesPosition,       :string_value],
  }.freeze

  # Each "format" provided gets mapping into several :emma_data fields.
  #
  # @type [Hash{Symbol=>Array<Symbol>}]
  #
  FORMAT = {
    #-------------------- -------------   --------  -------------------------
    # Underscored name    :dc_format      :dc_type  :emma_formatFeature
    #-------------------- -------------   --------  -------------------------
    epub:                 %i[epub],
    word:                 %i[word],
    image_pdf:            %i[pdf          image],
    text_pdf:             %i[pdf          text],
    daisy_spoken:         %i[daisy        sound     human],
    daisy_tts:            %i[daisy        sound     tts],
    audio:                %i[daisy        sound], # TODO: not daisy?
    tactile_graphics:     %i[tactile],
    kurzweil:             %i[kurzweil],
    ueb_literary_grade_1: %i[braille      text      ueb   grade1  literary],
    ueb_literary_grade_2: %i[braille      text      ueb   grade2  literary],
    ebae:                 %i[braille      text      ebae],
    ueb_technical:        %i[braille      text      ueb   technical],
    ueb_nemeth:           %i[braille      text      ueb   nemeth],
  }.deep_freeze

  # Each "mediatype" contributes to the :dc_type value.
  #
  # @type [Hash{Symbol=>Symbol}]
  #
  MEDIA_TYPE = {
    #----- ---------
    # Name :dc_type
    #----- ---------
    texts: :text,
    audio: :sound,
    data:  :dataset,
  }.deep_freeze

  # If no format was provided in order to determine :dc_format, then
  # #normalize_results will use this table to come up with a guess based on
  # 'media_type' (if it was given).
  #
  # @type [Hash{Symbol=>Symbol}]
  #
  DC_TYPE_TO_DC_FORMAT = {
    #-----------  ----------
    # :dc_type    :dc_format
    #-----------  ----------
    text:         :braille,
    sound:        :daisy,
    dataset:      :pdf,
    image:        :pdf,
    still_image:  :pdf,
    _default:     :word,
  }.deep_freeze

  # ===========================================================================
  # :section: Import overrides
  # ===========================================================================

  public

  # Import schema.
  #
  # @return [Hash]
  #
  # This method overrides:
  # @see Import#schema
  #
  def schema
    SCHEMA #.dup
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Translate a format value into one or more :emma_data fields as indicated by
  # the #FORMAT mapping.
  #
  # @param [Symbol] _k                The name of the field being imported.
  # @param [*]      v
  #
  # @return [Array<(Array<Symbol>,Array)>]
  #
  def translate_formats(_k, v)
    key    = hash_key(v)
    values = FORMAT[key]&.dup || [key].compact
    field  = {}
    field[:dc_format]          = values.shift if values.present?
    field[:dc_type]            = values.shift if values.present?
    field[:emma_formatFeature] = values       if values.present?
    return field.keys, field.values
  end

  # Transform a data item into one or more ISSN identifiers.
  #
  # @param [*] v
  #
  # @return [String]
  #
  def media_type_values(v)
    v   = string_value(v, first: true)
    key = hash_key(v)
    (MEDIA_TYPE[key] || key).to_s
  end

  # ===========================================================================
  # :section: Import overrides
  # ===========================================================================

  protected

  # Normalize single-element arrays to scalar values and sort the fields for
  # easier comparison when reviewing/debugging.
  #
  # @param [Hash] fields
  #
  # @return [Hash]
  #
  def normalize_results(fields)

    # NOTE: Prefix to help identify this record via Unified Search
    title = Array.wrap(fields[:dc_title]).first
    title ||= Ingest::Record::IngestionRecord::MISSING_TITLE
    fields[:dc_title] = "IA_BULK - #{title}" # TODO: testing - remove

    # Correct an issue caused by "contributed_format" == "Audio" items which
    # incorrectly have "mediatype" == "texts".
    type = fields[:dc_type]
    fields[:dc_type] = type = type.first if type.is_a?(Array)

    # Provide a reasonable guess at a format if none was provided in the data.
    if fields[:dc_format].blank?
      type &&= type.to_sym
      fmt = DC_TYPE_TO_DC_FORMAT[type] || DC_TYPE_TO_DC_FORMAT[:_default]
      fields[:dc_format] = fmt = fmt.to_s
      Log.error do
        "Import::IaBulk: missing 'contributed_format' - " \
          "using #{fmt.inspect} based on mediatype #{type.inspect}"
      end
    end

    # If :rem_coverage was provided but :rem_complete wasn't, then assume that
    # this entry does *not* cover the complete work.
    if fields[:rem_coverage].present? && fields[:rem_complete].nil?
      fields[:rem_complete] = false
    end

    # Assuming that the first :dc_identifier given actually identifies the
    # associated work, move the rest into :dc_relation.
    ids = reject_blanks(Array.wrap(fields[:dc_identifier])).uniq
    if ids.size <= 1
      fields[:dc_identifier] = ids
    else
      ids_old    = ids
      isbns, ids = ids.partition { |id| id.start_with?('isbn:') }
      issns, ids = ids.partition { |id| id.start_with?('issn:') }
      dois,  ids = ids.partition { |id| id.start_with?('doi:')  }

      # Look for an ISBN that is paired with the lead ISBN.  (E.g. if the lead
      # ISBN was an ISBN-10, look for the ISBN-13 version of that number).
      lead_isbn = isbns.shift
      alt_isbn  =
        if lead_isbn && isbns.present?
          lead_value = remove_isbn_prefix(lead_isbn)
          alt_index =
            if isbn13?(lead_value)
              isbns.index { |id| lead_value == to_isbn13(id, log: false) }
            else
              isbns.index { |id| lead_value == to_isbn10(id, log: false) }
            end
          isbns.delete_at(alt_index) if alt_index
        end

      # Assign to :dc_identifier all lead values for each type, plus the
      # alternate ISBN if it was present.
      fields[:dc_identifier] =
        [ids.shift, dois.shift, issns.shift, lead_isbn, alt_isbn].compact

      if (ids += dois + issns + isbns).present?
        rel_old = Array.wrap(fields[:dc_relation]).reject(&:blank?)
        fields[:dc_relation] = (rel_old + ids).uniq
        Log.debug do
          ids_new = fields[:dc_identifier].inspect
          rel_new = fields[:dc_relation].inspect
          %w(Import::IaBulk).tap { |m|
            m << "dc_identifier = #{ids_new}; was #{ids_old.inspect}"
            m << "dc_relation = #{  rel_new}; was #{rel_old.inspect}"
          }.join(' | ')
        end
      end
    end

    # Finish with the common normalizations.
    super(fields)

  end

end

__loading_end(__FILE__)