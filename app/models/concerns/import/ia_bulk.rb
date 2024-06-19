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

  extend self

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Import schema.
  #
  # @type [
  #   Hash{Symbol=>Symbol},
  #   Hash{Symbol=>(Symbol,Symbol)},
  #   Hash{Symbol=>(Symbol,Proc)}
  # ]
  #
  # === Notes
  # - [1] Collection is always %w[emma_uploads_restricted]; this can be ignored
  #       since this is just be used internally by IA to distinguish these
  #       items.
  #
  # - [2] The name of the contributed file is always the basename of the URL in
  #       the :download field if it is present.  Otherwise it can be derived
  #       from :identifier and :contributed_file.
  #
  # - [3] Items that are only for IA internal use can be ignored since they are
  #       not relevant to EMMA metadata.
  #
  # - [4] Fields which pertain to upload into IA can be ignored because they
  #       are not relevant to EMMA metadata.
  #
  #--
  # noinspection SpellCheckingInspection
  #++
  SCHEMA = {
    #-------------------- --------------------------- -------------------------
    # Underscored name    Translator method or field  Value translator method
    #-------------------- --------------------------- -------------------------
    collection:           :skip,                      # NOTE: [1]
    contributed_file:     [:contributed_file, :string_value], # NOTE: [2]
    contributed_format:   :translate_formats,
    contributor:          [:rem_source,               :rem_source_value],
    creator:              [:dc_creator,               :values],
    date:                 [:dcterms_dateCopyright,    :year_value],
    description:          [:dc_description,           :string_value],
    doi:                  [:dc_identifier,            :doi_values],
    download:             [:file_path,                :string_value],
    format:               :skip,                      # NOTE: [3]
    free_to_download:     :skip,
    free_to_view:         :skip,
    identifier:           [:identifier, :string_value], # NOTE: [2]
    'identifier-access':  :skip,                      # NOTE: [3]
    'identifier-ark':     :skip,                      # NOTE: [3]
    imagecount:           [:rem_image_count,          :ordinal_value],
    isbn:                 [:dc_identifier,            :isbn_values],
    issn:                 [:dc_identifier,            :issn_values],
    language:             [:dc_language,              :language_values],
    lccn:                 [:dc_identifier,            :lccn_values],
    mediatype:            [:dc_type,                  :media_type_values],
    metadata_source:      [:rem_metadataSource,       :values],
    neverindex:           :skip,                      # NOTE: [3]
    noindex:              :skip,                      # NOTE: [3]
    portion:              [:rem_complete,             :rem_complete_value],
    portion_description:  [:rem_coverage,             :values],
    publicdate:           :skip,                      # NOTE: [4]
    publisher:            [:dc_publisher,             :string_value],
    remediated_aspects:   [:rem_remediatedAspects,    :rem_aspect_values],
    remediated_by:        [:rem_remediatedBy,         :values],
    remediation_comments: [:rem_comments,             :string_value],
    remediation_status:   [:rem_status,               :rem_status_value],
    scanner:              :skip,                      # NOTE: [3]
    series_type:          [:bib_seriesType,           :series_type_value],
    subject:              [:dc_subject,               :array_value],
    text_quality:         [:rem_textQuality,          :text_quality_value],
    title:                [:dc_title,                 :string_value],
    uploader:             :skip,                      # NOTE: [4]
    version:              [:emma_version,             :string_value],
    volume:               [:bib_seriesPosition,       :string_value],
  }.deep_freeze

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
    audio:                %i[daisyAudio   sound], # TODO: not daisy?
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
  # #normalize_results! will use this table to come up with a guess based on
  # 'media_type' (if it was given).
  #
  # @type [Hash{Symbol=>Symbol}]
  #
  DC_TYPE_TO_DC_FORMAT = {
    #-----------  ----------
    # :dc_type    :dc_format
    #-----------  ----------
    text:         :braille,
    sound:        :daisyAudio,
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
  def schema
    SCHEMA
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Translate a format value into one or more :emma_data fields as indicated by
  # the #FORMAT mapping.
  #
  # @param [Symbol]   _k              The name of the field being imported.
  # @param [any, nil] v
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

  # Transform a "contributor" value into a :rem_source value.
  #
  # @note This is probably no longer an appropriate mapping.
  #
  # @param [any, nil] v
  #
  # @return [String, nil]
  #
  def rem_source_value(v)
    enum_value(v, SourceType)
  end

  # Transform a "mediatype" into a :dc_format.
  #
  # @param [any, nil] v
  #
  # @return [String, nil]
  #
  def media_type_values(v)
    v = string_value(v, first: true)
    return if v.blank?
    key = hash_key(v)
    (MEDIA_TYPE[key] || key).to_s
  end

  # Transform a "portion" value into a :rem_complete value.
  #
  # @param [any, nil] v
  #
  # @return [Boolean, nil]
  #
  def rem_complete_value(v)
    v = string_value(v, first: true)
    false?(v) if v.present?
  end

  # Transform a "remediated_aspects" value into a :rem_remediatedAspects value.
  #
  # @param [any, nil] v
  #
  # @return [Array<String>]
  #
  def rem_aspect_values(v)
    enum_values(v, RemediatedAspects)
  end

  # Transform a "remediation_status" value into a :rem_status value.
  #
  # @param [any, nil] v
  #
  # @return [String, nil]
  #
  def rem_status_value(v)
    enum_value(v, RemediationStatus)
  end

  # Transform a "series_type" value into a :bib_seriesType value.
  #
  # @param [any, nil] v
  #
  # @return [String, nil]
  #
  def series_type_value(v)
    enum_value(v, SeriesType)
  end

  # Transform a "text_quality" value into a :rem_textQuality value.
  #
  # @param [any, nil] v
  #
  # @return [String, nil]
  #
  def text_quality_value(v)
    enum_value(v, TextQuality)
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
  def normalize_results!(fields)

    # If :download was not provided but :identifier and :contributed_file were
    # then construct the download link.
    unless fields[:file_path]
      path, fields = partition_hash(fields, :identifier, :contributed_file)
      if path[:identifier] && path[:contributed_file]
        fields[:file_path] = [IA_DOWNLOAD_BASE_URL, *path.values].join('/')
      else
        Log.warn do
          path.select! { |_, v| v.nil? }
          keys = [:download, *path.keys].map! { |key| "'#{key}'" }
          last = keys.pop
          keys = keys.join(', ') << " and #{last}"
          "Import::IaBulk: missing #{keys}"
        end
      end
    end

    # Correct an issue caused by "contributed_format" == "Audio" items which
    # incorrectly have "mediatype" == "texts".
    type = fields[:dc_type]
    fields[:dc_type] = type = type.first if type.is_a?(Array)

    # Provide a reasonable guess at a format if none was provided in the data.
    if fields[:dc_format].blank?
      type &&= type.to_sym
      fmt = DC_TYPE_TO_DC_FORMAT[type] || DC_TYPE_TO_DC_FORMAT[:_default]
      fields[:dc_format] = fmt = fmt.to_s
      Log.warn do
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
    ids = Array.wrap(fields[:dc_identifier]).compact_blank.uniq
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
          lead_value = Isbn.remove_prefix(lead_isbn)
          alt_index =
            if Isbn.isbn13?(lead_value)
              isbns.index { |id| lead_value == Isbn.to_isbn13(id, log: false) }
            else
              isbns.index { |id| lead_value == Isbn.to_isbn10(id, log: false) }
            end
          isbns.delete_at(alt_index) if alt_index
        end

      # Assign to :dc_identifier all lead values for each type, plus the
      # alternate ISBN if it was present.
      fields[:dc_identifier] =
        [ids.shift, dois.shift, issns.shift, lead_isbn, alt_isbn].compact

      if ids.concat(dois, issns, isbns).present?
        rel_old = Array.wrap(fields[:dc_relation]).compact_blank.presence
        fields[:dc_relation] = rel_old ? (rel_old + ids).uniq : ids
        Log.debug do
          ids_new = fields[:dc_identifier].inspect
          rel_new = fields[:dc_relation].inspect
          %w[Import::IaBulk].tap { |m|
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
