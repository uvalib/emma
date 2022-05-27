// app/assets/javascripts/feature/model-form.js


import { Rails }                                 from '../vendor/rails'
import { Emma }                                  from '../shared/assets'
import { delegateInputClick }                    from '../shared/accessibility'
import { pageController }                        from '../shared/controller'
import { selector, toggleClass }                 from '../shared/css'
import { htmlDecode, scrollIntoView }            from '../shared/html'
import { HTTP }                                  from '../shared/http'
import { consoleError, consoleLog, consoleWarn } from '../shared/logging'
import { K, asSize }                             from '../shared/math'
import { asString, camelCase, singularize }      from '../shared/strings'
import { Uploader }                              from '../shared/uploader'
import { cancelAction, makeUrl }                 from '../shared/url'
import {
    isDefined,
    isEmpty,
    isMissing,
    isPresent,
    notDefined,
} from '../shared/definitions'
import {
    debounce,
    handleClickAndKeypress,
    handleEvent,
    onPageExit,
} from '../shared/events'
import {
    clearFlash,
    extractFlashMessage,
    flashError,
    flashMessage,
} from '../shared/flash'
import {
    arrayWrap,
    compact,
    deepFreeze,
    dup,
    fromJSON,
} from '../shared/objects'
import {
    SECONDS,
    asDateTime,
    secondsSince,
    timeOf,
} from '../shared/time'


$(document).on('turbolinks:load', function() {

    /**
     * CSS class for single-entry form elements.
     *
     * @readonly
     * @type {string}
     */
    const MODEL_FORM_CLASS = 'model-form';

    /**
     * CSS class for single-entry form elements.
     *
     * @readonly
     * @type {String}
     */
    const MODEL_FORM_SELECTOR = selector(MODEL_FORM_CLASS);

    /**
     * Single-entry operation forms on the page.
     *
     * NOTE: There is no current scenario where there should be more than one
     *  of these on a given page, despite the fact that the logic (mostly)
     *  supports the concept that there could be an arbitrary number of them.
     *  (That scenario has not been tested.)
     *
     * @type {jQuery}
     */
    let $model_form = $(MODEL_FORM_SELECTOR);

    /**
     * CSS classes for bulk operation form elements.
     *
     * @readonly
     * @type {string}
     */
    const BULK_FORM_CLASS = 'bulk-op-form';

    /**
     * CSS classes for bulk operation form elements.
     *
     * @readonly
     * @type {string}
     */
    const BULK_FORM_SELECTOR = selector(BULK_FORM_CLASS);

    /**
     * Bulk operation forms on the page.
     *
     * @type {jQuery}
     */
    let $bulk_op_form = $(BULK_FORM_SELECTOR).not('.delete');

    // Only perform these actions on the appropriate pages.
    if (isMissing($model_form) && isMissing($bulk_op_form)) {
        return;
    }

    // ========================================================================
    // JSDoc type definitions
    // ========================================================================

    /**
     * Shrine upload information for the submission.
     *
     * @typedef {{
     *      filename:   string,
     *      size:       number,
     *      mime_type:  string,
     * }} FileDataMetadata
     */

    /**
     * Shrine upload information for the submission.
     *
     * @typedef {{
     *      id:         string,
     *      storage:    string,
     *      metadata:   FileDataMetadata,
     * }} FileData
     *
     * @see "en.emma.upload.record.file_data"
     * @see "Shrine::InstanceMethods#upload"
     */

    /**
     * Normally 'string[]' but may be received as 'string'.
     * 
     * @typedef {string[]|string} multiString
     */

    /**
     * Normally 'string' but may be received as 'string[]'.
     *
     * @typedef {string|string[]} singleString
     */

    /**
     * EMMA metadata for the submission.
     *
     * @typedef {{
     *      emma_recordId:                      string,
     *      emma_titleId:                       string,
     *      emma_repository:                    string,
     *      emma_collection:                    multiString,
     *      emma_repositoryRecordId:            string,
     *      emma_retrievalLink:                 string,
     *      emma_webPageLink:                   string,
     *      emma_lastRemediationDate:           string,
     *      emma_sortDate:                      string,
     *      emma_repositoryUpdateDate:          string,
     *      emma_repositoryMetadataUpdateDate:  string,
     *      emma_publicationDate:               string,
     *      emma_lastRemediationNote:           string,
     *      emma_formatVersion:                 string,
     *      emma_formatFeature:                 multiString,
     *      dc_title:                           singleString,
     *      dc_creator:                         multiString,
     *      dc_identifier:                      multiString,
     *      dc_publisher:                       singleString,
     *      dc_relation:                        multiString,
     *      dc_language:                        multiString,
     *      dc_rights:                          singleString,
     *      dc_description:                     singleString,
     *      dc_format:                          singleString,
     *      dc_type:                            singleString,
     *      dc_subject:                         multiString,
     *      dcterms_dateAccepted:               singleString,
     *      dcterms_dateCopyright:              singleString,
     *      s_accessibilityFeature:             multiString,
     *      s_accessibilityControl:             multiString,
     *      s_accessibilityHazard:              multiString,
     *      s_accessMode:                       multiString,
     *      s_accessModeSufficient:             multiString,
     *      s_accessibilitySummary:             singleString,
     *      rem_source:                         singleString,
     *      rem_metadataSource:                 multiString,
     *      rem_remediatedBy:                   multiString,
     *      rem_complete:                       boolean,
     *      rem_coverage:                       singleString,
     *      rem_remediation:                    multiString,
     *      rem_remediatedAspects:              multiString,
     *      rem_textQuality:                    singleString,
     *      rem_quality:                        singleString,
     *      rem_status:                         singleString,
     *      rem_remediationDate:                singleString,
     *      rem_comments:                       singleString,
     *      rem_remediationComments:            singleString,
     *      bib_series:                         singleString,
     *      bib_seriesType:                     singleString,
     *      bib_seriesPosition:                 singleString,
     * }} EmmaData
     *
     * @see "en.emma.entry.record.emma_data"
     * @see "AwsS3::Record::SubmissionRequest"
     */

    /**
     * RecordMessageProperties
     *
     * - list_type: only present with session_debug
     * - item_type: only present with session_debug
     *
     * @typedef {{
     *      total:      number,
     *      limit:      number|null|undefined,
     *      links:      array|null|undefined,
     *      list_type?: string|null|undefined,
     *      item_type?: string|null|undefined,
     * }} RecordMessageProperties
     */

    /**
     * A complete submission database record.
     *
     * @typedef {{
     *      id:             number,
     *      file_data:      FileData,
     *      emma_data:      EmmaData,
     *      user_id:        number,
     *      repository:     string,
     *      submission_id:  string,
     *      fmt:            string,
     *      ext:            string,
     *      state:          string,
     *      created_at:     string,
     *      updated_at:     string,
     *      phase:          string,
     *      edit_state:     string,
     *      edit_user:      string,
     *      edit_file_data: FileData,
     *      edit_emma_data: EmmaData,
     *      edited_at:      string,
     *      review_user:    string,
     *      review_success: string,
     *      review_comment: string,
     *      reviewed_at:    string,
     * }} UploadRecord
     *
     * @see "en.emma.upload.record"
     */

    /**
     * A complete submission database record.
     *
     * @typedef {{
     *      id:             number,
     *      file_data:      FileData,
     *      emma_data:      EmmaData,
     *      user_id:        number,
     *      repository:     string,
     *      submission_id:  string,
     *      fmt:            string,
     *      ext:            string,
     *      created_at:     string,
     *      updated_at:     string,
     * }} EntryRecord
     *
     * @see "en.emma.entry.record"
     */

    /**
     * @typedef {UploadRecord|EntryRecord} SubmissionRecord
     */

    /**
     * @typedef {UploadRecord[]|EntryRecord[]} SubmissionRecords
     */

    /**
     * JSON format of a response message containing a list of submissions.
     *
     * @typedef {{
     *      entries: {
     *          properties: RecordMessageProperties,
     *          list:       UploadRecord[],
     *      }
     * }} UploadRecordMessage
     */

    /**
     * JSON format of a response message containing a list of submissions.
     *
     * @typedef {{
     *      entries: {
     *          properties: RecordMessageProperties,
     *          list:       EntryRecord[],
     *      }
     * }} EntryRecordMessage
     */

    /**
     * SubmissionRecordMessage
     *
     * @typedef {
     *      UploadRecordMessage | EntryRecordMessage
     * } SubmissionRecordMessage
     */

    /**
     * SubmissionRecordsCB
     *
     * @typedef {
     *      function(UploadRecord[]) | function(EntryRecord[])
     * } SubmissionRecordsCB
     */

    /**
     * A single search result entry.
     *
     * @typedef {{
     *      emma_recordId:                      string,
     *      emma_titleId:                       string,
     *      emma_repository:                    string,
     *      emma_collection:                    string[],
     *      emma_repositoryRecordId:            string,
     *      emma_retrievalLink:                 string,
     *      emma_webPageLink:                   string,
     *      emma_lastRemediationDate?:          string,
     *      emma_sortDate?:                     string,
     *      emma_repositoryUpdateDate?:         string,
     *      emma_repositoryMetadataUpdateDate?: string,
     *      emma_publicationDate?:              string,
     *      emma_lastRemediationNote?:          string,
     *      emma_version?:                      string,
     *      emma_formatVersion:                 string,
     *      emma_formatFeature?:                string[],
     *      dc_title:                           string,
     *      dc_creator?:                        string[],
     *      dc_identifier?:                     string[],
     *      dc_relation?:                       string[],
     *      dc_publisher?:                      string,
     *      dc_language?:                       string[],
     *      dc_rights?:                         string,
     *      dc_description?:                    string,
     *      dc_format?:                         string,
     *      dc_type?:                           string,
     *      dc_subject?:                        string[],
     *      dcterms_dateAccepted?:              string,
     *      dcterms_dateCopyright?:             string,
     *      s_accessibilityFeature?:            string[],
     *      s_accessibilityControl?:            string[],
     *      s_accessibilityHazard?:             string[],
     *      s_accessibilitySummary?:            string,
     *      s_accessMode?:                      string[],
     *      s_accessModeSufficient?:            string[],
     *      rem_source?:                        string,
     *      rem_metadataSource?:                string[],
     *      rem_remediatedBy?:                  string[],
     *      rem_complete?:                      boolean,
     *      rem_coverage?:                      string,
     *      rem_remediatedAspects?:             string[],
     *      rem_textQuality?:                   string,
     *      rem_quality?:                       string,
     *      rem_status?:                        string,
     *      rem_remediationDate?:               string,
     *      rem_comments?:                      string,
     *      rem_remediationComments?:           string,
     * }} SearchResultEntry
     *
     * @see file:config/locales/records/search.en.yml "en.emma.search.record"
     */

    /**
     * JSON format of a response message containing a list of search results.
     *
     * @typedef {{
     *      response: {
     *          properties: RecordMessageProperties,
     *          records:    SearchResultEntry[],
     *      }
     * }} SearchResultMessage
     */

    /**
     * Field relationship.
     *
     * @typedef {{
     *      name:           string,
     *      required?:       boolean|function,
     *      unrequired?:     boolean|function,
     *      required_val?:   string,
     *      unrequired_val?: string,
     * }} Relationship
     */

    // ========================================================================
    // Constants
    // ========================================================================

    /**
     * Flag controlling overall console debug output.
     *
     * @readonly
     * @type {boolean|undefined}
     */
    const DEBUGGING = true;

    /**
     * Flags controlling console debug output for specific purposes.
     *
     * @readonly
     * @type {{INPUT: boolean, XHR: boolean, UPLOAD: boolean, SUBMIT: boolean}}
     */
    const DEBUG = (DEBUGGING === false) ? {} : {
        INPUT:  false,  // Log low-level keystrokes
        SUBMIT: true,   // Submission
        UPLOAD: true,   // File upload
        XHR:    true,   // External communication
    };

    /**
     * Uppy plugin selection plus other optional settings.
     *
     * @readonly
     * @type {UppyFeatures}
     */
    const FEATURES = deepFreeze({
        flash_messages: true,
        flash_errors:   true,
        debugging:      DEBUG.UPLOAD
    });

    /**
     * How long to wait after the user enters characters into a field before
     * re-validating the form.
     *
     * @readonly
     * @type {number}
     *
     * @see monitorInputFields
     */
    const DEBOUNCE_DELAY = 500; // milliseconds

    /**
     * Current controller.
     *
     * @readonly
     * @type {string}
     */
    const CONTROLLER = pageController();

    /**
     * Base name (singular of the related database table).
     *
     * @readonly
     * @type {string}
     */
    const MODEL = singularize(CONTROLLER);

    /**
     * Page assets.js properties.
     *
     * @readonly
     * @type {ModelProperties}
     */
    const PROPERTIES = Emma[camelCase(MODEL)];

    /**
     * The value used to denote that a database field has been intentionally
     * left blank.
     *
     * @readonly
     * @type {string}
     */
    const EMPTY_VALUE = PROPERTIES.Field.empty;

    /**
     * Generic form selector.
     *
     * @readonly
     * @type {string}
     */
    const FORM_SELECTOR = MODEL_FORM_SELECTOR + ',' + BULK_FORM_SELECTOR;

    /**
     * Selectors for input fields.
     *
     * @readonly
     * @type {string[]}
     */
    const FORM_FIELD_TYPES = deepFreeze([
        'select',
        'textarea',
        'input[type="checkbox"]',
        'input[type="date"]',
        'input[type="datetime-local"]',
        'input[type="email"]',
        'input[type="month"]',
        'input[type="number"]',
        'input[type="password"]',
        'input[type="range"]',
        'input[type="tel"]',
        'input[type="text"]',
        'input[type="time"]',
        'input[type="url"]',
        'input[type="week"]',
    ]);

    /**
     * Selector for input fields.
     *
     * @readonly
     * @type {string}
     */
    const FORM_FIELD_SELECTOR = FORM_FIELD_TYPES.join(', ');

    /**
     * Interrelated elements.  For example:
     *
     * If "rem_complete" is set to "true", then "rem_coverage" is no longer
     * required.  Conversely, if "rem_coverage" is given a value then that
     * implies that "rem_complete" is "false".
     *
     * @readonly
     * @type {Object<Relationship>}
     */
    const FIELD_RELATIONSHIP = deepFreeze({
        rem_complete: {
            name:           'rem_coverage',
            required:       (el) => ($(el).val() !== 'true'),
            unrequired_val: ''
        },
        rem_coverage: {
            name:           'rem_complete',
            required:       (el) => isMissing($(el).val()),
            required_val:   '',
            unrequired_val: 'false'
        },
        password: {
            name:           'password_confirmation',
            required:       (el) => $(el).hasClass('valid'),
        }
    });

    /**
     * State of the page.
     *
     * SUBMITTING:  The submit button has been activated.
     * SUBMITTED:   The submission has been completed.
     * CANCELED:    The cancel button has been activated.
     *
     * @readonly
     * @type {Object<string>}
     */
    const FORM_STATE = deepFreeze({
        SUBMITTING: 'submitting',
        SUBMITTED:  'submitted',
        CANCELED:   'canceled'
    });

    // ========================================================================
    // Constants - field validation
    // ========================================================================

    /**
     * Remote identifier validation.
     *
     * @readonly
     * @type {string}
     */
    const ID_VALIDATE_URL_BASE = '/search/validate?identifier=';

    /**
     * Validation methods table.
     *
     * @readonly
     * @type {Object<boolean|string|function(string|string[]):boolean>}
     */
    const FIELD_VALIDATION = deepFreeze({
        dc_identifier: ID_VALIDATE_URL_BASE,
        dc_relation:   ID_VALIDATE_URL_BASE,
    });

    // ========================================================================
    // Constants - Bulk operations
    // ========================================================================

    /**
     * Selector for the dynamic bulk operation results panel.
     *
     * @readonly
     * @type {string}
     */
    const BULK_OP_RESULTS_SELECTOR = '.bulk-op-results';

    /**
     * Item name for sessionStorage of a trace of bulk operation activity.
     *
     * @readonly
     * @type {string}
     */
    const BULK_OP_STORAGE_KEY = 'bulk-operation';

    /**
     * CSS class indicating that the bulk operation results panel contains the
     * results of the previous run (from sessionStorage), not the current run.
     *
     * @readonly
     * @type {string}
     */
    const OLD_DATA_MARKER = 'previous';

    /**
     * CSS selector indicating that the bulk operation results panel contains
     * the results of the previous run (from sessionStorage), not the current
     * run.
     *
     * @readonly
     * @type {string}
     */
    const OLD_DATA = '.' + OLD_DATA_MARKER;

    /**
     * Interval for checking the contents of the model database table.
     *
     * @readonly
     * @type {number}
     */
    const BULK_CHECK_PERIOD = 10 * SECONDS;

    /**
     * Indicator that a results line is filler displayed prior to detecting the
     * first added database entry.
     *
     * @readonly
     * @type {string}
     */
    const TMP_LINE_CLASS = 'start';

    /**
     * Filler displayed prior to detecting the first added database entry.
     *
     * @readonly
     * @type {string}
     */
    const TMP_LINE = 'Uploading...'; // TODO: I18n

    // ========================================================================
    // Actions
    // ========================================================================

    // Setup Uppy for any <input type="file"> elements (unless this page is
    // being reached via browser history).
    $model_form.each(function() {
        let $form = $(this);

        // Setup file uploader (if applicable).
        initializeFileUploader($form);

        // noinspection JSDeprecatedSymbols
        switch (performance.navigation.type) {
            case PerformanceNavigation.TYPE_BACK_FORWARD:
                debugSection('HISTORY BACK/FORWARD');
                refreshRecord($form);
                break;
            case PerformanceNavigation.TYPE_RELOAD:
                debugSection('PAGE REFRESH');
                // TODO: this causes a junk record to be created for /new.
                refreshRecord($form);
                break;
            default:
                initializeModelForm($form);
                break;
        }
    });

    // Setup handlers for bulk operation pages.
    $bulk_op_form.each(function() {
        initializeBulkOpForm(this);
    });

    // ========================================================================
    // Functions - Uploader
    // ========================================================================

    // noinspection ES6ConvertVarToLetConst
    /**
     * @type {Uploader|undefined}
     */
    var uploader;

    /**
     * Indicate whether the form requires file uploading capability.
     *
     * @param {Selector} [form]       Default: {@link formElement}.
     *
     * @returns {boolean}
     *
     * @see "BaseDecorator::Form#model_form"
     */
    function isFileUploader(form) {
        return formElement(form).hasClass('file-uploader');
    }

    /**
     * Initialize the file uploader if the form requires it.
     *
     * @param {Selector} form
     *
     * @returns {Uploader|undefined}
     */
    function initializeFileUploader(form) {
        let $form = $(form);
        if (!uploader && isFileUploader($form)) {
            uploader = newUploader($form);
        }
        return uploader;
    }

    /**
     * Create a new uploader instance.
     *
     * @param {Selector} form
     *
     * @returns {Uploader}
     */
    function newUploader(form) {
        let $form = $(form);
        const state = {
            new:    isCreateForm($form),
            edit:   isUpdateForm($form),
            bulk:   isBulkOpForm($form),
        };
        const callbacks = {
            onSelect:   onSelect,
            onStart:    onStart,
            onError:    onError,
            onSuccess:  onSuccess,
        };
        let instance = new Uploader($form, MODEL, FEATURES, state, callbacks);
        return instance.initialize();

        /**
         * Callback invoked when the file select button is pressed.
         *
         * @param {jQuery.Event} [event]    Ignored.
         */
        function onSelect(event) {
            clearFlash();
        }

        /**
         * This event occurs between the 'file-added' and 'upload-started'
         * events.
         *
         * The current value of the submission's database ID applied to the
         * upload endpoint URL in order to correlate the upload with the
         * appropriate workflow.
         *
         * @param {{id: string, fileIDs: string[]}} data
         *
         * @returns {object}          URL parameters for the remote endpoint.
         */
        function onStart(data) {
            clearFlash();
            return submissionParams($form);
        }

        /**
         * This event occurs when the response from POST /entry/endpoint is
         * received with success status (200).  At this point, the file has
         * been uploaded by Shrine, but has not yet been validated.
         *
         * @param {Uppy.UppyFile}         file
         * @param {ShrineResponseMessage} response
         *
         * @see "Shrine::UploadEndpointExt#make_response"
         *
         * == Implementation Notes
         * The normal Shrine response has been augmented to include an
         * 'emma_data' object in addition to the fields associated with
         * 'file_data'.
         */
        function onSuccess(file, response) {

            let body = response.body || {};

            // Save uploaded EMMA metadata.
            /** @type {EmmaDataOrError} */
            let emma_data = body.emma_data || {};
            if (isPresent(emma_data)) {
                emma_data = compact(emma_data);
                let $emma_data = emmaDataElement($form);
                if (isPresent($emma_data)) {
                    $emma_data.val(asString(emma_data));
                }
                delete body.emma_data;
            }

            // Set hidden field value to the uploaded file data so that it is
            // submitted with the form as the attachment.
            /** @type {FileData} */
            const file_data = body;
            if (file_data) {
                let $file_data = fileDataElement($form);
                if (isPresent($file_data)) {
                    $file_data.val(asString(file_data));
                }
                if (!emma_data.dc_format) {
                    const meta = file_data.metadata;
                    const mime = meta?.mime_type;
                    const fmt  = PROPERTIES.Mime.to_fmt[mime] || [];
                    if (fmt[0]) { emma_data.dc_format = fmt[0]; }
                }
            }

            if (emma_data.error) {

                // If there was a problem with the uploaded file (e.g. not an
                // expected file type) it will be reported here.
                showFlashError(emma_data.error);

            } else {

                // Display the name of the provisionally uploaded file.
                //
                instance.displayUploadedFilename(file_data);

                // Disable the file select button.
                //
                // The 'cancel' button is used to select a different file
                // because previous metadata (manually or automatically
                // acquired) may no longer be appropriate.
                //
                instance.disableFileSelectButton();

                // Update form fields with the transmitted EMMA data.
                //
                // When the form is submitted these values should take
                // precedence over the original values which will be
                // retransmitted the hidden '#entry_emma_data' field.
                //
                populateFormFields(emma_data, $form) || validateForm($form);
            }
        }

        /**
         * This event occurs when the response from POST /entry/endpoint is
         * received with a failure status (4xx).
         *
         * @param {Uppy.UppyFile}                  file
         * @param {Error}                          error
         * @param {{status: number, body: string}} [response]
         */
        function onError(file, error, response) {
            showFlashError(error?.message || error);
            requireFormCancellation($form);
        }
    }

    // ========================================================================
    // Functions - Bulk operations
    // ========================================================================

    /**
     * Initialize form display and event handlers for bulk operations.
     *
     * @param {Selector} form
     */
    function initializeBulkOpForm(form) {

        let $form = $(form);

        // Setup file uploader (if applicable).
        initializeFileUploader($form);

        // Setup buttons.
        setupSubmitButton($form);
        setupCancelButton($form);

        // Start with submit disabled until a bulk control file is supplied.
        disableSubmit($form);

        // Show the results of the most recent bulk operation (if available).
        let $results = bulkOpResults().empty().addClass(OLD_DATA_MARKER);
        let previous = getBulkOpTrace();
        if (previous && showBulkOpResults($results, previous)) {
            $results.removeClass('hidden');
            bulkOpResultsLabel($results).removeClass('hidden');
        }

        // When the bulk manifest is submitted, begin a running tally of
        // the items that have been added/changed.
        handleEvent($form, 'submit', monitorBulkOperation);

        // When a file has been selected, display its name and enable submit.
        if (uploader) {

            handleEvent(uploader.fileSelectInput(), 'change', setBulkFilename);

            /**
             * Update the form after the bulk control file is selected.
             *
             * @param {jQuery.Event} event
             */
            function setBulkFilename(event) {
                const filename = ((event.target.files || [])[0] || {}).name;
                if (uploader.displayFilename(filename)) {
                    uploader.fileSelectButton().removeClass('best-choice');
                    enableSubmit($form);
                }
            }
        }
    }

    /**
     * Indicate whether this is a bulk operation form.
     *
     * @param {Selector} [form]       Default: {@link formElement}.
     *
     * @returns {boolean}
     */
    function isBulkOpForm(form) {
        return formElement(form).hasClass('bulk');
    }

    // ========================================================================
    // Functions - Bulk form submission
    // ========================================================================

    /**
     * The element containing the bulk operation results.
     *
     * Currently there can only be one bulk operation results element per page.
     * TODO: Associate results element with a specific bulk-action form.
     *
     * @param {Selector} [results]
     *
     * @returns {jQuery}
     */
    function bulkOpResults(results) {
        const selector = BULK_OP_RESULTS_SELECTOR;
        let $results   = $(results);
        return $results.is(selector) ? $results : $(selector);
    }

    /**
     * The element displayed above bulk operation results.
     *
     * @param {Selector} [results]
     *
     * @returns {jQuery}
     *
     * @see file:stylesheets/feature/_model_form.scss .bulk-op-results-label
     */
    function bulkOpResultsLabel(results) {
        let $results = bulkOpResults(results);
        const lbl_id = $results.attr('aria-labelledby');
        return lbl_id ? $('#' + lbl_id) : $();
    }

    /**
     * The first database ID to monitor for results, defaulting to "1".
     *
     * If *record* is given, the first database ID is set to be the one which
     * succeeds it.
     *
     * @param {Selector}                [results]
     * @param {SubmissionRecord|number} [record]   The current max database ID.
     *
     * @returns {string}
     */
    function bulkOpResultsNextId(results, record) {
        const name    = 'next-id';
        let $results  = bulkOpResults(results);
        let value     = $results.data(name);
        const initial = isMissing(value);
        if (initial || isDefined(record)) {
            value = (typeof record === 'object') ? record.id : record;
            value = (Number(value) || 0) + 1;
            $results.data(name, value);
        }
        if ((value > 1) && !$results.data('first-id')) {
            $results.data('first-id', value);
        }
        return value.toString();
    }

    /**
     * Time the download was started.
     *
     * The first call sets the time.  If *start_time* is provided, it resets
     * the start time to the given value.
     *
     * @param {Selector}    [results]
     * @param {Date|number} [start_time]
     *
     * @returns {number}
     */
    function bulkOpResultsStartTime(results, start_time) {
        const name   = 'start-time';
        let $results = bulkOpResults(results);
        let value    = $results.data(name);
        if (isPresent(start_time) || isMissing(value)) {
            value = timeOf(start_time);
            $results.data(name, value);
        }
        return value;
    }

    /**
     * Setup the element which shows intermediate results during a bulk upload.
     *
     * @param {jQuery.Event} [event]
     */
    function monitorBulkOperation(event) {
        const target = event?.currentTarget || event?.target;
        let $form    = target ? $(target) : $bulk_op_form;
        disableSubmit($form);
        uploader?.disableFileSelectButton();

        let $results = bulkOpResults();
        let $label   = bulkOpResultsLabel($results);
        $results.removeClass(OLD_DATA_MARKER).empty();
        addBulkOpResult($results, TMP_LINE, TMP_LINE_CLASS);
        $label.text('Upload results:').removeClass('hidden'); // TODO: I18n
        $results.removeClass('hidden');

        clearBulkOpTrace();
        fetchEntryList('$', null, startMonitoring);

        /**
         * Establish the lower-bound of database ID's to search (starting with
         * the first ID after the current latest ID) then schedule an update.
         *
         * @param {SubmissionRecords} list
         */
        function startMonitoring(list) {
            const record = list.slice(-1)[0] || {};
            bulkOpResultsNextId($results, record);
            bulkOpResultsStartTime($results);
            scheduleCheckBulkOpResults($results);
        }
    }

    /**
     * If still appropriate, schedule another round of checking the "update"
     * table.
     *
     * @param {Selector} results
     * @param {number}   [milliseconds]
     */
    function scheduleCheckBulkOpResults(results, milliseconds) {
        let $results = bulkOpResults(results);
        const period = milliseconds || BULK_CHECK_PERIOD;
        const name   = 'check-period';
        const timer  = $results.data(name);
        if (isPresent(timer)) {
            clearTimeout(timer);
        }
        if ($results.not(OLD_DATA).is(':visible')) {
            const new_timer = setTimeout(checkBulkOpResults, period);
            $results.data(name, new_timer);
        }
    }

    /**
     * Display new entries that have appeared since the last check.
     */
    function checkBulkOpResults() {
        let $results = bulkOpResults();
        if ($results.is(OLD_DATA)) {
            return;
        }
        const start_id = bulkOpResultsNextId($results);
        fetchEntryList(start_id, '$', addNewLines);

        /**
         * Add lines for any entries that have appeared since the last round
         * then schedule a new round.
         *
         * @param {SubmissionRecords} list
         */
        function addNewLines(list) {
            if (isPresent(list)) {
                /** @type {jQuery} */
                let $lines = $results.children();

                // Remove initialization line(s) if present.
                $lines.filter('.' + TMP_LINE_CLASS).remove();

                // Add a line for each record.
                let last_id = 0;
                let row     = $lines.length;
                let entries = [];
                list.forEach(function(record) {
                    const entry = addBulkOpResult($results, record, row++);
                    last_id = Math.max(record.id, last_id);
                    entries.push(entry);
                });
                addBulkOpTrace(entries);

                // Update the next ID to fetch.
                if (last_id) {
                    bulkOpResultsNextId($results, last_id);
                }
            }
            scheduleCheckBulkOpResults($results);
        }
    }

    /**
     * Add a line to bulk operation results.
     *
     * @param {Selector}                       results
     * @param {SubmissionRecord|object|string} entry
     * @param {number|string}                  [index]
     * @param {Date|number}                    [time]
     *
     * @returns {string}              The added result entry.
     *
     * @see file:stylesheets/feature/_model_form.scss .bulk-op-results
     */
    function addBulkOpResult(results, entry, index, time) {
        let $results = bulkOpResults(results);
        let data;
        if (typeof entry !== 'object') {
            data = entry.toString();
        } else if (isMissing(entry.submission_id)) {
            // A generic object.
            data = asString(entry, (K / 2));
        } else {
            // An object which is a de-serialized Entry record.
            const start = bulkOpResultsStartTime($results);
            const date  = time            || new Date();
            const fd    = entry.file_data || {};
            const md    = fd.metadata     || {};
            const file  = md.filename;
            data = {
                date: asDateTime(date),
                time: secondsSince(start, date).toFixed(1),
                id:   (entry.id            || '(missing)'),
                sid:  (entry.submission_id || '(missing)'),
                size: (asSize(md.size)     || '(missing)'),
                file: (file && `"${file}"` || '(missing)')
            };
        }
        let $line = makeBulkOpResult(data, index);
        $line.appendTo($results);
        scrollIntoView($line);
        return (typeof data === 'string') ? data : asString(data);
    }

    /**
     * Generate a line for inclusion in the bulk operation results element.
     *
     * @param {object|string} entry
     * @param {number|string} [index]
     *
     * @returns {jQuery}
     */
    function makeBulkOpResult(entry, index) {
        const func = 'makeBulkOpResult';
        let $line  = $('<div>');

        // CSS classes for the new line.
        let row = (typeof index === 'number') ? `row-${index}` : (index || '');
        if (!row.includes('line')) {
            row = `line ${row}`.trim();
        }
        $line.addClass(row);

        // Content for the new line.
        let text, html = '';
        if (typeof entry === 'object') {
            $.each(entry, function(k, v) {
                html += `<span class="label ${k}">${k}</span> `;
                html += `<span class="value ${k}">${v}</span>\n`;
            });
        } else if (typeof entry === 'string') {
            text = entry;
        } else {
            console.error(`${func}: ${typeof entry} invalid`);
        }
        if (html) {
            $line.html(html);
        } else if (text) {
            $line.text(text);
        }
        return $line;
    }

    /**
     * Display previous bulk operation results.
     *
     * @param {Selector} results
     * @param {string}   [data]       Default: {@link getBulkOpTrace}.
     *
     * @returns {number}              Number of entries to be shown.
     */
    function showBulkOpResults(results, data) {
        let $results = bulkOpResults(results);
        let entries  = data || getBulkOpTrace();
        if (entries && !entries.startsWith('[')) {
            entries  = `[${entries}]`;
        }
        const list = entries && fromJSON(entries) || [];
        $.each(list, function(row, record) {
            makeBulkOpResult(record, (row + 1)).appendTo($results);
        });
        return list.length;
    }

    /**
     * Get a sequence of EMMA entries.
     *
     * @param {string|number|null}  min
     * @param {string|number|null}  max
     * @param {SubmissionRecordsCB} callback
     */
    function fetchEntryList(min, max, callback) {

        const func = 'fetchEntryList';
        let range;
        if (min && max) { range = `${min}-${max}`; }
        else if (max)   { range = `1-${max}`; }
        else if (min)   { range = `${min}`; }
        else            { range = '*'; }
        const base = `${PROPERTIES.Path.index}.json`;
        const url  = makeUrl(base, { selected: range });

        debugXhr(`${func}: VIA`, url);

        /** @type {SubmissionRecords} */
        let records;
        let warning, error;
        const start = Date.now();

        $.ajax({
            url:      url,
            type:     'GET',
            dataType: 'json',
            success:  onSuccess,
            error:    onError,
            complete: onComplete
        });

        /**
         * Extract the list of EMMA entries returned as JSON.
         *
         * @param {object}         data
         * @param {string}         status
         * @param {XMLHttpRequest} xhr
         */
        function onSuccess(data, status, xhr) {
            // debugXhr(`${func}: received`, (data?.length || 0), 'bytes.');
            if (isMissing(data)) {
                error = 'no data';
            } else if (typeof(data) !== 'object') {
                error = `unexpected data type ${typeof data}`;
            } else {
                // The actual data may be inside '{ "response" : { ... } }'.
                /** @type {SubmissionRecordMessage} */
                const message = data.response   || data;
                const entries = message.entries || {};
                records       = entries.list    || [];
            }
        }

        /**
         * Accumulate the status failure message.
         *
         * @param {XMLHttpRequest} xhr
         * @param {string}         status
         * @param {string}         message
         */
        function onError(xhr, status, message) {
            const failure = `${status}: ${xhr.status} ${message}`;
            if (transientError(xhr.status)) {
                warning = failure;
            } else {
                error   = failure;
            }
        }

        /**
         * Actions after the request is completed.  If there was no error, the
         * list of extracted entries is passed to the callback function.
         *
         * @param {XMLHttpRequest} xhr
         * @param {string}         status
         */
        function onComplete(xhr, status) {
            debugXhr(`${func}: complete`, secondsSince(start), 'sec.');
            if (records) {
                callback(records);
            } else if (warning) {
                consoleWarn(`${func}: ${url}: ${warning}`);
                callback([]);
            } else {
                const failure = error || 'unknown failure';
                consoleError(`${func}: ${url}: ${failure} - aborting`);
            }
        }
    }

    // ========================================================================
    // Functions - Bulk session storage
    // ========================================================================

    /**
     * Get stored value.
     *
     * @param {string} [name]         Default: {@link BULK_OP_STORAGE_KEY}.
     *
     * @returns {string}
     */
    function getBulkOpTrace(name) {
        const key = name || BULK_OP_STORAGE_KEY;
        return sessionStorage.getItem(key) || '';
    }

    /**
     * Clear stored value.
     *
     * @param {string} [name]         Passed to {@link setBulkOpTrace}.
     *
     * @returns {string}              New stored value.
     */
    function clearBulkOpTrace(name) {
        return setBulkOpTrace('', name, false);
    }

    /**
     * Add to stored value.
     *
     * @param {string|string[]|object} value
     * @param {string}                 [name]   To {@link setBulkOpTrace}.
     *
     * @returns {string}                        New stored value.
     */
    function addBulkOpTrace(value, name) {
        return setBulkOpTrace(value, name, true);
    }

    /**
     * Set stored value.
     *
     * @param {string|object|string[]|object[]} value
     * @param {string}  [name]        Def: {@link BULK_OP_STORAGE_KEY}.
     * @param {boolean} [append]      If *true* append to current
     *
     * @returns {string}              New stored value.
     */
    function setBulkOpTrace(value, name, append) {
        const key = name || BULK_OP_STORAGE_KEY;
        let entry = append && getBulkOpTrace(key) || '';
        if (isPresent(value)) {
            let trace = (v) => (typeof v === 'string') ? v : asString(v);
            let parts = arrayWrap(value).map(v => trace(v));
            if (entry) {
                parts.unshift(entry);
            }
            entry = parts.join(', ');
        }
        sessionStorage.setItem(key, entry);
        return entry;
    }

    // ========================================================================
    // Functions - Initialization
    // ========================================================================

    /**
     * Call the server endpoint to acquire replacement form field values.
     *
     * If this is a create form, then a new Upload record is generated to make
     * up for the fact that previously clicking away from the page resulted in
     * the original partial Upload record being deleted.
     *
     * If this is an update form, then the appropriate field values are
     * generated to put the Upload record in the initial workflow edit state.
     *
     * In either case, {@link initializeModelForm} is called with the new
     * fields to complete page initialization.
     *
     * @param {Selector} [form]       Default: {@link formElement}.
     */
    function refreshRecord(form) {

        const func = 'refreshRecord';
        let $form  = formElement(form);
        let url;
        if (isCreateForm($form)) {
            url = PROPERTIES.Path.renew;
        } else {
            url = makeUrl(PROPERTIES.Path.reedit, submissionParams($form));
        }

        /** @type {SubmissionRecord} */
        let record  = undefined;
        let warning, error;
        const start = Date.now();

        $.ajax({
            url:      url,
            type:     'POST',
            dataType: 'json',
            headers:  { 'X-CSRF-Token': Rails.csrfToken() },
            async:    false,
            success:  onSuccess,
            error:    onError,
            complete: onComplete
        });

        /**
         * Extract the replacement Upload fields returned as JSON.
         *
         * @param {object}         data
         * @param {string}         status
         * @param {XMLHttpRequest} xhr
         */
        function onSuccess(data, status, xhr) {
            // debugXhr(`${func}: received`, (data?.length || 0), 'bytes.');
            if (isMissing(data)) {
                error = 'no data';
            } else if (typeof(data) !== 'object') {
                error = `unexpected data type ${typeof data}`;
            } else {
                // The actual data may be inside '{ "response" : { ... } }'.
                record = data.response || data;
            }
        }

        /**
         * Accumulate the status failure message.
         *
         * @param {XMLHttpRequest} xhr
         * @param {string}         status
         * @param {string}         message
         */
        function onError(xhr, status, message) {
            const failure = `${status}: ${xhr.status} ${message}`;
            if (transientError(xhr.status)) {
                warning = failure;
            } else {
                error   = failure;
            }
        }

        /**
         * Actions after the request is completed.  If valid record data was
         * acquired it will be used in place of the field values that are
         * currently in the DOM tree.  If not, the initialize method is still
         * called (just without replacement values).  It remains to be seen
         * whether this is better than indicating a failure.
         *
         * @param {XMLHttpRequest} xhr
         * @param {string}         status
         */
        function onComplete(xhr, status) {
            debugXhr(`${func}: complete`, secondsSince(start), 'sec.');
            if (record) {
                // debugXhr(`${func}: data from server:`, record);
            } else if (warning) {
                consoleWarn(`${func}: ${url}:`, warning);
            } else {
                consoleError(`${func}: ${url}:`, (error || 'unknown failure'));
            }
            initializeModelForm($form, record);
        }
    }

    /**
     * Initialize form display and event handlers.
     *
     * @param {Selector}      form
     * @param {string|object} [start_data]  Replacement data.
     */
    function initializeModelForm(form, start_data) {

        let $form = $(form);

        // Setup buttons.
        setupSubmitButton($form);
        setupCancelButton($form);

        // Prevent password managers from incorrectly interpreting any of the
        // fields as something that might pertain to user information.
        inputFields($form).each(function() { turnOffAutocomplete(this); });

        // Broaden click targets for radio buttons and checkboxes that are
        // paired with labels.
        let $filter_panel = fieldDisplayFilterContainer($form);
        $filter_panel.children('.radio, .control').each(function() {
            delegateInputClick(this);
        });
        $form.find('.checkbox.single').each(function() {
            delegateInputClick(this);
        });

        // Ensure that required fields are indicated.
        initializeFormFields($form, start_data);
        monitorInputFields($form);

        // Intercept the "Source Repository" menu selection.
        monitorSourceRepository($form);

        // Set initial field filtering and setup field display filter controls.
        monitorFieldDisplayFilterButtons($form);
        fieldDisplayFilterSelect($form);

        // Intercept form submission so that it can be handled via AJAX in
        // order to retrieve information sent back from the server via headers.
        monitorRequestResponse($form);

        // Cancel the current submission if the the user leaves the page before
        // submitting.
        onPageExit(function() { abortSubmission($form) }, DEBUGGING);
    }

    /**
     * Initialize the state of the submit button.
     *
     * @param {Selector} [form]       Default: {@link formElement}.
     */
    function setupSubmitButton(form) {
        let $form   = formElement(form);
        const label = submitLabel($form);
        const tip   = submitTooltip($form);
        let $button = submitButton($form).attr('title', tip).text(label);
        handleClickAndKeypress($button, clearFlashMessages);
        handleClickAndKeypress($button, startSubmission);
    }

    /**
     * Initialize the state of the cancel button, and set it up to clear the
     * form when it is activated.
     *
     * @param {Selector} [form]       Default: {@link formElement}.
     *
     * == Implementation Notes
     * Although the button is created with 'type="reset"' HTML reset behavior
     * is not relied upon because it only clears form fields but not file data.
     */
    function setupCancelButton(form) {
        let $form   = formElement(form);
        const label = cancelLabel($form);
        const tip   = cancelTooltip($form);
        let $button = cancelButton($form).attr('title', tip).text(label);
        handleClickAndKeypress($button, clearFlashMessages);
        handleClickAndKeypress($button, cancelSubmission);
    }

    /**
     * Adjust an input element to prevent password managers from interpreting
     * certain fields like "Title" as ones that they should offer to
     * autocomplete (unless the field has been explicitly rendered with
     * autocomplete turned on).
     *
     * @param {Selector} element
     */
    function turnOffAutocomplete(element) {
        let $element = $(element);
        if ($element[0] instanceof HTMLInputElement) {
            let autocomplete = $element.attr('autocomplete');
            let last_pass    = $element.attr('data-lpignore');
            if (isMissing(autocomplete)) {
                $element.attr('autocomplete', (autocomplete = 'off'));
            }
            if (isMissing(last_pass) && (autocomplete === 'off')) {
                $element.attr('data-lpignore', 'true'); // Needed for LastPass.
            }
        }
    }

    /**
     * Initialize each form field then update any fields associated with
     * server-provided metadata.
     *
     * @param {Selector}      [form]        Default: {@link formElement}.
     * @param {string|object} [start_data]  Replacement data.
     */
    function initializeFormFields(form, start_data) {

        const func = 'initializeFormFields';
        let $form  = formElement(form);

        let data = {};
        if (start_data) {
            extractData(start_data);
        } else {
            extractData(emmaDataElement($form).val());
            extractData(revertDataElement($form).val());
        }

        formFields($form).each(function() {
            initializeInputField(this, data);
        });
        resolveRelatedFields();
        disableSubmit($form);
        clearFormState($form);

        /**
         * Transform data supplied through an element value and merge in into
         * the initialization data object.
         *
         * @param {string|object} value
         */
        function extractData(value) {
            const result = fromJSON(value, func);
            if (result) {
                $.extend(data, result);
            }
        }
    }

    // ========================================================================
    // Functions - form fields
    // ========================================================================

    /**
     * Interpret the object keys as field names to locate the input elements
     * to update.
     *
     * The field will not be updated if "sealed off" by the presence of the
     * "sealed" CSS class.  This prevents the uploading of the file from
     * modifying metadata which is under the control of the member repository
     * specified via 'emma_repository'.
     *
     * @param {object}   data
     * @param {Selector} [form]       Default: {@link formElement}.
     *
     * @returns {boolean}             False if validateForm didn't occur.
     */
    function populateFormFields(data, form) {
        let revalidated = false;
        if (isPresent(data)) {
            let $form = formElement(form);
            let count = 0;
            $.each(data, function(field, value) {
                let $field = formField(field, $form);
                if (!$field.hasClass('sealed')) {
                    updateInputField($field, value);
                    count++;
                }
            });
            if (count) {
                resolveRelatedFields();
                validateForm($form);
                revalidated = true;
            }
        }
        return revalidated;
    }

    /**
     * Initialize a single input field and its label.
     *
     * @param {Selector} field
     * @param {object}   [data]
     */
    function initializeInputField(field, data) {
        let $field  = $(field);
        const key   = $field.attr('data-field');
        const value = (typeof data === 'object') ? data[key] : data;
        updateInputField($field, value, true, true);
    }

    /**
     * Update a single input field and its label.
     *
     * @param {Selector} field
     * @param {*}        [new_value]
     * @param {boolean}  [trim]       If *false*, don't trim white space.
     * @param {boolean}  [init]       If *true*, in initialization phase.
     */
    function updateInputField(field, new_value, trim, init) {
        let $field = $(field);

        if ($field.is('fieldset.input.multi')) {
            updateFieldsetInputs($field, new_value, trim, init);

        } else if ($field.is('.menu.multi')) {
            updateFieldsetCheckboxes($field, new_value, init);

        } else if ($field.is('.menu.single')) {
            updateMenu($field, new_value, init);

        } else if ($field.is('[type="checkbox"]')) {
            updateCheckboxInputField($field, new_value, init);

        } else if ($field.is('textarea')) {
            updateTextAreaField($field, new_value, trim, init);

        } else {
            updateTextInputField($field, new_value, trim, init);
        }
    }

    /**
     * Update the input field collection and label for a <fieldset> and its
     * enclosed set of text inputs.
     *
     * @param {Selector}             target
     * @param {string|string[]|null} [new_value]
     * @param {boolean}              [trim]     If *false*, keep white space.
     * @param {boolean}              [init]     If *true*, initializing.
     *
     * @see "BaseDecorator::Form#render_form_input_multi"
     */
    function updateFieldsetInputs(target, new_value, trim, init) {

        let $fieldset = $(target);
        let $inputs   = $fieldset.find('input');

        // If multiple values are provided, they are treated as a complete
        // replacement for the existing set of values.
        let value, values;
        if (Array.isArray(new_value) || (new_value === null)) {
            values = compact(new_value || []);
            $inputs.each(function(i) {
                value = values[i];
                if (init && !value) {
                    value = '';
                }
                if (isDefined(value)) {
                    setValue(this, value, true, init);
                }
            });
        } else {
            // Initialize original values for all elements.
            $inputs.each(function() {
                setOriginalValue(this);
            });
            if (new_value) {
                value = new_value;
                if ((trim !== false) && (typeof value === 'string')) {
                    value = value.trim();
                }
                let index = -1;
                // noinspection FunctionWithInconsistentReturnsJS
                $inputs.each(function(i) {
                    const old_value = this.value || '';
                    if (old_value === value) {
                        // The value is present in this slot.
                        index = -1;
                        return false;
                    } else if (index >= 0) {
                        // An empty slot has already been reserved; continue
                        // looking for the value in later slots.
                    } else if (!old_value) {
                        // The value will be placed in this empty slot unless
                        // it is found in a later slot.
                        index = i;
                    }
                });
                if (index >= 0) {
                    setValue($inputs[index], value, trim, init);
                }
            }
        }

        // Enumerate the valid inputs and update the fieldset.
        values = [];
        $inputs.each(function() {
            if (this.value) { values.push(this.value); }
        });
        updateFieldAndLabel($fieldset, values);
    }

    /**
     * Update the input field collection and label for a <fieldset> and its
     * enclosed set of checkboxes.
     *
     * @param {Selector}             target
     * @param {string|string[]|null} [setting]
     * @param {boolean}              [init]     If *true*, in initialization.
     *
     * @see "BaseDecorator::Form#render_form_menu_multi"
     */
    function updateFieldsetCheckboxes(target, setting, init) {

        let $fieldset   = $(target);
        let $checkboxes = $fieldset.find('input[type="checkbox"]');

        // If a value is provided, use it to define the state of the contained
        // checkboxes if it is an array, or to set a specific checkbox if it
        // is a string.
        if (Array.isArray(setting) || (setting === null)) {
            const values = compact(setting || []);
            $checkboxes.each(function() {
                const checked = values.includes(this.value);
                setChecked(this, checked, init);
            });
        } else if (typeof setting === 'string') {
            $checkboxes.each(function() {
                if (this.value === setting) {
                    setChecked(this, true, init);
                } else if (init) {
                    setOriginalValue(this);
                }
            });
        } else if (init) {
            $checkboxes.each(function() {
                setOriginalValue(this);
            });
        }

        // Enumerate the checked items and update the fieldset.
        let checked = [];
        $checkboxes.each(function() {
            if (this.checked) { checked.push(this.value); }
        });
        updateFieldAndLabel($fieldset, checked);
    }

    /**
     * Update the input field and label for a <input type="checkbox">.
     *
     * For this type, the checkbox is within a hierarchy under a <fieldset>
     * element which is a sibling of the label element associated with any of
     * the contained checkboxes.
     *
     * @param {Selector}       target
     * @param {string|boolean} [setting]
     * @param {boolean}        [init]       If *true*, in initialization phase.
     */
    function updateCheckboxInputField(target, setting, init) {
        const func     = 'updateCheckboxInputField';
        let $input     = $(target);
        let $fieldset  = $input.parents('[data-field]').first();
        const checkbox = $input[0];
        let checked    = undefined;
        if (notDefined(setting)) {
            checked = checkbox.checked;
        } else if (typeof setting === 'boolean') {
            checked = setting;
        } else if (setting === checkbox.value) {
            checked = true;
        } else if (setting === 'true') {
            checked = true;
        } else if (setting === 'false') {
            checked = false;
        }

        if (isDefined(checked)) {
            setChecked($input, checked, init);
        } else {
            consoleWarn(`${func}: unexpected:`, setting);
        }

        // Update the enclosing fieldset.
        updateFieldsetCheckboxes($fieldset, undefined, init);
    }

    /**
     * Update the input field and label for a <select>.
     *
     * For these types, the label is a sibling of the input element.
     *
     * @param {Selector}       target
     * @param {string|null}    [new_value]
     * @param {boolean}        [init]       If *true*, in initialization phase.
     *
     * @see "BaseDecorator::Form#render_form_menu_single"
     */
    function updateMenu(target, new_value, init) {
        let $input = $(target);
        let value  = new_value;
        if (Array.isArray(value)) {
            value = compact(value)[0];
        } else if (value !== null) {
            value = value || $input.val();
        }
        setValue($input, value, true, init);
        updateFieldAndLabel($input, $input.val());
    }

    /**
     * Update the input field and label for a <textarea>.
     *
     * For this type, the label is a sibling of the input element.
     *
     * @param {Selector}    target
     * @param {string|null} [new_value]
     * @param {boolean}     [trim]          If *false*, don't trim white space.
     * @param {boolean}     [init]          If *true*, in initialization phase.
     *
     * @see "BaseDecorator::Form#render_form_input"
     */
    function updateTextAreaField(target, new_value, trim, init) {
        let $input = $(target);
        let value  = new_value;
        if (value !== null) {
            value = value || $input.val();
            if (trim !== false) {
                value = textAreaValue(value);
            }
        }
        setValue($input, value, trim, init);
        updateFieldAndLabel($input, value);
    }

    /**
     * Update the input field and label for <select> or <input type="text">.
     *
     * For these types, the label is a sibling of the input element.
     *
     * @param {Selector}    target
     * @param {string|null} [new_value]
     * @param {boolean}     [trim]          If *false*, don't trim white space.
     * @param {boolean}     [init]          If *true*, in initialization phase.
     *
     * @see "BaseDecorator::Form#render_form_input"
     */
    function updateTextInputField(target, new_value, trim, init) {
        let $input = $(target);
        let value  = new_value;
        if (Array.isArray(value)) {
            value = compact(value).join('; ');
        } else if (value !== null) {
            value = value || $input.val();
        }
        setValue($input, value, trim, init);

        // If this is one of a collection of text inputs under <fieldset> then
        // it has to be handled differently.
        if ($input.parent().hasClass('multi')) {
            let $fieldset = $input.parents('fieldset').first();
            updateFieldsetInputs($fieldset, undefined, trim, init);
        } else {
            updateFieldAndLabel($input, $input.val());
        }
    }

    /**
     * Attempt to update all of the fields with relationships except for those
     * indicated.
     *
     * @param {string[]} [already_modified]
     */
    function resolveRelatedFields(already_modified) {
        let skip_fields = already_modified || [];
        $.each(FIELD_RELATIONSHIP, function(field_name, relationship) {
            if (!skip_fields.includes(field_name)) {
                const visited = updateRelatedField(field_name, relationship);
                if (visited) {
                    skip_fields.push(visited.name);
                }
            }
        });
    }

    /**
     * Use {@link FIELD_RELATIONSHIP} to determine whether the state of the
     * indicated field should change the state of other field(s) with which it
     * has a relationship.
     *
     * @param {string|jQuery}       name
     * @param {string|Relationship} [other_name]
     *
     * @returns {undefined | { name: string, modified: boolean|undefined }}
     */
    function updateRelatedField(name, other_name) {
        const func = 'updateRelatedField';
        if (isMissing(name)) {
            consoleError(`${func}: missing primary argument`);
            return;
        }

        // Determine the element for the named field.
        let $form = formElement();
        let this_name;
        let $this_input;
        if (typeof name === 'string') {
            this_name   = name;
            $this_input = $form.find(`[name="${this_name}"]`);
        } else {
            $this_input = $(name);
            this_name   = $this_input.attr('name');
        }

        /** @type {Relationship} */
        let other;
        /** @type {boolean|string|undefined} */
        let error = undefined;
        /** @type {boolean|string|undefined} */
        let warn  = undefined;
        if (typeof other_name === 'object') {
            other = dup(other_name);
            error = isMissing(other) && 'empty secondary argument';
        } else if (isDefined(other_name)) {
            other = FIELD_RELATIONSHIP[other_name];
            error = isMissing(other) && `no table entry for ${this_name}`;
        } else {
            other = FIELD_RELATIONSHIP[this_name];
            if (isMissing(other)) {
                warn  = `no table entry for ${this_name}`;
            } else if (other_name && (other_name !== other.name)) {
                error = `no relation for ${this_name} -> ${other_name}`;
            }
        }
        if (error) {
            consoleError(`${func}:`, error);
            return;
        } else if (warn) {
            // consoleWarn(`${func}:`, warn);
            return;
        }

        // Toggle state of the related element.
        let modified     = undefined;
        let $other_input = $form.find(`[name="${other.name}"]`);
        if (isPresent($other_input)) {
            if (isTrue(other.required) || isFalse(other.unrequired)) {
                modified = modifyOther(true, other.required_val);
            } else if (isTrue(other.unrequired) || isFalse(other.required)) {
                modified = modifyOther(false, other.unrequired_val);
            }
            if (modified) {
                updateFieldAndLabel($other_input, $other_input.val());
            }
        }
        return { name: other.name, modified: modified };

        // ====================================================================
        // Functions
        // ====================================================================

        function isTrue(v) {
            return isBoolean(v, true);
        }

        function isFalse(v) {
            return isBoolean(v, false);
        }

        function isBoolean(v, is_true) {
            let result = v;
            if (typeof result === 'function') {
                result = result($this_input);
            }
            if (typeof result !== 'boolean') {
                result = String(result).toLowerCase();
                result = is_true ? (result === 'true') : (result !== 'false');
            }
            return is_true ? result : !result;
        }

        function modifyOther(new_req, new_val) {
            let changed   = false;
            const old_req = $other_input.attr('data-required')?.toString();
            if (old_req !== new_req?.toString()) {
                $other_input.attr('data-required', new_req);
                changed = true;
            }
            if (isDefined(new_val) && ($other_input.val() !== new_val)) {
                $other_input.val(new_val);
                // This shouldn't be necessary.
                if ((this_name === 'rem_complete') &&
                    (rawOriginalValue($other_input) === '(ALL)')) {
                    setOriginalValue($other_input, '');
                    $other_input.text(new_val);
                }
                changed = true;
            }
            return changed;
        }
    }

    /**
     * Update the input field for <select>, <textarea>, or <input type="text">,
     * along with its label, and possibly other related fields.
     *
     * For these types, the label is a sibling of the input element.
     *
     * @param {Selector} target
     * @param {*}        values
     *
     * @see "BaseDecorator::Form#form_note_pair"
     */
    function updateFieldAndLabel(target, values) {
        let $input   = $(target);
        const id     = $input.attr('id');
        const field  = $input.attr('data-field');
        /** @type {jQuery} $label, $status, $related */
        let $label   = $input.siblings(`label[for="${id}"]`);
        let $status  = $label.find('.status-marker');
        let $related = $input.siblings(`[data-for="${field}"]`);
        const parts  = [$input, $label, $status, ...$related];

        if ($input.attr('readonly')) {

            // Database fields should not be marked for validation.
            toggleClass(parts, 'valid invalid', false);

        } else {

            const required = ($input.attr('data-required') === 'true');
            const optional = ($input.attr('data-required') === 'false');
            const missing  = isEmpty(values);
            let invalid    = required && missing;

            if (invalid) {
                update(false);
            } else {
                validate($input, values, update);
            }

            function update(valid, notes) {

                if (required || !missing) {
                    invalid ||= !valid;
                }

                // Update the status icon and tooltip.
                let icon, tip;
                if (valid && (required || !missing)) {
                    icon = PROPERTIES.Status.valid.label;
                    tip  = PROPERTIES.Status.valid.tooltip;
                } else if (invalid && !missing) {
                    icon = PROPERTIES.Status.invalid.label;
                    tip  = PROPERTIES.Status.invalid.tooltip;
                } else if (required) {
                    icon = PROPERTIES.Status.required.label;
                } else {
                    icon = PROPERTIES.Status.blank.label;
                }

                const plus_notes = isPresent(notes) && arrayWrap(notes);
                if (tip && plus_notes) {
                    setTooltip($status, [tip, '', ...plus_notes].join("\n"));
                } else if (tip ||= plus_notes) {
                    setTooltip($status, tip);
                } else {
                    restoreTooltip($status);
                }

                if (icon) {
                    setIcon($status, icon);
                } else {
                    restoreIcon($status);
                }

                // Update CSS status classes on all parts of the field.
                toggleClass(parts, 'required', required);
                toggleClass(parts, 'invalid',  invalid);
                toggleClass(parts, 'valid',    (!!valid && !missing));
            }
        }
    }

    /**
     * If the checkbox state is changing, save the old state.
     *
     * If *new_state* is undefined then it is assumed that this invocation is
     * in response to a change event, in which case the state change has
     * already happened so the old state is the opposite of the current state.
     *
     * @param {Selector} target
     * @param {boolean}  [new_state]
     * @param {boolean}  [init]       If *true*, in initialization phase.
     */
    function setChecked(target, new_state, init) {
        let $item = $(target);
        if (init) {
            setOriginalValue($item, new_state);
        }
        $item[0].checked = new_state;
    }

    /**
     * If the input value is changing, save the old value.
     *
     * @param {Selector}    target
     * @param {string|null} new_value
     * @param {boolean}     [trim]      If *false*, don't trim white space.
     * @param {boolean}     [init]      If *true*, in initialization phase.
     */
    function setValue(target, new_value, trim, init) {
        let $item = $(target);
        let value = new_value || '';
        if ((trim !== false) && value && (typeof value === 'string')) {
            value = value.trim();
        }
        if (init) {
            setOriginalValue($item, value);
        }
        $item.val(value);
    }

    /**
     * Translate a value for a <textarea> into a string.
     *
     * @param {string|string[]} value
     *
     * @returns {string}
     */
    function textAreaValue(value) {
        let result = value;
        if (typeof result === 'string') {
            result = result.trim();
            if (!result || (result === '[]')) {
                result = '';
            } else if (result[0] === '[') {
                // noinspection UnusedCatchParameterJS
                try {
                    result = JSON.parse(result);
                }
                catch (_err) {
                    if (result.slice(-1) === ']') {
                        result = result.slice(1, -1);
                    } else {
                        result = result.slice(1);
                    }
                    result = [result];
                }
            } else {
                result = [result];
            }
        }
        if (Array.isArray(result)) {
            return compact(result).map(v => htmlDecode(v)).join("\n");
        } else {
            return result;
        }
    }

    /**
     * Save the original value of an element.
     *
     * If *value* is present, that is assigned directly as the original value.
     * If *value* was not provided, and no saved value is present then the
     * current value will be saved as the original value.
     *
     * @param {Selector}                 target
     * @param {string|boolean|undefined} [value]
     */
    function setOriginalValue(target, value) {
        let $item     = $(target);
        let new_value = undefined;
        if (isDefined(value)) {
            new_value = valueOf(value);
        } else if (notDefined(rawOriginalValue($item))) {
            new_value = valueOf($item);
        }
        if (isDefined(new_value)) {
            $item.attr('data-original-value', new_value);
        }
    }

    /**
     * Get the effective original value of the element.
     *
     * @param {Selector} target
     *
     * @returns {string}
     */
    function getOriginalValue(target) {
        const value = rawOriginalValue(target);
        return notDefined(value) ? '' : value;
    }

    /**
     * Get the saved original value of the element.
     *
     * @param {Selector} target
     *
     * @returns {string|undefined}
     */
    function rawOriginalValue(target) {
        let $item = $(target);
        return $item.attr('data-original-value');
    }

    /**
     * Get the value string associated with *item*.
     *
     * If *item* is a checkbox element, the state of it's 'checked' attribute
     * is found; if *item* is another type of element, its 'value' attribute
     * is found.
     *
     * Booleans are converted to either 'true' or 'false'.
     *
     * @param {jQuery|HTMLElement|string|boolean|undefined} item
     *
     * @returns {string}
     */
    function valueOf(item) {
        let value;
        if (typeof item === 'object') {
            let $i = $(item);
            value  = $i.is('[type="checkbox"]') ? $i[0].checked : $i.val();
        } else {
            value  = item;
        }
        switch (typeof value) {
            case 'boolean': value = value ? 'true' : 'false'; break;
            case 'number':  value = value.toString();         break;
            case 'string':  value = value.trim();             break;
            default:        value = '';                       break;
        }
        return value;
    }

    // ========================================================================
    // Functions - field validation
    // ========================================================================

    /**
     * Validate the value(s) for a field.
     *
     * @param {Selector} target
     * @param {*}        new_value    Current *target* value if not given.
     * @param {function} callback     Required.
     */
    function validate(target, new_value, callback) {
        let $input  = $(target);
        const field = $input.attr('data-field');
        const entry = FIELD_VALIDATION[field];
        const value = isDefined(new_value) ? new_value : $input.val();
        let valid, notes, min, max;
        if (isEmpty(value)) {
            notes = 'empty value';
            valid = undefined;
        } else if (typeof entry === 'string') {
            remoteValidate(field, value, callback);
            return;
        } else if (typeof entry === 'function') {
            notes = undefined;
            valid = entry(value);
        } else if (typeof entry === 'boolean') {
            notes = undefined;
            valid = entry;
        } else if (field === 'password_confirmation') {
            let $pwd = inputFields().filter('[data-field="password"]');
            if ($pwd.hasClass('valid')) {
                valid = (value === $pwd.val());
            } else if ($pwd.hasClass('invalid')) {
                valid = false;
            }
        } else if ((min = $input.attr('minlength')) && (value.length < min)) {
            notes = 'Not enough characters.'; // TODO: I18n
            valid = false;
        } else if ((max = $input.attr('maxlength')) && (value.length > max)) {
            notes = 'Too many characters.'; // TODO: I18n
            valid = false;
        } else {
            notes = undefined;
            valid = true;
        }
        callback(valid, notes);
    }

    /**
     * Validate the value(s) for a field.
     *
     * @param {string}   field
     * @param {*}        new_value        Current *target* value if not given.
     * @param {function} callback
     */
    function remoteValidate(field, new_value, callback) {
        const func = 'remoteValidate';
        let url    = FIELD_VALIDATION[field];

        if (isMissing(callback)) {
            consoleError(func, `${field}: no callback given`);
        }
        if (isMissing(url)) {
            consoleError(func, `${field}: no URL given`);
            callback(false);
            return;
        }

        // Prepare value for inclusion in the URL.
        let value = new_value;
        if (typeof value === 'string') {
            value = value.split(/[,;|\t\n]/);
        }
        if (Array.isArray(value)) {
            value = value.join(',');
        }
        if (isEmpty(value)) {
            consoleWarn(func, `${url}: no values given`);
            callback(false);
            return;
        }

        // If the URL is expecting to be completed, append the value string.
        // Otherwise provide it as a generic "value" URL parameter.
        if (url.endsWith('=')) {
            url += value;
        } else if (url.includes('?')) {
            url = makeUrl(url, { value: value });
        }

        let error, reply;
        const start = Date.now();

        $.ajax({
            url:      url,
            type:     'GET',
            success:  onSuccess,
            error:    onError,
            complete: onComplete
        });

        /**
         * Parse the validation reply.
         *
         * @param {object}         data
         * @param {string}         status
         * @param {XMLHttpRequest} xhr
         */
        function onSuccess(data, status, xhr) {
            // debugXhr(func, 'received data: |', data, '|');
            if (isMissing(data)) {
                error = 'no data';
            } else if (typeof(data) !== 'object') {
                error = `unexpected data type ${typeof data}`;
            } else {
                // The actual data may be inside '{ "response" : { ... } }'.
                reply = data.response || data;
            }
        }

        /**
         * Accumulate the status failure message.
         *
         * @param {XMLHttpRequest} xhr
         * @param {string}         status
         * @param {string}         message
         */
        function onError(xhr, status, message) {
            if (xhr.status === HTTP.unauthorized) {
                error = 'Could not contact server for validation'; // TODO: I18n
            } else {
                error = `${status}: ${xhr.status} ${message}`;
            }
        }

        /**
         * Invoke the callback with the reply.
         *
         * @param {XMLHttpRequest} xhr
         * @param {string}         status
         */
        function onComplete(xhr, status) {
            debugXhr(func, 'complete', secondsSince(start), 'sec.');
            if (error) {
                consoleWarn(func, `${url}:`, error);
                callback(undefined, `system error: ${error}`);
            } else if (isPresent(reply.errors)) {
                callback(reply.valid, reply.errors);
            } else {
                callback(reply.valid, reply.ids);
            }
        }
    }

    // ========================================================================
    // Functions - source repository
    // ========================================================================

    /**
     * Monitor attempts to change to the "Source Repository" menu selection.
     *
     * @param {Selector} [form]       Default: {@link formElement}.
     */
    function monitorSourceRepository(form) {

        const func = 'monitorSourceRepository';
        let $form  = formElement(form);
        let $menu  = sourceRepositoryMenu($form);

        // If editing a completed submission, prevent the selection from being
        // updated.

        if (isUpdateForm($form) && $menu.val()) {
            const note = 'This cannot be changed for an existing EMMA entry'; // TODO: I18n
            $menu.attr('title', note);
            $menu.prop('disabled', true);
            $menu.addClass('sealed');
            return;
        }

        // Listen for a change to the "Source Repository" selection.  If the
        // selection was cleared, or if the default repository was selected,
        // then proceed to form validation.  If a member repository was
        // selected, prompt for the original item.

        handleEvent($menu, 'change', function() {
            clearFlash();
            hideParentEntrySelect($form);
            const new_repo = $menu.val() || '';
            if (!new_repo || (new_repo === PROPERTIES.Repo.default)) {
                setSourceRepository(new_repo);
            } else {
                let $popup = showParentEntrySelect($form);
                $popup.find('#parent-entry-search').focus();
            }
        });

        // Set up click handler for the button within .parent-entry-select,
        // the element that will be displayed to prompt for the original item
        // on which this submission is based.

        let $submit = parentEntrySelect($form).find('.search-button');
        handleClickAndKeypress($submit, function() {
            clearFlash();
            hideParentEntrySelect($form);
            const new_repo = $menu.val();
            const query    = parentEntrySearchTerms($form);
            const search   = { q: query, repository: new_repo };
            fetchIndexEntries(search, useParentEntryMetadata, searchFailure);
        });

        // If the prompt is canceled, silently restore the source repository
        // selection to its previous setting.

        let $cancel = parentEntrySelect($form).find('.search-cancel');
        handleClickAndKeypress($cancel, function() {
            clearFlash();
            hideParentEntrySelect($form);
            searchFailure();
        });

        /**
         * Extract the title information from the search results.
         *
         * @param {SearchResultEntry[]} list
         *
         * @returns {void}
         */
        function useParentEntryMetadata(list) {

            const new_repo = $menu.val();
            let error;

            // If there was an error, the source repository menu selection is
            // restored to its previous setting.

            if (isEmpty(list)) {
                const query = parentEntrySearchTerms($form);
                error = `${new_repo}: no match for "${query}"`;
                console.warn(`${func}:`, error);
            } else if (!Array.isArray(list)) {
                error = `${new_repo}: search error`;
                console.error(`${func}: ${new_repo}: arg is not an array`);
            }
            if (error) {
                return searchFailure(error);
            }

            // Ideally, there should be only a single search result which
            // matched the search terms.  If there are multiple results,
            // ideally they are all just variations on the same title.

            /** @type {SearchResultEntry} */
            let parent = list.shift();
            if (new_repo !== parent.emma_repository) {
                error = 'PROBLEM: ';
                error += `new_repo == "${new_repo}" but parent `;
                error += `emma_repository == "${parent.emma_repository}"`;
                console.warn(`${func}:`, error);
            }
            if (isPresent(list)) {
                const title_id = parent.emma_titleId;
                list.forEach(function(entry) {
                    if (entry.emma_titleId !== title_id) {
                        error = `ambiguous: Title ID ${entry.emma_titleId}`;
                        flashMessage(error);
                        console.warn(`${func}: ambiguous: ${asString(entry)}`);
                    }
                });
            }

            // If control reaches here then the current selection is valid.

            $menu.attr('data-previous-value', new_repo);

            // Update form fields.
            //
            // Value        Field will be...
            // -----------  --------------------------------------------------
            // FROM_PARENT  assigned the value acquired from the parent record
            // CLEARED      cleared of any value(s)
            // AS_IS        kept as it is
            // (other)      assigned that value
            //
            // The AS_IS choice is necessary for any remediation-related fields
            // may have been extracted from the file if it was provided before
            // the source repository was selected.

            const FROM_PARENT  = true;
            const CLEARED      = null;
            const AS_IS        = '';
            const repo_name    = PROPERTIES.Repo.name[new_repo];
            const source_field = {
                repository:                         new_repo,
                emma_recordId:                      CLEARED,
                emma_titleId:                       FROM_PARENT,
                emma_repository:                    new_repo,
                emma_collection:                    FROM_PARENT,
                emma_repositoryRecordId:            FROM_PARENT,
                emma_retrievalLink:                 CLEARED,
                emma_webPageLink:                   CLEARED,
                emma_lastRemediationDate:           AS_IS,
                emma_sortDate:                      FROM_PARENT,
                emma_repositoryUpdateDate:          AS_IS,
                emma_repositoryMetadataUpdateDate:  AS_IS,
                emma_publicationDate:               FROM_PARENT,
                emma_lastRemediationNote:           AS_IS,
                emma_version:                       FROM_PARENT,
                emma_formatVersion:                 AS_IS,
                emma_formatFeature:                 AS_IS,
                dc_title:                           FROM_PARENT,
                dc_creator:                         FROM_PARENT,
                dc_identifier:                      FROM_PARENT,
                dc_relation:                        FROM_PARENT,
                dc_publisher:                       FROM_PARENT,
                dc_language:                        FROM_PARENT,
                dc_rights:                          FROM_PARENT,
                dc_description:                     FROM_PARENT,
                dc_format:                          AS_IS,
                dc_type:                            AS_IS,
                dc_subject:                         FROM_PARENT,
                dcterms_dateAccepted:               CLEARED,
                dcterms_dateCopyright:              FROM_PARENT,
                s_accessibilityFeature:             AS_IS,
                s_accessibilityControl:             AS_IS,
                s_accessibilityHazard:              AS_IS,
                s_accessibilityMode:                AS_IS,
                s_accessibilityModeSufficient:      AS_IS,
                s_accessibilitySummary:             AS_IS,
                rem_source:                         AS_IS,
                rem_metadataSource:                 [repo_name],
                rem_remediatedBy:                   AS_IS,
                rem_complete:                       AS_IS,
                rem_coverage:                       AS_IS,
                rem_remediation:                    AS_IS,
                rem_remediatedAspects:              AS_IS,
                rem_textQuality:                    AS_IS,
                rem_quality:                        AS_IS,
                rem_status:                         AS_IS,
                rem_remediationDate:                AS_IS,
                rem_comments:                       AS_IS,
                rem_remediationComments:            AS_IS,
                bib_series:                         FROM_PARENT,
                bib_seriesType:                     FROM_PARENT,
                bib_seriesPosition:                 FROM_PARENT,
            };

            let update = {};
            $.each(source_field, function(field, value) {
                if (typeof value === 'function') {
                    update[field] = value(parent);
                } else if (value === FROM_PARENT) {
                    update[field] = parent[field] || EMPTY_VALUE;
                } else {
                    update[field] = value;
                }
            });
            populateFormFields(update, $form);

            // Seal off the specified fields by adding the "sealed" class in
            // order to prevent populateFormFields() from modifying the them.
            //
            // This way, if the source repository is set before the file is
            // uploaded then metadata extracted from the file will not
            // contradict the title-level metadata supplied by the member
            // repository.
            //
            // This doesn't prevent the user from updating the field, but the
            // styling of the "sealed" class should hint that changing the
            // field is not desirable (since the change is going to be ignored
            // by the member repository anyway).

            $.each(source_field, function(field, value) {
                if (value === FROM_PARENT) {
                    let $input = formField(field, $form);
                    let input  = $input[0];
                    if (input.value === EMPTY_VALUE) {
                        input.placeholder = input.value;
                        input.value       = '';
                    }
                    $input.toggleClass('sealed');
                }
            });
        }

        /**
         * The search failed.
         *
         * @param {string} [message]
         */
        function searchFailure(message) {
            if (message) {
                flashError(message);
            }
            setSourceRepository();
        }

        /**
         * Force the current source repository setting.
         *
         * @param {string} [value]
         */
        function setSourceRepository(value) {
            let new_repo;
            if (notDefined(value)) {
                new_repo = $menu.attr('data-previous-value') || '';
            } else {
                new_repo = value;
                $menu.attr('data-previous-value', new_repo);
            }
            const set_repo = {
                repository:      (new_repo || EMPTY_VALUE),
                emma_repository: (new_repo || null)
            };
            debug(`${func}:`, (new_repo || 'cleared'));
            populateFormFields(set_repo, $form);
        }
    }

    /**
     * Get EMMA index entries via search.
     *
     * @param {string|[string]|object} search
     * @param {function(SearchResultEntry[])} callback
     * @param {function}                      [error_callback]
     */
    function fetchIndexEntries(search, callback, error_callback) {
        const func = 'fetchIndexEntries';
        let search_terms = {};

        // Create a search URL from the given search term(s).
        if (isEmpty(search)) {
            console.error(`${func}: empty search terms`);
            return;
        } else if (Array.isArray(search)) {
            let terms = [];
            search.forEach(function(term) {
                const type = typeof(term);
                if (type !== 'string') {
                    console.warn(`${func}: can't process ${type} search term`);
                } else if (!term) {
                    // Skip empty term.
                } else if (term.match(/\s/)) {
                    terms.push(`"${term}"`);
                } else {
                    terms.push(term);
                }
            });
            search_terms['q'] = terms.join('+');
        } else if (typeof search === 'object') {
            $.extend(search_terms, search);
        } else if (typeof search !== 'string') {
            console.error(`${func}: can't process ${typeof search} search`);
            return;
        } else if (search.match(/\s/)) {
            search_terms['q'] = `"${search}"`;
        } else {
            search_terms['q'] = search;
        }
        const url = makeUrl('/search/direct', search_terms);

        debugXhr(`${func}: VIA`, url);

        /** @type {SearchResultEntry[]} */
        let records = undefined;
        let warning, error;
        const start = Date.now();

        $.ajax({
            url:      url,
            type:     'GET',
            dataType: 'json',
            success:  onSuccess,
            error:    onError,
            complete: onComplete
        });

        /**
         * Extract the list of search result entries returned as JSON.
         *
         * @param {SearchResultMessage|object} data
         * @param {string}                     status
         * @param {XMLHttpRequest}             xhr
         */
        function onSuccess(data, status, xhr) {
            // debugXhr(`${func}: received`, (data?.length || 0), 'bytes.');
            if (isMissing(data)) {
                error = 'no data';
            } else if (typeof(data) !== 'object') {
                error = `unexpected data type ${typeof data}`;
            } else {
                records = data.response?.records || [];
            }
        }

        /**
         * Accumulate the status failure message.
         *
         * @param {XMLHttpRequest} xhr
         * @param {string}         status
         * @param {string}         message
         */
        function onError(xhr, status, message) {
            const failure = `${status}: ${xhr.status} ${message}`;
            if (transientError(xhr.status)) {
                warning = failure;
            } else {
                error   = failure;
            }
        }

        /**
         * Actions after the request is completed.  If there was no error, the
         * search result list is passed to the callback function.
         *
         * @param {XMLHttpRequest} xhr
         * @param {string}         status
         */
        function onComplete(xhr, status) {
            debugXhr(`${func}: complete`, secondsSince(start), 'sec.');
            if (records) {
                callback(records);
            } else {
                const failure = error || warning || 'unknown failure'
                const message = `${url}: ${failure}`;
                if (warning) {
                    consoleWarn(`${func}:`, message);
                } else {
                    consoleError(`${func}:`, message);
                }
                if (error_callback) {
                    error_callback(message);
                }
            }
        }
    }

    /**
     * The menu which defines the intended repository for the submission.
     *
     * @param {Selector} [form]       Passed to {@link inputFields}.
     *
     * @returns {jQuery}
     */
    function sourceRepositoryMenu(form) {
        return inputFields(form).filter('[data-field="emma_repository"]');
    }

    /**
     * Search terms used to locate the parent EMMA entry.
     *
     * @param {Selector} [form]
     *
     * @returns {string|undefined}
     */
    function parentEntrySearchTerms(form) {
        return parentEntrySelect(form).find('#parent-entry-search').val();
    }

    /**
     * Selection control for identifying the EMMA entry which is the source of
     * a new submission derived from member repository content.
     *
     * @param {Selector} [form]
     *
     * @returns {jQuery}
     */
    function parentEntrySelect(form) {
        return formElement(form).find('.parent-entry-select');
    }

    /**
     * Display the source entry selection control.
     *
     * @param {Selector} [form]
     *
     * @returns {jQuery}
     */
    function showParentEntrySelect(form) {
        let $form = parentEntrySelect(form);
        $form.find('#parent-entry-search').prop('disabled', false);
        return $form.toggleClass('hidden', false);
    }

    /**
     * Hide the source entry selection control.
     *
     * @param {Selector} [form]
     *
     * @returns {jQuery}
     */
    function hideParentEntrySelect(form) {
        let $form = parentEntrySelect(form);
        $form.find('#parent-entry-search').prop('disabled', true);
        return $form.toggleClass('hidden', true);
    }

    // ========================================================================
    // Functions - form validation
    // ========================================================================

    /**
     * Listen for changes on input fields.
     *
     * @param {Selector} [form]       Default: {@link formElement}.
     */
    function monitorInputFields(form) {

        let $form   = formElement(form);
        let $fields = inputFields($form);

        handleEvent($fields, 'change', onChange);
        handleEvent($fields, 'cut',    debounce(onCut));
        handleEvent($fields, 'paste',  debounce(onPaste));
        handleEvent($fields, 'keyup',  debounce(onKeyUp, DEBOUNCE_DELAY));

        /**
         * Revalidate the form after the element's content changes.
         *
         * In the case of checkboxes/radio buttons this happens when the value
         * of the element changes; otherwise it happens when the element loses
         * focus.
         *
         * @param {jQuery.Event} event
         */
        function onChange(event) {
            DEBUG.INPUT && console.log('*** CHANGE ***');
            validateInputField(event);
        }

        /**
         * After the cut-to-clipboard has completed, re-validate the form based
         * on the new contents of the element.
         *
         * @param {jQuery.Event|ClipboardEvent} event
         */
        function onCut(event) {
            DEBUG.INPUT && console.log('*** CUT ***');
            validateInputField(event);
        }

        /**
         * After the paste-from-clipboard has completed, re-validate the form
         * based on the new contents of the element.
         *
         * @param {jQuery.Event|ClipboardEvent} event
         */
        function onPaste(event) {
            DEBUG.INPUT && console.log('*** PASTE ***');
            validateInputField(event);
        }

        /**
         * Respond to key presses only after the user has paused, rather than
         * re-validating the entire form with every key stroke.
         *
         * @param {jQuery.Event|KeyboardEvent} event
         *
         * @returns {function}
         */
        function onKeyUp(event) {
            DEBUG.INPUT && console.log('*** KEYUP ***');
            validateInputField(event, undefined, false);
        }

        /**
         * Update a single input field then revalidate the form.
         *
         * @param {jQuery.Event} event
         * @param {string|null}  [value]  Default: current element value.
         * @param {boolean}      [trim]   If *false*, don't trim white space.
         */
        function validateInputField(event, value, trim) {
            let $field = $(event.target);
            updateInputField($field, value, trim);
            updateRelatedField($field);
            validateForm($form);
            clearFormState($form);
        }
    }

    /**
     * Check whether all required field values are present (and a file has been
     * supplied in the case of a new submission) and that all supplied values
     * are valid.
     *
     * @param {Selector} [form]       Default: {@link formElement}.
     */
    function validateForm(form) {
        let $form   = formElement(form);
        let $fields = inputFields($form);
        let ready   = !$fields.hasClass('invalid');
        if ((ready &&= !menuMultiFields($form).hasClass('invalid'))) {
            const updating = isUpdateForm($form);
            let recheck = updating;
            if (uploader) {
                if (uploader.fileSelected()) {
                    recheck = false;
                } else if (!updating) {
                    ready = false;
                }
            }
            if (recheck) {
                const items = $fields.toArray();
                ready = items.some(i => (valueOf(i) !== getOriginalValue(i)));
            }
        }
        if (ready) {
            enableSubmit($form);
        } else {
            disableSubmit($form);
        }
    }

    /**
     * Enable form submission.
     *
     * @param {Selector} [form]       Default: {@link formElement}.
     *
     * @returns {jQuery}              The submit button.
     */
    function enableSubmit(form) {
        let $form = formElement(form);
        const tip = submitReadyTooltip($form);
        return submitButton($form)
            .addClass('best-choice')
            .removeClass('disabled forbidden')
            .removeAttr('disabled')
            .attr('title', tip)
            .attr('data-state', 'ready');
    }

    /**
     * Disable form submission.
     *
     * @param {Selector} [form]       Default: {@link formElement}.
     *
     * @returns {jQuery}              The submit button.
     */
    function disableSubmit(form) {
        let $form = formElement(form);
        const tip = submitNotReadyTooltip($form);
        return submitButton($form)
            .removeClass('best-choice')
            .addClass('forbidden')
            .attr('disabled', true)
            .attr('title', tip)
            .attr('data-state', 'not-ready');
    }

    // ========================================================================
    // Functions - form submission
    // ========================================================================

    /**
     * Indicate that submission process has been initiated.
     *
     * @param {jQuery.Event} [event]
     */
    function startSubmission(event) {
        let $button = $(event.target);
        let $form   = formElement($button);
        setFormSubmitting($form);
    }

    /**
     * Get data to send to revert a canceled edit.
     *
     * @param {Selector} [form]       Default: {@link formElement}.
     *
     * @returns {object|undefined}
     */
    function revertEditData(form) {
        const func = 'revertEditData';
        const data = revertDataElement(form).val();
        return (data && (data !== '{}')) ? fromJSON(data, func) : undefined;
    }

    /**
     * Actively cancel the current action.
     *
     * The Upload record is restored to its original state (non-existence in
     * the case of the create form).
     *
     * @param {jQuery.Event} [event]
     */
    function cancelSubmission(event) {
        event.stopPropagation();
        event.preventDefault();
        let $button = $(event.target);
        let $form   = formElement($button);
        if (!formState($form)) {
            setFormCanceled($form);
            let cancel_path = $button.attr('data-path');
            if (PROPERTIES.Path.cancel) {
                const fields = isUpdateForm($form) && revertEditData($form);
                cancelCurrent($form, cancel_path, fields);
            } else {
                cancel_path ||= $button.attr('href') || 'back';
                cancelAction(cancel_path);
            }
        }
    }

    /**
     * Cancel the current action.
     *
     * @param {Selector}      [form]        Default: {@link formElement}.
     * @param {string}        [redirect]
     * @param {string|object} [fields]
     */
    function cancelCurrent(form, redirect, fields) {
        let $form  = formElement(form);
        const sid  = submissionParams($form);
        let params = $.extend({ redirect: PROPERTIES.Path.index }, sid);
        if (redirect) {
            let back_here;
            if (!uploader || uploader.fileSelected()) {
                const p = window.location.pathname;   // Current path.
                const u = window.location.origin + p; // Current URL.
                back_here = redirect.startsWith(p) || redirect.startsWith(u);
            }
            if (back_here && !canSubmit($form)) {
                params.reset    = true;
                params.redirect = makeUrl(redirect, sid);
            } else {
                params.redirect = redirect;
            }
        }
        if (fields) {
            /** @type {string} */
            let data = fields;
            if (typeof data !== 'string') {
                data = JSON.stringify(data);
            }
            params.revert = encodeURIComponent(data);
        }
        cancelAction(makeUrl(PROPERTIES.Path.cancel, params));
    }

    /**
     * Abandon the current action (by moving through history or clicking on
     * another link).
     *
     * @param {Selector} [form]       Default: {@link formElement}.
     */
    function abortSubmission(form) {
        let $form   = formElement(form);
        const state = formState($form);
        if (!state) {
            // Neither Submit nor Cancel have been invoked yet.
            let fields = undefined;
            if (isUpdateForm($form)) {
                fields = revertEditData($form);
            }
            setFormCanceled($form);
            abortCurrent($form, fields);
        }
    }

    /**
     * Inform the server that the submission should be canceled.
     *
     * @param {Selector}      [form]        Default: {@link formElement}.
     * @param {string|object} [fields]
     */
    function abortCurrent(form, fields) {
        let $form  = formElement(form);
        let params = submissionParams($form);
        if (fields) {
            /** @type {string} */
            let data = fields;
            if (typeof data !== 'string') {
                data = JSON.stringify(data);
            }
            params.revert = encodeURIComponent(data);
        }
        $.ajax({
            url:     makeUrl(PROPERTIES.Path.cancel, params),
            type:    'POST',
            headers: { 'X-CSRF-Token': Rails.csrfToken() },
            async:   false
        });
    }

    /**
     * React to the server's response after the form is submitted.
     *
     * @param {Selector} [form]       Default: {@link formElement}.
     */
    function monitorRequestResponse(form) {

        let $form = formElement(form);

        handleEvent($form, 'ajax:before',     beforeAjax);
        handleEvent($form, 'ajax:beforeSend', beforeAjaxFormSubmission);
        handleEvent($form, 'ajax:stopped',    onAjaxStopped);
        handleEvent($form, 'ajax:success',    onAjaxFormSubmissionSuccess);
        handleEvent($form, 'ajax:error',      onAjaxFormSubmissionError);
        handleEvent($form, 'ajax:complete',   onAjaxFormSubmissionComplete);

        /**
         * Before the XHR request is generated.
         *
         * @param {object} arg
         */
        function beforeAjax(arg) {
            debugXhr('ajax:before - arguments', Array.from(arguments));
        }

        /**
         * Pre-process form fields before the form is actually submitted.
         *
         * @param {object} arg
         */
        function beforeAjaxFormSubmission(arg) {
            debugXhr('ajax:beforeSend - arguments', Array.from(arguments));

            // Disable empty database fields so they are not transmitted back
            // as form data.
            inputFields($form).each(function() {
                if (isEmpty(this.value) || (this.value === EMPTY_VALUE)) {
                    this.disabled = true;
                }
            });

            // If the source repository control is disabled (when editing a
            // completed submission), re-enable it so that it *is* transmitted.
            let $repo = sourceRepositoryMenu($form);
            if ($repo.prop('disabled')) {
                $repo.prop('disabled', false);
            }
        }

        /**
         * Called if "ajax:before" or 'ajax:beforeSend' rejects the request.
         *
         * @param {object} arg
         */
        function onAjaxStopped(arg) {
            debugXhr('ajax:stopped - arguments', Array.from(arguments));
        }

        /**
         * Process rails-ujs 'ajax:success' event data.
         *
         * @param {object} arg
         */
        function onAjaxFormSubmissionSuccess(arg) {
            debugXhr('ajax:success - arguments', Array.from(arguments));
            const data  = arg.data;
            const event = arg.originalEvent || {};
            // noinspection JSUnusedLocalSymbols
            const [_resp, _status_text, xhr] = event.detail || [];
            const status = xhr.status;
            onCreateSuccess(data, status, xhr);
        }

        /**
         * Process rails-ujs 'ajax:error' event data.
         *
         * @param {object} arg
         */
        function onAjaxFormSubmissionError(arg) {
            debugXhr('ajax:error - arguments', Array.from(arguments));
            const error = arg.data;
            const event = arg.originalEvent || {};
            // noinspection JSUnusedLocalSymbols
            const [_resp, _status_text, xhr] = event.detail || [];
            const status = xhr.status;
            consoleError('ajax:error', status, 'error', error, 'xhr', xhr);
            onCreateError(xhr, status, error);
        }

        /**
         * Process rails-ujs 'ajax:complete' event data.
         *
         * @param {object} arg
         */
        function onAjaxFormSubmissionComplete(arg) {
            debugXhr('ajax:complete - arguments', Array.from(arguments));
            onCreateComplete();
        }

        /**
         * When called this indicates that Shrine has validated the uploaded
         * file and has created an Upload record which references it.
         *
         * @param {object}         data
         * @param {string}         status
         * @param {XMLHttpRequest} xhr
         */
        function onCreateSuccess(data, status, xhr) {
            const func  = 'onCreateSuccess';
            const flash = compact(extractFlashMessage(xhr));
            const entry = (flash.length > 1) ? 'entries' : 'entry'; // TODO: I18n
            let message = `EMMA ${entry} ${termActionOccurred()}`;  // TODO: I18n
            if (isPresent(flash)) {
                message += ' for: ' + flash.join(', ');
            }
            debug(`${func}:`, message);
            showFlashMessage(message);
            setFormSubmitted($form);
        }

        /**
         * When called this indicates that there was problem (e.g. a validation
         * error) which has prevented the creation of an Upload record.  This
         * also indicates that the previously-uploaded file has been removed
         * from storage.
         *
         * @param {XMLHttpRequest} xhr
         * @param {string}         status
         * @param {string}         error
         */
        function onCreateError(xhr, status, error) {
            const func   = 'onCreateError';
            const flash  = compact(extractFlashMessage(xhr));
            const action = termAction($form).toUpperCase();
            let message  = `${action} ERROR:`; // TODO: I18n
            if (flash.length > 1) {
                message += "\n" + flash.join("\n");
            } else if (flash.length === 1) {
                message += ' ' + flash[0];
            } else {
                message += ` ${status}: ${error}`;
            }
            consoleWarn(`${func}:`, message);
            showFlashError(message);
            requireFormCancellation($form);
        }

        /**
         * Restore empty database fields at the end of the submission response.
         *
         * @param {XMLHttpRequest} [xhr]
         * @param {string}         [status]
         */
        function onCreateComplete(xhr, status) {
            databaseInputFields($form).each(function() {
                this.disabled = false;
            });
        }
    }

    // ========================================================================
    // Functions - form field filtering
    // ========================================================================

    // noinspection ES6ConvertVarToLetConst
    /**
     * A flag to indicate whether field filtering has occurred yet.
     *
     * @type {boolean}
     */
    var filter_initialized = false;

    /**
     * The current field filtering selection.
     *
     * @param {Selector} [form]  Passed to {@link fieldDisplayFilterContainer}.
     *
     * @returns {string}
     */
    function fieldDisplayFilterCurrent(form) {
        return fieldDisplayFilterContainer(form).find(':checked').val();
    }

    /**
     * Update the current field filtering selection.
     *
     * @param {Selector} [form]    Passed to {@link fieldDisplayFilterButtons}.
     * @param {string}   [new_mode]
     */
    function fieldDisplayFilterSelect(form, new_mode) {
        let $form  = formElement(form);
        let $radio = fieldDisplayFilterButtons($form);
        let mode;
        if (isDefined(new_mode)) {
            mode = new_mode;
        } else {
            const current_action = termAction($form);
            let [action, general, first] = [];
            $.each(PROPERTIES.Filter, function(group, property) {
                if (property.default === current_action) {
                    action = group;
                } else if (property.default) {
                    general = group;
                } else {
                    first = first || group;
                }
            });
            mode = action || general || first;
        }
        let selector = `[value="${mode}"]`;
        $radio.filter(selector).prop('checked', true).change();
    }

    /**
     * Listen for changes on field display filter selection.
     *
     * @param {Selector} [form]  Passed to {@link fieldDisplayFilterButtons}.
     *
     * @see "BaseDecorator::Form#field_group_controls"
     */
    function monitorFieldDisplayFilterButtons(form) {

        let $form    = formElement(form);
        let $buttons = fieldDisplayFilterButtons($form);
        handleEvent($buttons, 'change', fieldDisplayFilterHandler);

        /**
         * Update field display filtering if the target is checked.
         *
         * @param {jQuery.Event} event
         */
        function fieldDisplayFilterHandler(event) {
            let $target = $(event.target);
            if ($target.is(':checked')) {
                filterFieldDisplay($target.val(), $form);
            }
        }
    }

    /**
     * Update field display filtering.
     *
     * @param {string|null} [new_mode]
     * @param {Selector}    [form_sel]
     *
     * @overload filterFieldDisplay(new_mode, form_sel)
     *  @param {string|null} new_mode
     *  @param {Selector}    [form_sel]
     *
     * @overload filterFieldDisplay(form_sel)
     *  @param {Selector}    form_sel
     *
     * @see "BaseDecorator::Form#field_group_controls"
     */
    function filterFieldDisplay(new_mode, form_sel) {
        const func = 'filterFieldDisplay';
        const obj  = (typeof new_mode === 'object');
        const form = obj ? new_mode  : form_sel;
        let $form  = formElement(form);
        const mode =
            (obj ? undefined : new_mode) || fieldDisplayFilterCurrent($form);
        switch (mode) {
            case 'available': fieldDisplayAvailable($form); break;
            case 'invalid':   fieldDisplayInvalid($form);   break;
            case 'filled':    fieldDisplayFilled($form);    break;
            case 'all':       fieldDisplayAll($form);       break;
            default:          consoleError(`${func}: invalid mode:`, mode);
        }
        // Scroll so that the first visible field is at the top of the display
        // beneath the field display controls.
        if (filter_initialized) {
            $form[0].scrollIntoView();
        } else {
            filter_initialized = true;
        }
    }

    /**
     * Show fields that have data (plus required fields whether or not they
     * have data).
     *
     * @param {Selector} [form]       Passed to {@link fieldDisplayOnly}.
     */
    function fieldDisplayFilled(form) {
        fieldDisplayOnly('.valid:not(.disabled)', form);
    }

    /**
     * Show only required fields that are missing values and fields with values
     * which are invalid.
     *
     * @param {Selector} [form]       Passed to {@link fieldDisplayOnly}.
     */
    function fieldDisplayInvalid(form) {
        fieldDisplayOnly('.invalid:not(.disabled)', form);
    }

    /**
     * Show fields that are modifiable by the user.
     *
     * @param {Selector} [form]       Passed to {@link fieldDisplayExcept}.
     */
    function fieldDisplayAvailable(form) {
        fieldDisplayExcept('.disabled', form);
    }

    /**
     * Show all fields including internal fields that are not modifiable.
     *
     * @param {Selector} [form]       Passed to {@link fieldContainer}.
     */
    function fieldDisplayAll(form) {
        fieldContainer(form).children().show().filter('.no-fields').hide();
    }

    /**
     * Show only the matching fields.
     *
     * @param {Selector} match        Selector for visible fields.
     * @param {Selector} [form]       Passed to {@link fieldContainer}.
     */
    function fieldDisplayOnly(match, form) {
        let $fields    = fieldContainer(form).children().hide();
        let $visible   = $fields.filter(match);
        let $no_fields = $fields.filter('.no-fields');
        if (isPresent($visible)) {
            $visible.show();
            $no_fields.hide();
        } else {
            $no_fields.show();
        }
    }

    /**
     * Hide the matching fields.
     *
     * @param {Selector} match        Selector for hidden fields.
     * @param {Selector} [form]       Passed to {@link fieldContainer}.
     */
    function fieldDisplayExcept(match, form) {
        let $fields = fieldContainer(form).children().show();
        $fields.filter(match).hide();
        $fields.filter('.no-fields').hide();
    }

    // ========================================================================
    // Functions - display manipulation
    // ========================================================================

    /**
     * Set a temporary tooltip.
     *
     * @param {Selector} element
     * @param {string}   [text]       Default: no tooltip
     */
    function setTooltip(element, text) {
        let $element = $(element);
        let old_tip  = $element.attr('data-title');
        if (isMissing(old_tip)) {
            old_tip = $element.attr('title');
            if (isPresent(old_tip)) {
                $element.attr('data-title', old_tip);
            }
        }
        if (isPresent(text)) {
            $element.attr('title', text);
        } else {
            $element.removeAttr('title');
        }
    }

    /**
     * Remove a temporary tooltip.
     *
     * @param {Selector} element
     */
    function restoreTooltip(element) {
        let $element  = $(element);
        const old_tip = $element.attr('data-title');
        if (isPresent(old_tip)) {
            $element.attr('title', old_tip);
        } else {
            $element.removeAttr('title');
        }
    }

    /**
     * Change a status marker icon.
     *
     * @param {Selector} element
     * @param {string}   [icon]       Default: no icon.
     */
    function setIcon(element, icon) {
        let $element = $(element);
        let old_icon = $element.attr('data-icon');
        if (isMissing(old_icon)) {
            old_icon = $element.text();
            if (isPresent(old_icon)) {
                $element.attr('data-icon', old_icon);
            }
        }
        const new_icon = icon || PROPERTIES.Status.blank.label;
        $element.text(new_icon);
    }

    /**
     * Change the previous status marker icon.
     *
     * @param {Selector} element
     */
    function restoreIcon(element) {
        let $element   = $(element);
        const old_icon = $element.attr('data-icon') || '';
        $element.text(old_icon);
    }

    // ========================================================================
    // Functions - elements
    // ========================================================================

    /**
     * The given form element or the first file upload form on the page.
     *
     * @param {Selector} [form]       Default: FORM_SELECTOR.
     *
     * @returns {jQuery}
     */
    function formElement(form) {
        let $form = form && $(form);
        if ($form && !$form.is(FORM_SELECTOR)) {
            $form = $form.parents(FORM_SELECTOR);
        }
        if (isMissing($form)) {
            const bulk = isMissing($model_form);
            $form = bulk ? $bulk_op_form : $model_form;
        }
        return $form.first();
    }

    /**
     * The hidden element with information supporting reversion of the record
     * when canceling/aborting a modification submission.
     *
     * @param {Selector} [form]       Default: {@link formElement}.
     *
     * @returns {jQuery}
     */
    function revertDataElement(form) {
        return formElement(form).find('#revert_data');
    }

    /**
     * The hidden element with metadata information supplied by the server.
     *
     * @param {Selector} [form]       Default: {@link formElement}.
     *
     * @returns {jQuery}
     */
    function emmaDataElement(form) {
        return formElement(form).find(`#${MODEL}_emma_data`);
    }

    /**
     * The hidden element with file metadata information maintained by Uppy.
     *
     * @param {Selector} [form]       Default: {@link formElement}.
     *
     * @returns {jQuery}
     */
    function fileDataElement(form) {
        return formElement(form).find(`#${MODEL}_file_data`);
    }

    /**
     * All elements that are or that contain form field inputs.
     *
     * @param {Selector} [form]       Default: {@link formElement}.
     *
     * @returns {jQuery}
     */
    function formFields(form) {
        return formElement(form).find('[data-field]');
    }

    /**
     * The element that maintains the given form field.
     *
     * @param {string}   field
     * @param {Selector} [form]       Default: {@link formElement}.
     *
     * @returns {jQuery}
     */
    function formField(field, form) {
        return formElement(form).find(`[data-field="${field}"]`);
    }

    /**
     * The database ID or submission ID assigned to the current submission.
     *
     * @param {Selector} form
     *
     * @returns { {id: string} | {submission_id: string} | {} }
     */
    function submissionParams(form) {
        if (MODEL === 'entry') {
            const value = formField('submission_id', form).val();
            if (value) { return { submission_id: value } }
            console.warn(`No submission ID for ${MODEL}`);
        } else {
            const value = formField('id', form).val();
            if (value) { return { id: value } }
            console.warn(`No database record ID for ${MODEL}`);
        }
        return {};
    }

    /**
     * The control button container.
     *
     * @param {Selector} [form]       Default: {@link formElement}.
     *
     * @returns {jQuery}
     *
     * @see "BaseDecorator::Form#model_form"
     * @see Uploader.buttonTray
     */
    function buttonTray(form) {
        return formElement(form).find('.button-tray');
    }

    /**
     * The submit button.
     *
     * @param {Selector} [form]       Default: {@link formElement}.
     *
     * @returns {jQuery}
     *
     * @see "BaseDecorator::Form#submit_button"
     */
    function submitButton(form) {
        return buttonTray(form).children('.submit-button');
    }

    /**
     * The cancel button.
     *
     * @param {Selector} [form]       Default: {@link formElement}.
     *
     * @returns {jQuery}
     *
     * @see setupCancelButton
     * @see "BaseDecorator::Form#cancel_button"
     */
    function cancelButton(form) {
        return buttonTray(form).children('.cancel-button');
    }

    /**
     * The container for the field filtering controls.
     *
     * @param {Selector} [form]       Default: {@link formElement}.
     *
     * @returns {jQuery}
     */
    function fieldDisplayFilterContainer(form) {
        return formElement(form).find('.field-group');
    }

    /**
     * Field display filter radio buttons.
     *
     * @param {Selector} [form]  Passed to {@link fieldDisplayFilterContainer}.
     *
     * @returns {jQuery}
     */
    function fieldDisplayFilterButtons(form) {
        return fieldDisplayFilterContainer(form).find('input[type="radio"]');
    }

    /**
     * The container element for all input fields and their labels.
     *
     * @param {Selector} [form]       Default: {@link formElement}.
     *
     * @returns {jQuery}
     */
    function fieldContainer(form) {
        return formElement(form).find('.form-fields');
    }

    /**
     * All input fields.
     *
     * @param {Selector} [form]       Passed to {@link fieldContainer}.
     *
     * @returns {jQuery}
     */
    function inputFields(form) {
        return fieldContainer(form).find(FORM_FIELD_SELECTOR);
    }

    /**
     * Input fields directly associated with database columns.
     *
     * @param {Selector} [form]       Passed to {@link inputFields}.
     *
     * @returns {jQuery}
     */
    function databaseInputFields(form) {
        return inputFields(form).filter('[readonly]');
    }

    /**
     * Containers for groups of checkboxes.
     *
     * @param {Selector} [form]       Passed to {@link fieldContainer}.
     *
     * @returns {jQuery}
     */
    function menuMultiFields(form) {
        return fieldContainer(form).find('.menu.multi.value[data-field]');
    }

    // ========================================================================
    // Functions - form status
    // ========================================================================

    /**
     * Indicate whether the form is ready to submit.
     *
     * @param {Selector} [form]       Passed to {@link submitButton}.
     *
     * @returns {boolean}
     */
    function canSubmit(form) {
        return submitButton(form).attr('data-state') === 'ready';
    }

    /**
     * Indicate whether the form can be canceled.
     *
     * @param {Selector} [form]       Passed to {@link cancelButton}.
     *
     * @returns {boolean}
     */
    function canCancel(form) {
        return true; // TODO: canCancel?
    }

    /**
     * Mark the form submission state as submitted.
     *
     * @param {Selector} [form]       Default: {@link formElement}.
     */
    function setFormSubmitting(form) {
        setFormState(form, FORM_STATE.SUBMITTING);
    }

    /**
     * Mark the form submission state as complete.
     *
     * @param {Selector} [form]       Default: {@link formElement}.
     */
    function setFormSubmitted(form) {
        setFormState(form, FORM_STATE.SUBMITTED);
    }

    /**
     * Mark the form submission state as canceled.
     *
     * @param {Selector} [form]       Default: {@link formElement}.
     */
    function setFormCanceled(form) {
        setFormState(form, FORM_STATE.CANCELED);
    }

    /**
     * If the submission can't proceed, this method will force the submission
     * to be cleaned-up rather than continuing with the submission record
     * possibly invalid or deleted.
     *
     * @param {Selector} [form]       Default: {@link formElement}.
     */
    function requireFormCancellation(form) {
        let $form     = formElement(form);
        const message = 'Cancel this submission before retrying'; // TODO: I18n
        const tooltip = { 'title': message };
        uploader?.cancel();
        uploader?.disableFileSelectButton()?.attr(tooltip);
        disableSubmit($form).attr(tooltip);
        fieldContainer($form).attr(tooltip);
        inputFields($form).attr(tooltip).each(function() {
            this.disabled = true;
        });
        cancelButton($form).addClass('best-choice');
    }

    /**
     * The state of form submission.
     *
     * @param {Selector} [form]       Default: {@link formElement}.
     *
     * @returns {string|undefined}
     */
    function formState(form) {
        const attr = 'form-state';
        return formElement(form).data(attr);
    }

    /**
     * Clear the form submission state.
     *
     * @param {Selector} [form]       Default: passed to {@link setFormState}.
     */
    function clearFormState(form) {
        setFormState(form, undefined);
    }

    /**
     * Mark the form submission state.
     *
     * @param {Selector} [form]       Default: {@link formElement}.
     * @param {*}        [state]      If missing, clears the state.
     *
     * @returns {string|undefined}
     */
    function setFormState(form, state) {
        const attr  = 'form-state';
        let $form   = formElement(form);
        const value = isDefined(state) ? state.toString() : undefined;
        if (isDefined(value)) {
            $form.data(attr, value);
        } else {
            $form.removeData(attr);
        }
        return value;
    }

    // ========================================================================
    // Functions - data properties
    // ========================================================================

    /**
     * Indicate whether the purpose of the form is for creation of a new entry.
     *
     * @param {Selector} [form]       Default: {@link formElement}.
     *
     * @returns {boolean}
     */
    function isCreateForm(form) {
        return formElement(form).hasClass('new');
    }

    /**
     * Indicate whether the purpose of the form is for update of an existing
     * entry.
     *
     * @param {Selector} [form]       Default: {@link formElement}.
     *
     * @returns {boolean}
     */
    function isUpdateForm(form) {
        return formElement(form).hasClass('edit');
    }

    /**
     * Displayable term for the action associated with the form.
     *
     * @param {Selector} [form]       Passed to {@link isUpdateForm}.
     *
     * @returns {string}
     */
    function termAction(form) {
        return isUpdateForm(form) ? 'update' : 'create'; // TODO: I18n
    }

    /**
     * Displayable term for the past-tense action associated with the form.
     *
     * @param {Selector} [form]       Passed to {@link isUpdateForm}.
     *
     * @returns {string}
     */
    function termActionOccurred(form) {
        return isUpdateForm(form) ? 'updated' : 'created'; // TODO: I18n
    }

    /**
     * The label for the Submit button.
     *
     * @param {Selector} [form]         Passed to {@link formElement}.
     * @param {boolean}  [can_submit]   Default: `canSubmit()`.
     *
     * @returns {string}
     */
    function submitLabel(form, can_submit) {
        let $form   = formElement(form);
        const asset = endpointProperties($form).submit || {};
        const state = buttonProperties($form, 'submit', can_submit, asset);
        return state?.label || asset.label;
    }

    /**
     * The tooltip for the Submit button.
     *
     * @param {Selector} [form]         Passed to {@link formElement}.
     * @param {boolean}  [can_submit]   Default: `canSubmit()`.
     *
     * @returns {string}
     */
    function submitTooltip(form, can_submit) {
        let $form   = formElement(form);
        const asset = endpointProperties($form).submit || {};
        const state = buttonProperties($form, 'submit', can_submit, asset);
        return state?.tooltip || asset?.tooltip;
    }

    /**
     * The tooltip for the Submit button after the form is validated.
     *
     * @param {Selector} [form]       Passed to {@link submitTooltip}.
     *
     * @returns {string}
     */
    function submitReadyTooltip(form) {
        return submitTooltip(form, true);
    }

    /**
     * The tooltip for the Submit button before the form is validated.
     *
     * @param {Selector} [form]       Passed to {@link submitTooltip}.
     *
     * @returns {string}
     */
    function submitNotReadyTooltip(form) {
        return submitTooltip(form, false);
    }

    /**
     * The current label for the Cancel button.
     *
     * @param {Selector} [form]         Default: {@link formElement}.
     * @param {boolean}  [can_cancel]   Default: `canCancel()`.
     *
     * @returns {string}
     */
    function cancelLabel(form, can_cancel) {
        let $form   = formElement(form);
        const asset = endpointProperties($form).cancel || {};
        const state = buttonProperties($form, 'cancel', can_cancel, asset);
        return state?.label || asset?.label;
    }

    /**
     * The current tooltip for the Cancel button.
     *
     * @param {Selector} [form]         Default: {@link formElement}.
     * @param {boolean}  [can_cancel]   Default: `canCancel()`.
     *
     * @returns {string}
     */
    function cancelTooltip(form, can_cancel) {
        let $form   = formElement(form);
        const asset = endpointProperties($form).cancel || {};
        const state = buttonProperties($form, 'cancel', can_cancel, asset);
        return state?.tooltip || asset?.tooltip;
    }

    /**
     * Get label/tooltip properties for the indicated operation depending on
     * whether it is enabled or disabled.
     *
     * @param {Selector}         form     Passed to {@link endpointProperties}.
     * @param {string}           op_name  Name of the operation.
     * @param {boolean}    [can_perform]  Pre-determined enabled/disabled state
     * @param {ActionProperties} [asset]  Pre-fetched property values.
     *
     * @returns {ElementProperties|null}
     *
     * @see Uploader.buttonProperties
     */
    function buttonProperties(form, op_name, can_perform, asset) {
        const func  = 'buttonProperties';
        let $form   = formElement(form);
        let perform = can_perform;
        if (notDefined(perform)) {
            switch (op_name) {
                case 'submit': perform = canSubmit($form); break;
                case 'cancel': perform = canCancel($form); break;
                //case 'select': perform = canSelect($form); break;
                default:       consoleError(`${func}: invalid: "${op_name}"`);
            }
        }
        const op = asset || endpointProperties($form)[op_name];
        return op && (perform ? op.enabled : op.disabled);
    }

    /**
     * Get the configuration properties for the current form action.
     *
     * @param {Selector} [form]       Passed to {@link isUpdateForm}.
     *
     * @returns {EndpointProperties}
     *
     * @see Uploader.#endpointProperties
     */
    function endpointProperties(form) {
        let $form    = formElement(form);
        const action = PROPERTIES.Action || {};
        if (isBulkOpForm($form)) {
            return isUpdateForm($form) ? action.bulk_edit : action.bulk_new;
        } else {
            return isUpdateForm($form) ? action.edit : action.new;
        }
    }

    // ========================================================================
    // Functions - flash messages
    // ========================================================================

    /**
     * Show flash messages (unless disabled).
     *
     * @param {string} text
     */
    function showFlashMessage(text) {
        if (FEATURES.flash_messages) {
            flashMessage(text);
        }
    }

    /**
     * Show flash errors (unless disabled).
     *
     * @param {string} text
     */
    function showFlashError(text) {
        if (FEATURES.flash_errors) {
            flashError(text);
        }
    }

    /**
     * Invoke clearFlash() and return void.
     *
     * @param {jQuery.Event} [event]    Ignored.
     */
    function clearFlashMessages(event) {
        clearFlash();
    }

    // ========================================================================
    // Functions - other
    // ========================================================================

    /**
     * Indicate whether the HTTP status code should be treated as a temporary
     * condition.
     *
     * @param {number} code
     *
     * @returns {boolean}
     */
    function transientError(code) {
        switch (code) {
            case HTTP.service_unavailable:
            case HTTP.gateway_timeout:
                return true;
            default:
                return false;
        }
    }

    /**
     * Emit a console message if debugging.
     *
     * @param {...*} args
     */
    function debug(...args) {
        if (DEBUGGING) { consoleLog(...args); }
    }

    /**
     * Emit a console message if debugging.
     *
     * @param {...*} args
     */
    function debugSection(...args) {
        if (DEBUGGING) { consoleWarn('>>>>>', ...args, '<<<<<'); }
    }

    /**
     * Emit a console message if debugging communications.
     *
     * @param {...*} args
     */
    function debugXhr(...args) {
        if (DEBUG.XHR) { consoleLog('XHR:', ...args); }
    }

});
