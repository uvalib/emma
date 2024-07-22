// app/assets/javascripts/feature/model-form.js


import { AppDebug }                        from '../application/debug';
import { appSetup }                        from '../application/setup';
import { arrayWrap }                       from '../shared/arrays';
import { Emma }                            from '../shared/assets';
import { pageController }                  from '../shared/controller';
import { FORM_FIELD, turnOffAutocomplete } from '../shared/form';
import * as HTTP                           from '../shared/http';
import { LOOKUP_BUTTON, LookupModal }      from '../shared/lookup-modal';
import { LookupRequest }                   from '../shared/lookup-request';
import { K, asSize }                       from '../shared/math';
import { CheckboxGroup, TextInputGroup }   from '../shared/nav-group';
import { SearchInProgress }                from '../shared/search-in-progress';
import { SingleUploader, UPLOADER }        from '../shared/uploader';
import { cancelAction, makeUrl }           from '../shared/url';
import { responseErrors, transientError }  from '../shared/xhr';
import { Rails }                           from '../vendor/rails';
import {
    delegateInputClick,
    handleClickAndKeypress,
} from '../shared/accessibility';
import {
    selector,
    toggleClass,
    toggleHidden,
} from '../shared/css';
import {
    isDefined,
    isEmpty,
    isMissing,
    isPresent,
    notDefined,
    presence,
} from '../shared/definitions';
import {
    delayedBy,
    handleEvent,
    onPageExit,
} from '../shared/events';
import {
    clearFlash,
    extractFlashMessage,
    flashError,
    flashMessage,
} from '../shared/flash';
import {
    CHECKBOX,
    htmlDecode,
    sameElements,
    scrollIntoView,
    selfOrParent,
} from '../shared/html';
import {
    compact,
    deepDup,
    deepFreeze,
    dup,
    fromJSON,
    toObject,
} from '../shared/objects';
import {
    asString,
    camelCase,
    capitalize,
    pluralize,
    singularize,
} from '../shared/strings';
import {
    SECONDS,
    asDateTime,
    secondsSince,
    timeOf,
} from '../shared/time';


const MODULE = 'ModelForm';
const DEBUG  = true;

AppDebug.file('feature/model-form', MODULE, DEBUG);

// noinspection FunctionTooLongJS
appSetup(MODULE, function() {

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
     * @type {string}
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
    const $model_form = $(MODEL_FORM_SELECTOR);

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
    const $bulk_op_form = $(BULK_FORM_SELECTOR).not('.delete');

    // Only perform these actions on the appropriate pages.
    if (isMissing($model_form) && isMissing($bulk_op_form)) { return }

    /**
     * Console output functions for this module.
     */
    const OUT = AppDebug.consoleLogging(MODULE, DEBUG);

    // ========================================================================
    // Type definitions
    // ========================================================================

    /**
     * Shrine upload information for the submission.
     *
     * @typedef {object} FileDataMetadata
     *
     * @property {string} filename
     * @property {number} size
     * @property {string} mime_type
     */

    /**
     * Shrine upload information for the submission.
     *
     * @typedef {object} FileData
     *
     * @property {string}           id
     * @property {string}           storage
     * @property {FileDataMetadata} metadata
     *
     * @see "en.emma.record.upload.file_data"
     * @see "Shrine::InstanceMethods#upload"
     */

    /**
     * Normally *string[]* but may be received as *string*.
     *
     * @typedef {string[]|string} multiString
     */

    /**
     * Normally *string* but may be received as *string[]*.
     *
     * @typedef {string|string[]} singleString
     */

    /**
     * EMMA metadata for the submission.
     *
     * @typedef {object} EmmaData
     *
     * @property {string}       emma_recordId
     * @property {string}       emma_titleId
     * @property {string}       emma_repository
     * @property {multiString}  emma_collection
     * @property {string}       emma_repositoryRecordId
     * @property {string}       emma_retrievalLink
     * @property {string}       emma_webPageLink
     * @property {string}       emma_lastRemediationDate
     * @property {string}       emma_sortDate
     * @property {string}       emma_repositoryUpdateDate
     * @property {string}       emma_repositoryMetadataUpdateDate
     * @property {string}       emma_publicationDate
     * @property {string}       emma_lastRemediationNote
     * @property {string}       emma_formatVersion
     * @property {multiString}  emma_formatFeature
     * @property {singleString} dc_title
     * @property {multiString}  dc_creator
     * @property {multiString}  dc_identifier
     * @property {singleString} dc_publisher
     * @property {multiString}  dc_relation
     * @property {multiString}  dc_language
     * @property {singleString} dc_rights
     * @property {singleString} dc_description
     * @property {singleString} dc_format
     * @property {singleString} dc_type
     * @property {multiString}  dc_subject
     * @property {singleString} dcterms_dateAccepted
     * @property {singleString} dcterms_dateCopyright
     * @property {multiString}  s_accessibilityFeature
     * @property {multiString}  s_accessibilityControl
     * @property {multiString}  s_accessibilityHazard
     * @property {multiString}  s_accessMode
     * @property {multiString}  s_accessModeSufficient
     * @property {singleString} s_accessibilitySummary
     * @property {singleString} rem_source
     * @property {multiString}  rem_metadataSource
     * @property {multiString}  rem_remediatedBy
     * @property {boolean}      rem_complete
     * @property {singleString} rem_coverage
     * @property {multiString}  rem_remediation
     * @property {multiString}  rem_remediatedAspects
     * @property {singleString} rem_textQuality
     * @property {singleString} rem_quality
     * @property {singleString} rem_status
     * @property {singleString} rem_remediationDate
     * @property {singleString} rem_comments
     * @property {singleString} rem_remediationComments
     * @property {singleString} bib_series
     * @property {singleString} bib_seriesType
     * @property {singleString} bib_seriesPosition
     *
     * @see "en.emma.record.upload.emma_data"
     * @see "AwsS3::Record::SubmissionRequest"
     */

    /**
     * @typedef {object} RecordMessageProperties
     *
     * @property {number} total
     * @property {number} [limit]
     * @property {array}  [links]
     * @property {string} [list_type]   Only present for `#session_debug?`
     * @property {string} [item_type]   Only present for `#session_debug?`
     */

    /**
     * A complete submission database record.
     *
     * @typedef {object} UploadRecord
     *
     * @property {number}   id
     * @property {FileData} file_data
     * @property {EmmaData} emma_data
     * @property {number}   user_id
     * @property {string}   repository
     * @property {string}   submission_id
     * @property {string}   fmt
     * @property {string}   ext
     * @property {string}   state
     * @property {string}   created_at
     * @property {string}   updated_at
     * @property {string}   phase
     * @property {string}   edit_state
     * @property {string}   edit_user
     * @property {FileData} edit_file_data
     * @property {EmmaData} edit_emma_data
     * @property {string}   edited_at
     * @property {string}   review_user
     * @property {string}   review_success
     * @property {string}   review_comment
     * @property {string}   reviewed_at
     *
     * @see "en.emma.record.upload"
     */

    /**
     * @typedef {UploadRecord} SubmissionRecord
     */

    /**
     * @typedef {UploadRecord[]} SubmissionRecords
     */

    /**
     * @typedef {object} RecordMessageTable
     *
     * @property {RecordMessageProperties} properties
     * @property {UploadRecord[]}          list
     */

    /**
     * JSON format of a response message containing a list of submissions.
     *
     * @typedef {object} UploadRecordMessage
     *
     * @property {RecordMessageTable} entries
     */

    /**
     * @typedef {UploadRecordMessage} SubmissionRecordMessage
     */

    /**
     * @typedef {function(UploadRecord[])} SubmissionRecordsCB
     */

    /**
     * A single search result entry.
     *
     * @typedef {object} SearchResultEntry
     *
     * @property {string}   emma_recordId
     * @property {string}   emma_titleId
     * @property {string}   emma_repository
     * @property {string[]} emma_collection
     * @property {string}   emma_repositoryRecordId
     * @property {string}   emma_retrievalLink
     * @property {string}   emma_webPageLink
     * @property {string}   [emma_lastRemediationDate]
     * @property {string}   [emma_sortDate]
     * @property {string}   [emma_repositoryUpdateDate]
     * @property {string}   [emma_repositoryMetadataUpdateDate]
     * @property {string}   [emma_publicationDate]
     * @property {string}   [emma_lastRemediationNote]
     * @property {string}   [emma_version]
     * @property {string}   emma_formatVersion
     * @property {string[]} [emma_formatFeature]
     * @property {string}   dc_title
     * @property {string[]} [dc_creator]
     * @property {string[]} [dc_identifier]
     * @property {string[]} [dc_relation]
     * @property {string}   [dc_publisher]
     * @property {string[]} [dc_language]
     * @property {string}   [dc_rights]
     * @property {string}   [dc_description]
     * @property {string}   [dc_format]
     * @property {string}   [dc_type]
     * @property {string[]} [dc_subject]
     * @property {string}   [dcterms_dateAccepted]
     * @property {string}   [dcterms_dateCopyright]
     * @property {string[]} [s_accessibilityFeature]
     * @property {string[]} [s_accessibilityControl]
     * @property {string[]} [s_accessibilityHazard]
     * @property {string}   [s_accessibilitySummary]
     * @property {string[]} [s_accessMode]
     * @property {string[]} [s_accessModeSufficient]
     * @property {string}   [rem_source]
     * @property {string[]} [rem_metadataSource]
     * @property {string[]} [rem_remediatedBy]
     * @property {boolean}  [rem_complete]
     * @property {string}   [rem_coverage]
     * @property {string[]} [rem_remediatedAspects]
     * @property {string}   [rem_textQuality]
     * @property {string}   [rem_quality]
     * @property {string}   [rem_status]
     * @property {string}   [rem_remediationDate]
     * @property {string}   [rem_comments]
     * @property {string}   [rem_remediationComments]
     *
     * @see "en.emma.record.search"
     */

    /**
     * @typedef {object} SearchResultMessageTable
     *
     * @property {RecordMessageProperties} properties
     * @property {SearchResultEntry[]}     records
     */

    /**
     * JSON format of a response message containing a list of search results.
     *
     * @typedef {object} SearchResultMessage
     *
     * @property {SearchResultMessageTable} response
     */

    /**
     * Field relationship.
     *
     * @typedef {object} Relationship
     *
     * @property {string}           name
     * @property {boolean|function} [required]
     * @property {boolean|function} [unrequired]
     * @property {string}           [required_val]
     * @property {string}           [unrequired_val]
     */

    // ========================================================================
    // Constants
    // ========================================================================

    /* Show flash info messages */   const FLASH_MESSAGES = true;
    /* Show flash error messages */  const FLASH_ERRORS   = true;

    /* Log low-level keystrokes */   const DEBUG_INPUT    = false;
    /* Log external communication */ const DEBUG_XHR      = true;

    /**
     * Milliseconds to wait after the user enters characters into a field
     * before re-validating the form.
     *
     * @readonly
     * @type {number}
     *
     * @see monitorInputFields
     */
    const REVALIDATE_DELAY = 500;

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
    const EMPTY_VALUE = Emma.Field.empty;

    /**
     * Generic form selector.
     *
     * @readonly
     * @type {string}
     */
    const FORM_SELECTOR = MODEL_FORM_SELECTOR + ',' + BULK_FORM_SELECTOR;

    const BUTTON_TRAY_CLASS     = 'button-tray';
    const SUBMIT_BUTTON_CLASS   = 'submit-button';
    const CANCEL_BUTTON_CLASS   = 'cancel-button';
    const FIELD_GROUP_CLASS     = 'field-group';
    const FIELD_CONTAINER_CLASS = 'form-fields';
    const SYMBOL_CLASS          = 'symbol';

    const VALID_MARKER          = 'valid';
    const INVALID_MARKER        = 'invalid';
    const REQUIRED_MARKER       = 'required';
    const BEST_CHOICE_MARKER    = 'best-choice';

    const MENU_CLASS            = 'menu';
    const INPUT_CLASS           = 'input';
    const MULTI_CLASS           = 'multi';
    const SINGLE_CLASS          = 'single';

    const BUTTON_TRAY           = selector(BUTTON_TRAY_CLASS);
    const SUBMIT_BUTTON         = selector(SUBMIT_BUTTON_CLASS);
    const CANCEL_BUTTON         = selector(CANCEL_BUTTON_CLASS);
    const FIELD_GROUP           = selector(FIELD_GROUP_CLASS);
    const FIELD_CONTAINER       = selector(FIELD_CONTAINER_CLASS);
    const SYMBOL                = selector(SYMBOL_CLASS);

    const VALID                 = selector(VALID_MARKER);
    const INVALID               = selector(INVALID_MARKER);
  //const REQUIRED              = selector(REQUIRED_MARKER);
  //const BEST_CHOICE           = selector(BEST_CHOICE_MARKER);

    const MENU_MULTI            = `.${MENU_CLASS}.${MULTI_CLASS}`;
    const MENU_SINGLE           = `.${MENU_CLASS}.${SINGLE_CLASS}`;
    const INPUT_MULTI           = `.${INPUT_CLASS}.${MULTI_CLASS}`;
    const INPUT_SINGLE          = `.${INPUT_CLASS}.${SINGLE_CLASS}`;

    /**
     * Interrelated elements.  For example: <p/>
     *
     * If "rem_complete" is set to **true**, then "rem_coverage" is no longer
     * required.  Conversely, if "rem_coverage" is given a value then that
     * implies that "rem_complete" is **false**.
     *
     * @readonly
     * @type {Object.<string,Relationship>}
     */
    const FIELD_RELATIONSHIP = deepFreeze({
        rem_complete: {
            name:           'rem_coverage',
            required:       el => ($(el).val() !== 'true'),
            unrequired_val: ''
        },
        rem_coverage: {
            name:           'rem_complete',
            required:       el => isMissing($(el).val()),
            required_val:   '',
            unrequired_val: 'false'
        },
        password: {
            name:           'password_confirmation',
            required:       el => $(el).is(VALID),
        }
    });

    /**
     * State of the page.
     *
     * - SUBMITTING:  The submit button has been activated.
     * - SUBMITTED:   The submission has been completed.
     * - CANCELED:    The cancel button has been activated.
     *
     * @readonly
     * @type {StringTable}
     */
    const FORM_STATE = deepFreeze({
        SUBMITTING: 'submitting',
        SUBMITTED:  'submitted',
        CANCELED:   'canceled'
    });

    /**
     * Key for the data() value holding the state of the form.
     *
     * @readonly
     * @type {string}
     */
    const FORM_STATE_DATA = 'formState';

    const CREATE  = Emma.Messages.form.action.create;
    const CREATED = Emma.Messages.form.action.created;
    const UPDATE  = Emma.Messages.form.action.update;
    const UPDATED = Emma.Messages.form.action.updated;

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
     * @type {
     *      Object.<string,(boolean|string|function(string|string[]):boolean)>
     * }
     */
    const FIELD_VALIDATION = deepFreeze({
        dc_identifier: ID_VALIDATE_URL_BASE,
        dc_relation:   ID_VALIDATE_URL_BASE,
    });

    // ========================================================================
    // Constants - source repository
    // ========================================================================

    /**
     * Selector for the mini dialog used to find a parent EMMA entry.
     *
     * @readonly
     * @type {string}
     */
    const PARENT_SELECT = '.parent-entry-select';

    /**
     * Selector for the search term input used to find a parent EMMA entry.
     *
     * @readonly
     * @type {string}
     */
    const PARENT_SEARCH_INPUT  = '#parent-entry-search';

    const PARENT_SEARCH_SUBMIT = '.search-button';
    const PARENT_SEARCH_CANCEL = '.search-cancel';

    const FIXED_MARKER  = 'fixed';
    const SEALED_MARKER = 'sealed';

    const FIXED         = selector(FIXED_MARKER);
    const SEALED        = selector(SEALED_MARKER);

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
    const TMP_LINE_TEXT = Emma.Messages.uploader.placeholder;

    // ========================================================================
    // Functions - Uploader
    // ========================================================================

    /** @type {SingleUploader|null} */
    let uploader;

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
        return formElement(form).is(UPLOADER);
    }

    /**
     * Initialize the file uploader if the form requires it.
     *
     * @param {Selector} form
     *
     * @returns {SingleUploader|null}
     */
    function initializeFileUploader(form) {
        if (notDefined(uploader)) {
            const $form = $(form);
            uploader = isFileUploader($form) ? newUploader($form) : null;
        }
        return uploader;
    }

    /**
     * Create a new uploader instance.
     *
     * @param {Selector} form
     *
     * @returns {SingleUploader}
     */
    function newUploader(form) {
        // noinspection JSUnusedGlobalSymbols
        const cb    = { onSelect, onStart, onError, onSuccess };
        const $form = $(form);
        const state = {
            new:    isNewForm($form),
            edit:   isEditForm($form),
            bulk:   isBulkOpForm($form),
        };
        const features = { debugging: DEBUG };
        const instance = new SingleUploader($form, MODEL, features, state, cb);
        // noinspection JSValidateTypes
        return instance.initialize();

        /**
         * Callback invoked when the file select button is pressed.
         *
         * @param {ElementEvt} [_event]   Ignored.
         */
        function onSelect(_event) {
            clearFlash();
        }

        /**
         * This event occurs between the "file-added" and "upload-started"
         * events. <p/>
         *
         * The current value of the submission's database ID applied to the
         * upload endpoint URL in order to correlate the upload with the
         * appropriate workflow.
         *
         * @param {UppyFileUploadStartData} _data
         *
         * @returns {object}          URL parameters for the remote endpoint.
         */
        function onStart(_data) {
            clearFlash();
            return submissionParams($form);
        }

        /**
         * This event occurs when the response from POST /upload/upload is
         * received with a failure status (4xx).
         *
         * @param {UppyFile}                       file
         * @param {Error}                          error
         * @param {{status: number, body: string}} [_response]
         */
        function onError(file, error, _response) {
            showFlashError(error?.message || error);
            requireFormCancellation($form);
        }

        /**
         * This event occurs when the response from POST /upload/upload is
         * received with success status (200).  At this point, the file has
         * been uploaded by Shrine, but has not yet been validated. <p/>
         *
         * **Implementation Notes** <p/>
         * The normal Shrine response has been augmented to include an
         * "emma_data" object in addition to the fields associated with
         * "file_data".
         *
         * @param {UppyFile}            file
         * @param {UppyResponseMessage} response
         *
         * @see "Shrine::UploadEndpointExt#make_response"
         */
        function onSuccess(file, response) {

            const body = response.body || {};
            let error  = undefined;

            // Save uploaded EMMA metadata.
            // noinspection JSValidateTypes
            /** @type {EmmaDataOrError} */
            const emma_data = { ...body.emma_data };
            error ||= emma_data.error;
            delete emma_data.error;
            if (isPresent(emma_data)) {
                const $emma_data = emmaDataElement($form);
                if (isPresent($emma_data)) {
                    $emma_data.val(asString(emma_data));
                }
            }
            delete body.emma_data;

            // Set hidden field value to the uploaded file data so that it is
            // submitted with the form as the attachment.
            /** @type {FileData} */
            const file_data = body.file_data || body;
            error ||= file_data?.error || body.error;
            if (file_data) {
                const $file_data = fileDataElement($form);
                if (isPresent($file_data)) {
                    $file_data.val(asString(file_data));
                }
                if (!emma_data.dc_format) {
                    const mime = file_data.metadata?.mime_type;
                    const fmt  = PROPERTIES.Mime.to_fmt[mime] || [];
                    if (fmt[0]) { emma_data.dc_format = fmt[0] }
                }
            }

            if (error) {

                // If there was a problem with the uploaded file (e.g. not an
                // expected file type) it will be reported here.
                //
                showFlashError(error);

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

        const $form = $(form);

        // Setup file uploader (if applicable).
        initializeFileUploader($form);

        // Setup buttons.
        setupSubmitButton($form);
        setupCancelButton($form);

        // Start with submit disabled until a bulk control file is supplied.
        disableSubmit($form);

        // Show the results of the most recent bulk operation (if available).
        const $results = bulkOpResults().empty().addClass(OLD_DATA_MARKER);
        const previous = getBulkOpTrace();
        if (previous && showBulkOpResults($results, previous)) {
            const $label = bulkOpResultsLabel($results);
            toggleHidden($label,   false);
            toggleHidden($results, false);
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
             * @param {InputEvt} event
             */
            function setBulkFilename(event) {
                const files    = event.target.files || [];
                const filename = (files[0] || {}).name;
                if (uploader.displayFilename(filename)) {
                    uploader.fileSelectButton().removeClass(BEST_CHOICE_MARKER)
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
     * The element containing the bulk operation results. <p/>
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
        const $results = $(results);
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
        const $results = bulkOpResults(results);
        const lbl_id   = $results.attr('aria-labelledby');
        return lbl_id ? $('#' + lbl_id) : $();
    }

    /**
     * The first database ID to monitor for results, defaulting to "1". <p/>
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
        const name     = 'nextId';
        const $results = bulkOpResults(results);
        let value      = $results.data(name);
        const initial  = isMissing(value);
        if (initial || isDefined(record)) {
            value = (typeof record === 'object') ? record.id : record;
            value = (Number(value) || 0) + 1;
            $results.data(name, value);
        }
        if ((value > 1) && !$results.data('firstId')) {
            $results.data('firstId', value);
        }
        return value.toString();
    }

    /**
     * Time the download was started. <p/>
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
        const name     = 'startTime';
        const $results = bulkOpResults(results);
        let value      = $results.data(name);
        if (isPresent(start_time) || isMissing(value)) {
            value = timeOf(start_time);
            $results.data(name, value);
        }
        return value;
    }

    /**
     * Setup the element which shows intermediate results during a bulk upload.
     *
     * @param {ElementEvt} [event]
     */
    function monitorBulkOperation(event) {
        const target = event?.currentTarget || event?.target;
        const $form  = target ? $(target) : $bulk_op_form;
        disableSubmit($form);
        uploader?.disableFileSelectButton();

        const $results = bulkOpResults();
        const $label   = bulkOpResultsLabel($results);
        $results.removeClass(OLD_DATA_MARKER).empty();
        addBulkOpResult($results, TMP_LINE_TEXT, TMP_LINE_CLASS);
        $label.text(Emma.Messages.uploader.results + ':');
        toggleHidden($label,   false);
        toggleHidden($results, false);

        clearBulkOpTrace();
        fetchEntryList('$', null, startMonitoring);

        /**
         * Establish the lower-bound of database ID's to search (starting with
         * the first ID after the current latest ID) then schedule an update.
         *
         * @param {SubmissionRecords} list
         */
        function startMonitoring(list) {
            const record = list.at(-1) || {};
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
        const $results = bulkOpResults(results);
        const period   = milliseconds || BULK_CHECK_PERIOD;
        const name     = 'checkPeriod';
        const timer    = $results.data(name);
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
        const $results = bulkOpResults();
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
                const $lines   = $results.children();
                const tmp_line = selector(TMP_LINE_CLASS);

                // Remove initialization line(s) if present.
                $lines.filter(tmp_line).remove();

                // Add a line for each record.
                let row   = $lines.length;
                const ent = list.map(r => addBulkOpResult($results, r, row++));
                addBulkOpTrace(ent);

                // Update the next ID to fetch.
                const last_id = Math.max(...list.map(rec => rec.id));
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
        const $results = bulkOpResults(results);
        let data;
        if (typeof entry !== 'object') {
            data = entry.toString();
        } else if (isMissing(entry.submission_id)) {
            // A generic object.
            data = asString(entry, (K / 2));
        } else {
            // An object which is a de-serialized Upload record.
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
        const $line = makeBulkOpResult(data, index);
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
        const func  = 'makeBulkOpResult';
        const $line = $('<div>');

        // CSS classes for the new line.
        let row = (typeof index === 'number') ? `row-${index}` : (index || '');
        if (!row.includes('line')) {
            row = `line ${row}`.trim();
        }
        $line.addClass(row);

        // Content for the new line.
        let text, html = '';
        if (typeof entry === 'object') {
            for (const [k, v] of Object.entries(entry)) {
                html += `<span class="label ${k}">${k}</span> `;
                html += `<span class="value ${k}">${v}</span>\n`;
            }
        } else if (typeof entry === 'string') {
            text = entry;
        } else {
            OUT.error(`${func}: ${typeof entry} invalid`);
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
        const func     = 'showBulkOpResults';
        const $results = bulkOpResults(results);
        let entries = data || getBulkOpTrace();
        if (entries && !entries.startsWith('[')) {
            entries = `[${entries}]`;
        }
        const list = entries && fromJSON(entries, func) || [];
        list.forEach((record, row) => {
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
        if (min && max) { range = `${min}-${max}` }
        else if (max)   { range = `1-${max}` }
        else if (min)   { range = `${min}` }
        else            { range = '*' }
        const base = `${PROPERTIES.Path.index}.json`;
        const url  = makeUrl(base, { selected: range });

        _debugXhr(`${func}: VIA`, url);

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
         * @param {string}         _status
         * @param {XMLHttpRequest} _xhr
         */
        function onSuccess(data, _status, _xhr) {
            //_debugXhr(`${func}: received`, (data?.length || 0), 'bytes.');
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
            const errs = presence(responseErrors(xhr));
            const text = errs?.join("\n") || `${status}: ${message}`;
            if (transientError(xhr.status)) {
                warning = text;
            } else {
                error   = text;
            }
        }

        /**
         * Actions after the request is completed.  If there was no error, the
         * list of extracted entries is passed to the callback function.
         *
         * @param {XMLHttpRequest} xhr
         * @param {string}         _status
         */
        function onComplete(xhr, _status) {
            _debugXhr(`${func}: completed in`, secondsSince(start), 'sec.');
            if (records) {
                callback(records);
            } else if (warning) {
                OUT.warn(`${func}: ${xhr.status}: ${warning} FROM ${url}`);
                callback([]);
            } else if (error ||= 'unknown failure') {
                OUT.error(`${func}: ${xhr.status}: ${error} - ABORT ${url}`);
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
     * @param {boolean} [append]      If **true** append to current
     *
     * @returns {string}              New stored value.
     */
    function setBulkOpTrace(value, name, append) {
        const key = name || BULK_OP_STORAGE_KEY;
        let entry = append && getBulkOpTrace(key) || '';
        if (isPresent(value)) {
            const trace = (v) => (typeof v === 'string') ? v : asString(v);
            const parts = arrayWrap(value).map(v => trace(v));
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
     * Call the server endpoint to acquire replacement form field values. <p/>
     *
     * If this is a create form, then a new Upload record is generated to make
     * up for the fact that previously clicking away from the page resulted in
     * the original partial Upload record being deleted. <p/>
     *
     * If this is an edit form, then the appropriate field values are
     * generated to put the Upload record in the initial workflow edit state.
     * <p/>
     *
     * In either case, {@link initializeModelForm} is called with the new
     * fields to complete page initialization.
     *
     * @param {Selector} [form]       Default: {@link formElement}.
     *
     * @returns {boolean}
     */
    function refreshRecord(form) {

        const func  = 'refreshRecord';
        const $form = formElement(form);
        let url;
        if (isNewForm($form)) {
            url = PROPERTIES.Path.renew;
        } else {
            url = PROPERTIES.Path.reedit;
            url &&= makeUrl(url, submissionParams($form));
        }
        if (isMissing(url)) {
            return false;
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
         * @param {string}         _status
         * @param {XMLHttpRequest} _xhr
         */
        function onSuccess(data, _status, _xhr) {
            //_debugXhr(`${func}: received`, (data?.length || 0), 'bytes.');
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
            const errs = presence(responseErrors(xhr));
            const text = errs?.join("\n") || `${status}: ${message}`;
            if (transientError(xhr.status)) {
                warning = text;
            } else {
                error   = text;
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
         * @param {string}         _status
         */
        function onComplete(xhr, _status) {
            _debugXhr(`${func}: completed in`, secondsSince(start), 'sec.');
            if (record) {
                //_debugXhr(`${func}: data from server:`, record);
            } else if (warning) {
                OUT.warn(`${func}: ${xhr.status}: ${warning} FROM ${url}`);
            } else if (error ||= 'unknown error') {
                OUT.error(`${func}: ${xhr.status}: ${error} FROM ${url}`);
            }
            initializeModelForm($form, record);
        }

        return true;
    }

    /**
     * Initialize form display and event handlers.
     *
     * @param {Selector}      form
     * @param {string|object} [start_data]  Replacement data.
     */
    function initializeModelForm(form, start_data) {

        /** @type {jQuery} */
        const $form = $(form);

        // Setup file uploader (if applicable).
        initializeFileUploader($form);

        // Setup buttons.
        setupSubmitButton($form);
        setupCancelButton($form);
        setupLookupButton($form);

        // Prevent password managers from incorrectly interpreting any of the
        // fields as something that might pertain to user information.
        turnOffAutocomplete(inputFields($form));

        // Broaden click targets for radio buttons and checkboxes that are
        // paired with labels.
        const $panel  = fieldDisplayFilterContainer($form);
        const $radios = $panel.children('.radio, .control').not('label');
        const $cbs    = $form.find('.checkbox.single').not('[role="option"]');
        $radios.add($cbs).each((_, ctl) => delegateInputClick(ctl));

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

        // Cancel the current submission if the user leaves the page before
        // submitting.
        onPageExit((() => abortSubmission($form)), OUT.debugging());
    }

    /**
     * Initialize the state of the submit button.
     *
     * @param {Selector} [form]       Default: {@link formElement}.
     */
    function setupSubmitButton(form) {
        const $form    = formElement(form);
        const label    = submitLabel($form);
        const tip      = submitTooltip($form);
        const $button  = submitButton($form).attr('title', tip).text(label);
        const verify   = requiresRecaptcha($form);
        const callback = verify ? verifyRecaptcha : startSubmission;
        handleClickAndKeypress($button, callback);
    }

    /**
     * Initialize the state of the cancel button, and set it up to clear the
     * form when it is activated.
     *
     * @param {Selector} [form]       Default: {@link formElement}.
     */
    function setupCancelButton(form) {
        const $form   = formElement(form);
        const label   = cancelLabel($form);
        const tip     = cancelTooltip($form);
        const $button = cancelButton($form).attr('title', tip).text(label);
        handleClickAndKeypress($button, cancelSubmission);
    }

    /**
     * Initialize each form field then update any fields associated with
     * server-provided metadata.
     *
     * @param {Selector}      [form]        Default: {@link formElement}.
     * @param {string|object} [start_data]  Replacement data.
     */
    function initializeFormFields(form, start_data) {
        const func    = 'initializeFormFields';
        const $form   = formElement(form);
        const data    = {};
        const extract = (value) => Object.assign(data, fromJSON(value, func));

        if (start_data) {
            extract(start_data);
        } else {
            extract(emmaDataElement($form).val());
            extract(revertDataElement($form).val());
        }

        formFields($form).each((_, fld) => initializeInputField(fld, data));
        resolveRelatedFields();
        disableSubmit($form);
        disableLookup($form);
        clearFormState($form);
    }

    // ========================================================================
    // Functions - form fields
    // ========================================================================

    /**
     * Interpret the object keys as field names to locate the input elements
     * to update. <p/>
     *
     * The field will not be updated if "sealed off" by the presence of the
     * {@link SEALED_MARKER}.  This prevents the uploading of the file from
     * modifying metadata which is under the control of the partner repository
     * specified via "emma_repository".
     *
     * @param {object}   data
     * @param {Selector} [form]       Default: {@link formElement}.
     *
     * @returns {boolean}             False if validateForm didn't occur.
     */
    function populateFormFields(data, form) {
        let revalidated = false;
        if (isPresent(data)) {
            const $form = formElement(form);
            let count   = 0;
            for (const [field, value] of Object.entries(data)) {
                const $field = formField(field, $form);
                if (!$field.is(`${SEALED},${FIXED}`)) {
                    updateInputField($field, value);
                    count++;
                }
            }
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
        const $field = $(field);
        const key    = $field.attr('data-field');
        const value  = (typeof data === 'object') ? data[key] : data;
        updateInputField($field, value, true, true);
        if ($field.is(FIXED)) {
            $field.prop('readonly', true);
            $field.find('option').not(':selected').prop('disabled', true);
        }
    }

    /**
     * Update a single input field and its label.
     *
     * @param {Selector} field
     * @param {*}        [new_value]
     * @param {boolean}  [trim]       If **false**, don't trim white space.
     * @param {boolean}  [init]       If **true**, in initialization phase.
     */
    function updateInputField(field, new_value, trim, init) {
        const $field = $(field);

        if ($field.is(`fieldset${INPUT_MULTI}`)) {
            updateInputGroup($field, new_value, trim, init);

        } else if ($field.is(MENU_MULTI)) {
            updateCheckboxGroup($field, new_value, init);

        } else if ($field.is(MENU_SINGLE)) {
            updateMenu($field, new_value, init);

        } else if ($field.is(CHECKBOX)) {
            updateCheckboxInputField($field, new_value, init);

        } else if ($field.is('textarea')) {
            updateTextAreaField($field, new_value, trim, init);

        } else {
            updateTextInputField($field, new_value, trim, init);
        }
    }

    /**
     * Update the input field collection and label for a {@link TEXT_GROUP} and
     * its enclosed set of text inputs.
     *
     * @param {Selector}             target
     * @param {string|string[]|null} [new_value]
     * @param {boolean}              [trim]     If **false**, keep white space.
     * @param {boolean}              [init]     If **true**, initializing.
     *
     * @returns {undefined}
     *
     * @see "BaseDecorator::Form#render_form_input_multi"
     */
    function updateInputGroup(target, new_value, trim, init) {
        const func   = 'updateInputGroup';
        const $field = selfOrParent(target, '[data-field]');

        if (isEmpty($field)) {
            return OUT.error(`${func}: no data-field for`, target);
        }

        // If multiple values are provided, they are treated as a complete
        // replacement for the existing set of values.
        const $inputs = TextInputGroup.controls($field);
        if (Array.isArray(new_value) || (new_value === null)) {
            const new_values = compact(new_value || []);
            $inputs.each((index, input) => {
                let value = new_values[index];
                if (init && !value) {
                    value = '';
                }
                if (isDefined(value)) {
                    setValue(input, value, true, init);
                }
            });
        } else {
            // Initialize original values for all elements.
            $inputs.each((_, input) => setOriginalValue(input));
            if (new_value) {
                let value = new_value;
                if ((trim !== false) && (typeof value === 'string')) {
                    value = value.trim();
                }
                let index = -1;
                $inputs.each((idx, _input) => {
                    let done = false;
                    const old_value = this.value || '';
                    if (old_value === value) {
                        // The value is present in this slot.
                        index = -1;
                        done  = true;
                    } else if (index >= 0) {
                        // An empty slot has already been reserved; continue
                        // looking for the value in later slots.
                    } else if (!old_value) {
                        // The value will be placed in this empty slot unless
                        // it is found in a later slot.
                        index = idx;
                    }
                    return !done;
                });
                if (index >= 0) {
                    setValue($inputs[index], value, trim, init);
                }
            }
        }

        // Enumerate the valid inputs and update the fieldset.
        const values = $inputs.map((_, cb) => cb.value).filter(v => v);
        updateFieldAndLabel($field, values);
    }

    /**
     * Update the input field collection and label for a {@link CB_GROUP}
     * and its enclosed set of checkboxes.
     *
     * @param {Selector}             target
     * @param {string|string[]|null} [setting]
     * @param {boolean}              [init]     If **true**, in initialization.
     *
     * @returns {undefined}
     *
     * @see "BaseDecorator::Form#render_form_menu_multi"
     */
    function updateCheckboxGroup(target, setting, init) {
        const func   = 'updateCheckboxGroup';
        const $field = selfOrParent(target, '[data-field]');

        if (isEmpty($field)) {
            return OUT.error(`${func}: no data-field for`, target);
        }

        // If a value is provided, use it to define the state of the contained
        // checkboxes if it is an array, or to set a specific checkbox if it
        // is a string.
        const group       = CheckboxGroup.setupFor($field);
        /** @type {jQuery<HTMLInputElement>} */
        const $checkboxes = group?.controls || CheckboxGroup.controls($field);
        if (Array.isArray(setting) || (setting === null)) {
            const values = compact(setting || []);
            $checkboxes.each((_, cb) => {
                const checked = values.includes(cb.value);
                setChecked(cb, checked, init);
            });
        } else if (typeof setting === 'string') {
            $checkboxes.each((_, cb) => {
                if (cb.value === setting) {
                    setChecked(cb, true, init);
                } else if (init) {
                    setOriginalValue(cb);
                }
            });
        } else if (init) {
            $checkboxes.each((_, cb) => setOriginalValue(cb));
        }

        // Enumerate the checked items and update the fieldset.
        const $checked = $checkboxes.filter((_, cb) => cb.checked);
        const values   = $checked.map((_, cb) => cb.value);
        updateFieldAndLabel($field, values);
    }

    /**
     * Update the input field and label for a `<input type="checkbox">`. <p/>
     *
     * For this type, the checkbox is within a hierarchy under a group element
     * which is a sibling of the label element associated with any of the
     * contained checkboxes.
     *
     * @param {Selector}       target
     * @param {string|boolean} [setting]
     * @param {boolean}        [init]       If **true**, initialization phase.
     *
     * @returns {undefined}
     */
    function updateCheckboxInputField(target, setting, init) {
        const func   = 'updateCheckboxInputField';
        const $input = $(target);
        const $field = selfOrParent($input, '[data-field]');

        if (isEmpty($field)) {
            return OUT.error(`${func}: no data-field for`, target);
        }

        const checkbox = $input[0];
        let checked;
        switch (setting) {
            case true:  case 'true':    checked = true;             break;
            case false: case 'false':   checked = false;            break;
            case checkbox.value:        checked = true;             break;
            default:                    checked = checkbox.checked; break;
        }

        if (isDefined(checked)) {
            setChecked($input, checked, init);
        } else {
            OUT.warn(`${func}: unexpected:`, setting);
        }

        // Update the enclosing listbox.
        updateCheckboxGroup($field, undefined, init);
    }

    /**
     * Update the input field and label for a `<select>`. <p/>
     *
     * For these types, the label is a sibling of the input element.
     *
     * @param {Selector}       target
     * @param {string|null}    [new_value]
     * @param {boolean}        [init]       If **true**, initialization phase.
     *
     * @returns {undefined}
     *
     * @see "BaseDecorator::Form#render_form_menu_single"
     */
    function updateMenu(target, new_value, init) {
        const func   = 'updateMenu';
        const $input = $(target);
        const $field = selfOrParent($input, '[data-field]');

        if (isEmpty($field)) {
            return OUT.error(`${func}: no data-field for`, target);
        }

        let value = new_value;
        if (Array.isArray(value)) {
            value = compact(value)[0];
        } else if (notDefined(value)) {
            value = $input.val();
        }
        setValue($input, value, true, init);
        updateFieldAndLabel($field, $input.val());
    }

    /**
     * Update the input field and label for a `<textarea>`. <p/>
     *
     * For this type, the label is a sibling of the input element.
     *
     * @param {Selector}    target
     * @param {string|null} [new_value]
     * @param {boolean}     [trim]        If **false**, don't trim white space.
     * @param {boolean}     [init]        If **true**, in initialization phase.
     *
     * @returns {undefined}
     *
     * @see "BaseDecorator::Form#render_form_input"
     */
    function updateTextAreaField(target, new_value, trim, init) {
        const func   = 'updateTextAreaField';
        const $input = $(target);
        const $field = selfOrParent($input, '[data-field]');

        if (isEmpty($field)) {
            return OUT.error(`${func}: no data-field for`, target);
        }

        let value = new_value;
        if (value !== null) {
            if (notDefined(value)) {
                value = $input.val();
            }
            if (trim !== false) {
                value = textAreaValue(value);
            }
        }
        setValue($input, value, trim, init);
        updateFieldAndLabel($field, $input.val());
    }

    /**
     * Update input field and label for `<textarea>` or `<input type="text">`.
     * <p/>
     *
     * For these types, the label is a sibling of the input element.
     *
     * @param {Selector}    target
     * @param {string|null} [new_value]
     * @param {boolean}     [trim]        If **false**, don't trim white space.
     * @param {boolean}     [init]        If **true**, in initialization phase.
     *
     * @returns {undefined}
     *
     * @see "BaseDecorator::Form#render_form_input"
     */
    function updateTextInputField(target, new_value, trim, init) {
        const func   = 'updateTextInputField';
        const $input = $(target);
        const $field = selfOrParent($input, '[data-field]');

        if (isEmpty($field)) {
            return OUT.error(`${func}: no data-field for`, target);
        }

        let value = new_value;
        if (Array.isArray(value)) {
            // noinspection JSUnresolvedFunction
            value = compact(value).join('; ');
        } else if (notDefined(value)) {
            value = $input.val();
        }
        setValue($input, value, trim, init);

        // If this is one of a collection of text inputs under `<fieldset>`
        // then it has to be handled differently.
        if (sameElements($input, $field)) {
            updateFieldAndLabel($field, $input.val());
        } else {
            updateInputGroup($field, undefined, trim, init);
        }
    }

    /**
     * Attempt to update all of the fields with relationships except for those
     * indicated.
     *
     * @param {string[]} [already_modified]
     */
    function resolveRelatedFields(already_modified) {
        const skip_fields   = already_modified || [];
        const relationships = Object.entries(FIELD_RELATIONSHIP);
        for (const [field_name, relationship] of relationships) {
            if (!skip_fields.includes(field_name)) {
                const visited = updateRelatedField(field_name, relationship);
                if (visited) {
                    skip_fields.push(visited.name);
                }
            }
        }
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
            return OUT.error(`${func}: missing primary argument`);
        }

        // Determine the element for the named field.
        const $form = formElement();
        let this_name, $this_field;
        if (typeof name === 'string') {
            this_name   = name;
            $this_field = $form.find(`[name="${this_name}"]`);
        } else {
            $this_field = $(name);
            this_name   = $this_field.attr('name');
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
            return OUT.error(`${func}:`, error);
        } else if (warn) {
            return; //OUT.warn(`${func}:`, warn);
        }

        // Toggle state of the related element.
        let modified       = undefined;
        const $other_field = $form.find(`[name="${other.name}"]`);
        if (isPresent($other_field)) {
            if (isTrue(other.required) || isFalse(other.unrequired)) {
                modified = modifyOther(true, other.required_val);
            } else if (isTrue(other.unrequired) || isFalse(other.required)) {
                modified = modifyOther(false, other.unrequired_val);
            }
            if (modified) {
                updateFieldAndLabel($other_field, $other_field.val());
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
                result = result($this_field);
            }
            if (typeof result !== 'boolean') {
                result = String(result).toLowerCase();
                result = is_true ? (result === 'true') : (result !== 'false');
            }
            return is_true ? result : !result;
        }

        function modifyOther(new_req, new_val) {
            let changed   = false;
            const old_req = $other_field.attr('data-required')?.toString();
            if (old_req !== new_req?.toString()) {
                fieldRequired($other_field, new_req);
                changed = true;
            }
            if (isDefined(new_val) && ($other_field.val() !== new_val)) {
                $other_field.val(new_val);
                // This shouldn't be necessary.
                if ((this_name === 'rem_complete') &&
                    (rawOriginalValue($other_field) === '(ALL)')) {
                    setOriginalValue($other_field, '');
                    $other_field.text(new_val);
                }
                changed = true;
            }
            return changed;
        }
    }

    /**
     * Update the input field for `<select>`, `<textarea>`, or
     * `<input type="text">`, along with its label, and possibly other related
     * fields. <p/>
     *
     * For these types, the label is a sibling of the input element.
     *
     * @param {Selector} target
     * @param {*}        values
     *
     * @see "BaseDecorator::Form#form_note_pair"
     */
    function updateFieldAndLabel(target, values) {
        const $field   = $(target);
        const field    = $field.attr('data-field');
        /** @type {jQuery} */
        const $label   = fieldLabel($field),
              $status  = $label.find('.status-marker'),
              $related = $field.siblings(`[data-for="${field}"]`);
        const parts    = [$field, $label, $status, ...$related];

        if ($field.attr('readonly')) {

            // Database fields should not be marked for validation.
            toggleClass(parts, 'valid invalid', false);

        } else {

            const required = ($field.attr('data-required') === 'true');
            const missing  = isEmpty(values);
            let invalid    = required && missing;

            if (invalid) {
                updateFieldState(false);
            } else {
                validate($field, values, updateFieldState);
            }

            function updateFieldState(valid, notes) {

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

                // Update ARIA attributes on the input field.
                if (required) {
                    fieldAriaInvalid( $field, invalid);
                    fieldAriaRequired($field, required);
                } else if (fieldAriaRequired($field)) {
                    fieldAriaInvalid( $field, false);
                    fieldAriaRequired($field, false);
                }

                // Update CSS status classes on all parts of the field.
                const is_valid = !!valid && !missing;
                toggleClass(parts, REQUIRED_MARKER, required);
                toggleClass(parts, INVALID_MARKER,  invalid);
                toggleClass(parts, VALID_MARKER,    is_valid);

                // Update the state of the lookup button if appropriate.
                updateLookupCondition($field, field, is_valid);
            }
        }
    }

    /**
     * The label of a top-level "value" element.
     *
     * @param {Selector} target
     *
     * @returns {jQuery}
     *
     * @see "BaseDecorator::Form#render_form_pair"
     */
    function fieldLabel(target) {
        const $input = $(target);
        const id     = $input.attr('id');
        const match  = `[data-label-for="${id}"], label[for="${id}"]`;
        return $input.siblings(match);
    }

    /**
     * The *data-required* attribute is maintained on the top-level element
     * associated with an input or group of inputs independent of the
     * *aria-required* attribute.
     *
     * @param {Selector} target
     * @param {boolean}  [setting]
     *
     * @returns {boolean}
     */
    function fieldRequired(target, setting) {
        /** @type {jQuery} */
        const $input = $(target);
        switch (setting) {
            case true:  $input.attr('data-required', true); break;
            case false: $input.removeAttr('data-required'); break;
            default:    return $input.attr('data-required') || false;
        }
        return fieldAriaRequired($input, setting);
    }

    /**
     * In order to accommodate accessibility concerns, *aria-required* is
     * maintained on the top-level element associated with an input or group
     * of input except in the case of {@link MENU_MULTI} where the top-level
     * value entry is actually a wrapper for the element to which the attribute
     * must be applied.
     *
     * @param {Selector} target
     * @param {boolean}  [setting]
     *
     * @returns {boolean}
     */
    function fieldAriaRequired(target, setting) {
        const $target = fieldAriaTarget(target);
        switch (setting) {
            case true:  $target.attr('aria-required', true); return setting;
            case false: $target.removeAttr('aria-required'); return setting;
            default:    return $target.attr('aria-required') || false;
        }
    }

    /**
     * In order to accommodate accessibility concerns, *aria-invalid* is
     * maintained on the top-level element associated with an input or group
     * of input except in the case of {@link MENU_MULTI} where the top-level
     * value entry is actually a wrapper for the element to which the attribute
     * must be applied.
     *
     * @param {Selector} target
     * @param {boolean}  [setting]
     *
     * @returns {boolean}
     */
    function fieldAriaInvalid(target, setting) {
        const $target = fieldAriaTarget(target);
        switch (setting) {
            case true:  $target.attr('aria-invalid', true); return setting;
            case false: $target.removeAttr('aria-invalid'); return setting;
            default:    return $target.attr('aria-invalid') || false;
        }
    }

    /**
     * Return the element that should hold ARIA attributes for a field value.
     *
     * @param {Selector} target
     *
     * @returns {jQuery}
     */
    function fieldAriaTarget(target) {
        const $input = $(target);
        return $input.is('div') ? $input.children('[role]') : $input;
    }

    /**
     * If the checkbox state is changing, save the old state. <p/>
     *
     * If *new_state* is undefined then it is assumed that this invocation is
     * in response to a change event, in which case the state change has
     * already happened so the old state is the opposite of the current state.
     *
     * @param {Selector} checkbox
     * @param {boolean}  [new_state]
     * @param {boolean}  [init]       If **true**, in initialization phase.
     */
    function setChecked(checkbox, new_state, init) {
        const $checkbox = $(checkbox);
        if (init) {
            setOriginalValue($checkbox, new_state);
        }
        $checkbox.prop('checked', new_state);
    }

    /**
     * If the input value is changing, save the old value.
     *
     * @param {Selector}    target
     * @param {string|null} new_value
     * @param {boolean}     [trim]      If **false**, don't trim white space.
     * @param {boolean}     [init]      If **true**, in initialization phase.
     */
    function setValue(target, new_value, trim, init) {
        const $item = $(target);
        let value   = new_value || '';
        if (value === EMPTY_VALUE) {
            $item.prop('placeholder', value);
            value = '';
        } else if ((trim !== false) && value && (typeof value === 'string')) {
            value = value.trim();
        }
        if (init) {
            setOriginalValue($item, value);
        }
        $item.val(value);
    }

    /**
     * Translate a value for a `<textarea>` into a string.
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
                try {
                    result = JSON.parse(result);
                } catch {
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
     * Save the original value of an element. <p/>
     *
     * If *value* is present, that is assigned directly as the original value.
     * If *value* was not provided, and no saved value is present then the
     * current value will be saved as the original value.
     *
     * @param {Selector}                 target
     * @param {string|boolean|undefined} [value]
     */
    function setOriginalValue(target, value) {
        const $item   = $(target);
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
        const $item = $(target);
        return $item.attr('data-original-value');
    }

    /**
     * Get the value string associated with *item*. <p/>
     *
     * If *item* is a checkbox element, the state of it's *checked* attribute
     * is found; if *item* is another type of element, its *value* attribute
     * is found. <p/>
     *
     * Booleans are converted to either "true" or "false".
     *
     * @param {jQuery|HTMLElement|string|boolean|undefined} item
     *
     * @returns {string}
     */
    function valueOf(item) {
        let value;
        if (typeof item === 'object') {
            const $i = $(item);
            value = $i.is(CHECKBOX) ? $i[0].checked : $i.val();
        } else {
            value = item;
        }
        switch (typeof value) {
            case 'boolean': return value ? 'true' : 'false';
            case 'number':  return value.toString();
            case 'string':  return value.trim();
            default:        return '';
        }
    }

    // ========================================================================
    // Functions - form fields - deletion
    // ========================================================================

    const TO_DELETE_ATTR = 'data-to-delete';
    const DELETING_ATTR  = 'data-now-deleting';

    /**
     * Mark a field to be transmitted as a deleted field when submitted.
     *
     * @param {Selector} field
     */
    function markForDeletion(field) {
        $(field).attr(TO_DELETE_ATTR, true);
    }

    /**
     * Unmark a field to be transmitted as a deleted field.
     *
     * @param {Selector} field
     */
    function unmarkForDeletion(field) {
        $(field).removeAttr(TO_DELETE_ATTR);
    }

    /**
     * Indicate whether a field is marked for deletion.
     *
     * @param {Selector} field
     */
    function markedForDeletion(field) {
        return !!$(field).attr(TO_DELETE_ATTR);
    }

    /**
     * Mark a field to be transmitted as a deleted field when submitted,
     * transforming its value as needed.
     *
     * @param {Selector} field
     */
    function markAsDeleting(field) {
        const func   = 'markAsDeleting';
        const $field = $(field);
        const value  = Emma.Field.deleted;

        $field.attr(DELETING_ATTR, true);

        if ($field.is(MENU_SINGLE)) {
            OUT.debug(`${func}: MENU_SINGLE`, field);
            // noinspection JSCheckFunctionSignatures
            const unset = $field.children().find('[value=""]').text();
            const $added = $('<option>').val(value).text(unset);
            $field.append($added).val(value);
            OUT.debug(`${func}: MENU_SINGLE val =`, $field.val());

        } else if ($field.is(`${INPUT_SINGLE}[type="date"]`)) {
            OUT.debug(`${func}: INPUT_SINGLE[type="date"]`, field);
            // TODO: ?
            OUT.debug(`${func}: INPUT_SINGLE[type="date"] val =`, $field.val())

        } else if ($field.is(INPUT_SINGLE)) {
            OUT.debug(`${func}: INPUT_SINGLE`, field);
            $field.val(value);
            OUT.debug(`${func}: INPUT_SINGLE val =`, $field.val());

        } else {
            OUT.debug(`${func}: ignoring`, field);
            OUT.debug(`${func}: ignoring val =`, $field.val());
        }
    }

    // ========================================================================
    // Functions - form fields - validation
    // ========================================================================

    /**
     * Validate the value(s) for a field.
     *
     * @param {Selector} target
     * @param {*}        new_value    Current *target* value if not given.
     * @param {function} callback     Required.
     */
    function validate(target, new_value, callback) {
        const $input = $(target);
        const field  = $input.attr('data-field');
        const entry  = FIELD_VALIDATION[field];
        const value  = isDefined(new_value) ? new_value : $input.val();
        let valid, notes, min, max;

        if (isEmpty(value)) {
            notes = Emma.Messages.field.validation.empty;
            valid = undefined;

        } else if (typeof entry === 'string') {
            valid = remoteValidate(field, value, callback);
            if (notDefined(valid)) {
                return;
            }

        } else if (typeof entry === 'function') {
            valid = entry(value);

        } else if (typeof entry === 'boolean') {
            valid = entry;

        } else if (field === 'password_confirmation') {
            const $pwd = inputFields().filter('[data-field="password"]');
            if ($pwd.is(VALID)) {
                valid = (value === $pwd.val());
            } else if ($pwd.is(INVALID)) {
                valid = false;
            }

        } else if ($input.is('[type="email"]')) {
            valid = !!value.match(/^[^@]+@[^.].*\.[^.]+$/);

        } else if ((min = $input.attr('minlength')) && (value.length < min)) {
            notes = Emma.Messages.field.validation.too_small;
            valid = false;

        } else if ((max = $input.attr('maxlength')) && (value.length > max)) {
            notes = Emma.Messages.field.validation.too_big;
            valid = false;

        } else {
            valid = true;
        }

        callback(valid, notes);
    }

    /**
     * Validate the value(s) for a field.
     *
     * @param {string}          field
     * @param {string|string[]} new_value
     * @param {function}        callback
     *
     * @returns {boolean|undefined}
     */
    function remoteValidate(field, new_value, callback) {
        const func = 'remoteValidate';
        let url    = FIELD_VALIDATION[field];

        if (isMissing(callback)) {
            return OUT.error(`${func}: ${field}: no callback given`) || false;
        } else if (isMissing(url)) {
            return OUT.error(`${func}: ${field}: no URL given`) || false;
        }

        // Prepare value for inclusion in the URL.
        let value = new_value;
        if (typeof value === 'string') {
            value = value.split(/[,;|\t\n]/);
        }
        if (['dc_identifier', 'dc_relation'].includes(field)) {
            value = value.filter(v =>
                !v.match(/https?:/) || v.includes('doi.org') ||
                    OUT.log(`${func}: ignoring "${v}"`)
            );
            if (isEmpty(value)) {
                return false;
            }
        } else if (isEmpty(value)) {
            return OUT.warn(`${func}: ${url}: no values given`) || false;
        }
        value = value.join(',');

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
         * @param {string}         _status
         * @param {XMLHttpRequest} _xhr
         */
        function onSuccess(data, _status, _xhr) {
            //_debugXhr(`${func}: received data:`, data);
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
                error = Emma.Messages.field.validation.no_server;
            } else {
                const errs = presence(responseErrors(xhr));
                error = errs?.join("\n") || `${status}: ${message}`;
            }
        }

        /**
         * Invoke the callback with the reply.
         *
         * @param {XMLHttpRequest} xhr
         * @param {string}         _status
         */
        function onComplete(xhr, _status) {
            _debugXhr(`${func}: completed in`, secondsSince(start), 'sec.');
            if (error) {
                OUT.warn(`${func}: ${xhr.status}: ${error} FROM ${url}`);
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
     * @typedef {Object.<string,(true|null|string)>} SourceFieldTemplate
     */

    const FROM_PARENT = true;
    const CLEARED     = null;
    const AS_IS       = '';
    const NEW_REPO    = 'new_repo';

    /**
     * Template specifying update behavior for form fields.
     *
     * | Value       | Field will be...
     * |-------------|---------------------------------------------------
     * | FROM_PARENT | assigned the value acquired from the parent record
     * | CLEARED     | cleared of any value(s)
     * | AS_IS       | kept as it is
     * | NEW_REPO    | to be replaced by the repository selection
     * | (other)     | assigned that value
     *
     * The AS_IS choice is necessary for any remediation-related fields may
     * have been extracted from the file if it was provided before the source
     * repository was selected.
     *
     * @type {SourceFieldTemplate}
     */
    const SOURCE_FIELDS = Object.freeze({
        repository:                         NEW_REPO,
        emma_recordId:                      CLEARED,
        emma_titleId:                       FROM_PARENT,
        emma_repository:                    NEW_REPO,
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
        rem_metadataSource:                 AS_IS,
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
    });

    /**
     * Indicate whether *repo* requires the "partner repository workflow".
     *
     * @param {string} [repo]
     *
     * @returns {boolean}
     */
    function partnerRepository(repo) {
        return Emma.Repo.partner.includes(repo);
    }

    /**
     * Monitor attempts to change to the "Source Repository" menu selection.
     *
     * @param {Selector} [form]       Default: {@link formElement}.
     */
    function monitorSourceRepository(form) {
        const func  = 'monitorSourceRepository';
        const $form = formElement(form);
        const $menu = sourceRepositoryMenu($form);

        // If editing a completed submission, prevent the selection from being
        // updated.

        if (isEditForm($form) && $menu.val() && !$menu.is(FIXED)) {
            const note = Emma.Messages.field.readonly;
            seal($menu, true).attr('title', note);
            return;
        }

        const REPO_DATA = 'data-previous-value';

        // Listen for a change to the "Source Repository" selection.  If the
        // selection was cleared, or if the default repository was selected,
        // then proceed to form validation.  If a partner repository was
        // selected, prompt for the original item.

        handleEvent($menu, 'change', function() {
            clearFlash();
            const new_repo = $menu.val() || '';
            if (partnerRepository(new_repo)) {
                showParentEntrySelect($form);
                parentEntrySearchInput($form).trigger('focus');
            } else {
                hideParentEntrySelect($form);
                setSourceRepository(new_repo);
            }
        });

        // Set up click handler for the button within .parent-entry-select,
        // the element that will be displayed to prompt for the original item
        // on which this submission is based.

        handleClickAndKeypress(parentEntrySubmit($form), function() {
            clearFlash();
            hideParentEntrySelect($form);
            SearchInProgress.show();
            const search = parentEntrySearchTerms($form, func);
            search.repository = $menu.val();
            fetchIndexEntries(search, useParentEntryMetadata, searchFailure);
        });

        // If the prompt is canceled, silently restore the source repository
        // selection to its previous setting.

        handleClickAndKeypress(parentEntryCancel($form), function() {
            clearFlash();
            hideParentEntrySelect($form);
            searchFailure();
        });

        /**
         * Extract the title information from the search results.
         *
         * @param {SearchResultEntry[]} list
         */
        function useParentEntryMetadata(list) {

            const repo = $menu.val();
            let error;

            // If there was an error, the source repository menu selection is
            // restored to its previous setting.

            if (!Array.isArray(list)) {
                error = `${repo}: search error`;
                OUT.error(`${func}: ${repo}: arg is not an array`);
            } else if (isEmpty(list)) {
                const query = parentEntrySearchInput($form).val();
                error = `${repo}: no match for "${query}"`;
                OUT.warn(`${func}:`, error);
            }
            if (error) {
                searchFailure(error);
                return;
            }

            // Ideally, there should be only a single search result which
            // matched the search terms.  If there are multiple results, warn
            // if they don't appear to be just variations on the same title.

            /** @type {SearchResultEntry} */
            const parent = list.shift();
            if (repo !== parent.emma_repository) {
                error = 'PROBLEM: ';
                error += `new_repo == "${repo}" but parent `;
                error += `emma_repository == "${parent.emma_repository}"`;
                OUT.warn(`${func}:`, error);
            }
            const title_id = parent.emma_titleId;
            const mismatch = list.filter(e => (e.emma_titleId !== title_id));
            if (isPresent(mismatch)) {
                const count   = mismatch.length;
                const one     = (count === 1);
                const many    = one ? capitalize(Emma.Messages.one) : count;
                const other   = `${Emma.Messages.other} ${Emma.Messages.EMMA}`;
                const results = pluralize(Emma.Messages.result, count);
                const from    = Emma.Messages.from;
                const also    = Emma.Messages.also;
                const match   = pluralize(Emma.Messages.match, one);
                flashMessage(
                    [many, other, results, from, repo, also, match].join(' ')
                );
                const warn = (label, entry) => {
                    const id = entry.emma_titleId;
                    OUT.warn(`${func}: ${label}: title_id = ${id}`, entry);
                };
                warn('parent', parent);
                mismatch.forEach(e => warn('other', e));
            } else {
                OUT.debug(`${func}: parent:`, parent);
            }

            // If control reaches here then the current selection is valid.

            $menu.attr(REPO_DATA, repo);

            // Update form fields.

            const update = {};
            const source_fields = { ...SOURCE_FIELDS,
                repository:         repo,
                emma_repository:    repo,
                rem_metadataSource: [Emma.Repo.name[repo]],
            };
            for (const [field, value] of Object.entries(source_fields)) {
                if (typeof value === 'function') {
                    // noinspection JSValidateTypes
                    update[field] = value(parent);
                } else if (value === FROM_PARENT) {
                    update[field] = parent[field] || EMPTY_VALUE;
                } else {
                    update[field] = value;
                }
            }
            unsealFields(source_fields);
            populateFormFields(update, $form);
            sealFields(source_fields);
            SearchInProgress.hide();
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
            SearchInProgress.hide();
        }

        /**
         * Force the current source repository setting.
         *
         * @param {string} [value]
         */
        function setSourceRepository(value) {
            let new_repo = value;
            if (isDefined(new_repo)) {
                $menu.attr(REPO_DATA, new_repo);
            } else {
                new_repo = $menu.attr(REPO_DATA) || '';
            }
            OUT.debug(`${func}:`, (new_repo || 'cleared'));
            if (!partnerRepository(new_repo)) {
                unsealFields();
                resetLookupCondition($form, true);
            }
            const set_repo = {
                repository:      (new_repo || EMPTY_VALUE),
                emma_repository: (new_repo || null)
            };
            populateFormFields(set_repo, $form);
        }

        /**
         * Seal off the specified fields by adding the "sealed" class in order
         * to prevent populateFormFields() from modifying them. <p/>
         *
         * This way, if the source repository is set before the file is
         * uploaded then metadata extracted from the file will not contradict
         * the title-level metadata supplied by the partner repository. <p/>
         *
         * This doesn't prevent the user from updating the field, but the
         * styling of the "sealed" class should hint that changing the field is
         * not desirable (since the change is going to be ignored by the
         * partner repository anyway).
         *
         * @param {object} [source_fields]
         */
        function sealFields(source_fields = SOURCE_FIELDS) {
            for (const [field, value] of Object.entries(source_fields)) {
                if (value === FROM_PARENT) {
                    const $input = formField(field, $form);
                    if (!$input.is(FIXED)) {
                        seal($input);
                        seal(fieldLabel($input));
                    }
                }
            }
        }

        /**
         * Restore sealed fields.
         *
         * @param {object} [source_fields]
         */
        function unsealFields(source_fields = SOURCE_FIELDS) {
            for (const [field, value] of Object.entries(source_fields)) {
                if (value === FROM_PARENT) {
                    const $input = formField(field, $form);
                    if (!$input.is(FIXED)) {
                        unseal($input);
                        unseal(fieldLabel($input));
                    }
                }
            }
        }
    }

    /**
     * Get EMMA index entries via search.
     *
     * @param {object}                        params
     * @param {function(SearchResultEntry[])} callback
     * @param {function}                      [error_callback]
     */
    function fetchIndexEntries(params, callback, error_callback) {
        const func = 'fetchIndexEntries';
        const url  = isPresent(params) && makeUrl('/search/direct', params);
        if (isEmpty(url)) {
            OUT.error(`${func}: empty search terms`);
            return;
        }
        const title = params.title?.replace(/^"(.*)"$/, '$1')?.toLowerCase();

        _debugXhr(`${func}: VIA`, url);

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
         * @param {string}                     _status
         * @param {XMLHttpRequest}             _xhr
         */
        function onSuccess(data, _status, _xhr) {
            //_debugXhr(`${func}: received`, (data?.length || 0), 'bytes.');
            if (isMissing(data)) {
                error = 'no data';
            } else if (typeof(data) !== 'object') {
                error = `unexpected data type ${typeof data}`;
            } else if (!(records = data.response?.records)) {
                records = [];
            } else if (title) {
                records = records.filter(
                    rec => rec.dc_title?.toLowerCase()?.startsWith(title)
                );
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
            const errs = presence(responseErrors(xhr));
            const text = errs?.join("\n") || `${status}: ${message}`;
            if (transientError(xhr.status)) {
                warning = text;
            } else {
                error   = text;
            }
        }

        /**
         * Actions after the request is completed.  If there was no error, the
         * search result list is passed to the callback function.
         *
         * @param {XMLHttpRequest} xhr
         * @param {string}         _status
         */
        function onComplete(xhr, _status) {
            _debugXhr(`${func}: complete`, secondsSince(start), 'sec.');
            if (records) {
                callback(records);
            } else if (warning) {
                OUT.warn(`${func}: ${xhr.status}: ${warning} FROM ${url}`);
                error_callback?.(warning);
            } else if (error ||= 'unknown failure') {
                OUT.error(`${func}: ${xhr.status}: ${error} FROM ${url}`);
                error_callback?.(error);
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
     * Selection control for identifying the EMMA entry which is the source of
     * a new submission derived from partner repository content.
     *
     * @param {Selector} [form]
     *
     * @returns {jQuery}
     */
    function parentEntrySelect(form) {
        const $element = form && $(form);
        if ($element?.is(PARENT_SELECT)) {
            return $element;
        } else {
            return formElement($element).find(PARENT_SELECT);
        }
    }

    /**
     * Display the source entry selection control.
     *
     * @param {Selector} [form]
     *
     * @returns {jQuery}
     */
    function showParentEntrySelect(form) {
        const $popup_form = parentEntrySelect(form);
        parentEntrySearchInput($popup_form).prop('disabled', false);
        return toggleHidden($popup_form, false);
    }

    /**
     * Hide the source entry selection control.
     *
     * @param {Selector} [form]
     *
     * @returns {jQuery}
     */
    function hideParentEntrySelect(form) {
        const $popup_form = parentEntrySelect(form);
        parentEntrySearchInput($popup_form).prop('disabled', true);
        return toggleHidden($popup_form, true);
    }

    /**
     * Input element for search terms used to locate the parent EMMA entry.
     *
     * @param {Selector} [form]
     *
     * @returns {jQuery}
     */
    function parentEntrySearchInput(form) {
        return parentEntrySelect(form).find(PARENT_SEARCH_INPUT);
    }

    /**
     * Search terms to be used to locate the parent EMMA entry.
     *
     * @param {Selector} [form]
     * @param {string}   [caller]     For logging.
     *
     * @returns {object}
     */
    function parentEntrySearchTerms(form, caller) {
        let error, result = {};
        const $input = parentEntrySearchInput(form);
        const terms  = $input.val()?.trim() || '';
        if (isEmpty(terms)) {
            error = 'empty search terms';
        } else if (terms.match(/^[a-z]+:/)) {
            result.identifier = terms;
        } else if (terms.match(/^\d+[xX]?$/)) {
            result.identifier = `isbn:${terms}`;
        } else if (terms.match(/\s/)) {
            result.title      = `"${terms}"`;
        } else {
            result.title      = terms;
        }
        if (error) {
            const func = caller || 'parentEntrySearchTerms';
            OUT.warn(`${func}: ${error}`);
        }
        return result;
    }

    /**
     * Parent entry mini dialog submit.
     *
     * @param {Selector} [form]
     *
     * @returns {jQuery}
     */
    function parentEntrySubmit(form) {
        return parentEntrySelect(form).find(PARENT_SEARCH_SUBMIT);
    }

    /**
     * Parent entry mini dialog cancel.
     *
     * @param {Selector} [form]
     *
     * @returns {jQuery}
     */
    function parentEntryCancel(form) {
        return parentEntrySelect(form).find(PARENT_SEARCH_CANCEL);
    }

    /**
     * Seal an element. <p/>
     *
     * To allow {@link MENU_MULTI} (checkboxes) to be scrollable,
     * *pointer-events* on the content elements can be set to "none" via CSS.
     * This strategy does not work for {@link MENU_SINGLE} (dropdowns) to be
     * expandable, however, disabling the non-selected `<option>` elements here
     * does work.
     *
     * @param {Selector} item
     * @param {boolean}  [disabled]
     *
     * @returns {jQuery}
     */
    function seal(item, disabled) {
        const $item = $(item);
        $item.prop((disabled ? 'disabled' : 'readonly'), true);
        $item.find('option').not(':selected').prop('disabled', true);
        $item.toggleClass(SEALED_MARKER, true);
        return $item;
    }

    /**
     * Unseal an element.
     *
     * @param {Selector} item
     *
     * @returns {jQuery}
     */
    function unseal(item) {
        const $item = $(item);
        $item.prop('disabled', false);
        $item.prop('readonly', false);
        $item.prop('placeholder', '');
        $item.find('option').prop('disabled', false);
        $item.toggleClass(SEALED_MARKER, false);
        return $item;
    }

    // ========================================================================
    // Functions - bibliographic lookup
    // ========================================================================

    /**
     * The bibliographic lookup button if present on the form.
     *
     * @param {Selector} [form]       Default: {@link formElement}.
     *
     * @returns {jQuery|undefined}
     *
     * @see "BaseDecorator::Lookup#lookup_control"
     */
    function lookupButton(form) {
        const $elem = form && $(form);
        if (isEmpty($elem)) { return }
        if ($elem.is(LOOKUP_BUTTON)) { return $elem }
        return presence(buttonTray($elem).find(LOOKUP_BUTTON));
    }

    /**
     * Initialize the state of the bibliographic lookup button.
     *
     * @param {Selector} [form]       Default: {@link formElement}.
     */
    function setupLookupButton(form) {
        const $toggle = lookupButton(form);
        if ($toggle) {
            clearSearchResultsData($toggle);
            clearSearchTermsData($toggle);
            clearLookupCondition($toggle);
            LookupModal.setupFor($toggle, onLookupStart, onLookupComplete);
        }
    }

    /**
     * Invoked to update search terms when the popup opens.
     *
     * @param {jQuery}  $toggle
     * @param {boolean} check_only
     * @param {boolean} [halted]
     *
     * @returns {EventHandlerReturn}
     *
     * @see onShowModalHook
     */
    function onLookupStart($toggle, check_only, halted) {
        if (check_only || halted) { return undefined }
        clearFlash();
        clearSearchResultsData($toggle);
        setSearchTermsData($toggle);
        setOriginalValues($toggle);
    }

    /**
     * Invoked to update form fields when the popup closes.
     *
     * @param {jQuery}  $toggle
     * @param {boolean} check_only
     * @param {boolean} [halted]
     *
     * @returns {EventHandlerReturn}
     *
     * @see onHideModalHook
     */
    function onLookupComplete($toggle, check_only, halted) {
        if (check_only || halted) { return undefined }

        const $form = formElement();
        let message = Emma.Messages.lookup.no_changes;
        const data  = getFieldResultsData($toggle);

        if (isPresent(data)) {
            const updates = { Added: [], Changed: [], Removed: [] };
            for (const [field, value] of Object.entries(data)) {
                if (!value) {
                    updates.Removed.push(field);
                } else if (formField(field, $form).val()) {
                    updates.Changed.push(field);
                } else {
                    updates.Added.push(field);
                }
            }
            message = $.map(compact(updates), (fields, update_type) => {
                const items  = pluralize(Emma.Messages.item, fields.length);
                const label  = `${update_type} ${items}`;
                const attrs  = fields.map(fld => `[name="${fld}"]`).join(', ');
                const inputs = $form.find(attrs).toArray();
                const names  = inputs.map(input =>
                    fieldLabel(input).children('.text').text()
                ).sort().join(', ');
                const type   = `<span class="type">${label}:</span>`;
                const list   = `<span class="list">${names}.</span>`;
                return `${type} ${list}`;
            }).join("\n");

            // NOTE: This is a hack due to the way that publication date is
            //  handled versus copyright year.
            if (Object.keys(data).includes('emma_publicationDate')) {
                const $input = formField('emma_publicationDate', $form);
                const $label = fieldLabel($input);
                $input.attr('title', $label.attr('title'));
                $input.prop({ readonly: false, disabled: false });
                [$input, $label].forEach($e => {
                    $e.css('display','revert').toggleClass('disabled', false)
                });
            }

            // Update form fields with the provided data.
            populateFormFields(data, $form);
        }

        showFlashMessage(message);
    }

    /**
     * Enable bibliographic lookup.
     *
     * @param {Selector} [form]       Default: {@link formElement}.
     * @param {boolean}  [enable]     If **false** run {@link disableLookup}.
     * @param {boolean}  [forbid]     If **false** run {@link disableLookup}.
     *
     * @returns {jQuery|undefined}    The submit button.
     */
    function enableLookup(form, enable, forbid) {
        const $button = lookupButton(form);
        if ($button) {
            if (enable === false) {
                return disableLookup($button, forbid);
            }
            if (forbid) {
                OUT.error('enableLookup: cannot enable and forbid');
            }
            $button.prop('disabled', false);
            $button.removeClass('forbidden disabled');
            $button.attr('title', Emma.Lookup.if_enabled.tooltip);
        }
        return $button;
    }

    /**
     * Disable bibliographic lookup.
     *
     * @param {Selector} [form]       Default: {@link formElement}.
     * @param {boolean}  [forbid]     If **true** add ".forbidden".
     *
     * @returns {jQuery|undefined}    The submit button.
     */
    function disableLookup(form, forbid) {
        const $button = lookupButton(form);
        if ($button) {
            $button.prop('disabled', true);
            $button.addClass('disabled');
            let tooltip;
            if (forbid) {
                $button.addClass('forbidden');
                tooltip = Emma.Messages.form.no_lookup;
            } else {
                tooltip = Emma.Lookup.if_disabled.tooltip;
            }
            $button.attr('title', tooltip);
        }
        return $button;
    }

    // ========================================================================
    // Functions - bibliographic lookup - conditions
    // ========================================================================

    const LOOKUP_CONDITION_DATA = LookupRequest.LOOKUP_CONDITION_DATA;

    /**
     * Get the field value(s) for bibliographic lookup.
     *
     * @param {Selector} form
     *
     * @returns {LookupCondition}
     */
    function getLookupCondition(form) {
        const $button   = lookupButton(form);
        const condition = $button?.data(LOOKUP_CONDITION_DATA);
        return condition || LookupRequest.blankLookupCondition();
    }

    /**
     * Set the field value(s) for bibliographic lookup.
     *
     * @param {Selector}        form
     * @param {LookupCondition} value
     */
    function setLookupCondition(form, value) {
        lookupButton(form)?.data(LOOKUP_CONDITION_DATA, value);
    }

    /**
     * Set the field value(s) for bibliographic lookup to the initial state.
     *
     * @param {Selector} form
     */
    function clearLookupCondition(form) {
        const $btn = lookupButton(form);
        $btn && setLookupCondition($btn, LookupRequest.blankLookupCondition());
    }

    /**
     * Update the internal condition values for the Lookup button if *field* is
     * relevant to them, and change the button's enabled/disabled state if
     * appropriate.
     *
     * @param {Selector} form         Default: {@link formElement}.
     * @param {string}   field        A field-type.
     * @param {boolean}  valid        Whether data for that type is valid.
     */
    function updateLookupCondition(form, field, valid) {
        const $form   = formElement(form);
        const $button = lookupButton($form);
        if ($button) {
            const condition = getLookupCondition($button);
            let found;
            $.each(condition, (logical_op, entry) => {
                found = Object.keys(entry).includes(field);
                if (found) {
                    condition[logical_op][field] = valid;
                }
                return !found; // break loop if type found.
            });
            let enable   = false;
            const repo   = sourceRepositoryMenu($form).val();
            const forbid = partnerRepository(repo);
            if (found && !forbid) {
                enable ||= Object.values(condition.or).some(v => v);
                enable ||= Object.values(condition.and).every(v => v);
            }
            if (found || forbid) {
                enableLookup($button, enable, forbid);
            }
            if (enable) {
                clearSearchTermsData($button);
            }
        }
    }

    /**
     * Update the internal condition values for the Lookup button based on the
     * state of form values, and change the button's enabled/disabled state if
     * appropriate.
     *
     * @param {Selector} form         Default: {@link formElement}.
     * @param {boolean}  [permit]
     */
    function resetLookupCondition(form, permit) {
        const $form   = formElement(form);
        const $button = lookupButton($form);
        if ($button) {
            let enable = false;
            let forbid;
            if (isDefined(permit)) {
                forbid = !permit;
            } else {
                const repo = sourceRepositoryMenu($form).val();
                forbid = partnerRepository(repo);
            }
            if (!forbid) {
                const $fields   = inputFields($form);
                const condition = getLookupCondition($button);
                for (const [logical_op, entry] of Object.entries(condition)) {
                    for (const [field, _] of Object.entries(entry)) {
                        const $fld = $fields.filter(`[data-field="${field}"]`);
                        condition[logical_op][field] = isPresent($fld.val());
                    }
                }
                enable ||= Object.values(condition.or).some(v => v);
                enable ||= Object.values(condition.and).every(v => v);
                if (enable) {
                    clearSearchTermsData($button);
                }
            }
            enableLookup($button, enable, forbid);
        }
    }

    // ========================================================================
    // Functions - bibliographic lookup - original field values
    // ========================================================================

    /**
     * Set the original field values.
     *
     * @param {Selector} form
     * @param {EmmaData} [value]
     */
    function setOriginalValues(form, value) {
        const $if = !value && inputFields(form).filter('.valid');
        const dat = toObject(LookupModal.DATA_COLUMNS, (f) => deepDup(
            value ? value[f] : $if.filter(`[data-field="${f}"]`).val()
        ));
        lookupButton(form)?.data(LookupModal.ENTRY_ITEM_DATA, dat);
    }

    // ========================================================================
    // Functions - bibliographic lookup - search terms
    // ========================================================================

    /**
     * Get the search terms to be provided for lookup.
     *
     * @param {Selector} [form]       Default: {@link formElement}.
     *
     * @returns {LookupRequest|undefined}
     */
    function getSearchTermsData(form) {
        return lookupButton(form)?.data(LookupModal.SEARCH_TERMS_DATA);
    }

    /**
     * Update the search terms to be provided for lookup.
     *
     * @param {Selector}                      form
     * @param {LookupRequest|LookupCondition} [value]
     */
    function setSearchTermsData(form, value) {
        const $button = lookupButton(form);
        if ($button) {
            let request;
            if (value instanceof LookupRequest) {
                request = value;
            } else {
                request = generateLookupRequest($button, value);
            }
            $button.data(LookupModal.SEARCH_TERMS_DATA, request);
        }
    }

    /**
     * Clear the search terms to be provided for lookup.
     *
     * @param {Selector} form
     */
    function clearSearchTermsData(form) {
        lookupButton(form)?.removeData(LookupModal.SEARCH_TERMS_DATA);
    }

    // noinspection JSUnusedLocalSymbols
    /**
     * Update data on the Lookup button if required. <p/>
     *
     * To avoid excessive work, {@link setSearchTermsData} will only be run
     * if truly required to regenerate the data.
     *
     * @param {ElementEvt} event
     */
    function updateSearchTermsData(event) {
        const $button = $(event.target);
        if ($button.prop('disabled')) { return }
        if (isPresent(getSearchTermsData($button))) { return }
        clearSearchResultsData($button);
        setSearchTermsData($button);
    }

    /**
     * Create a LookupRequest instance.
     *
     * @param {Selector}        form
     * @param {LookupCondition} [value]     Def: {@link getLookupCondition}
     *
     * @returns {LookupRequest}
     */
    function generateLookupRequest(form, value) {
        const request   = new LookupRequest();
        const $button   = lookupButton(form);
        const $form     = formElement($button);
        const $fields   = inputFields($form).filter('.valid');
        const condition = value || getLookupCondition($button);
        for (const [_logical_op, entry] of Object.entries(condition)) {
            for (const [field, active] of Object.entries(entry)) {
                if (active) {
                    const $field = $fields.filter(`[data-field="${field}"]`);
                    const values = $field.val();
                    if (isPresent(values)) {
                        const prefix = LookupRequest.LOOKUP_PREFIX[field];
                        if (prefix === '') {
                            request.add(values);
                        } else {
                            request.add(values, (prefix || 'keyword'));
                        }
                    }
                }
            }
        }
        return request;
    }

    // ========================================================================
    // Functions - bibliographic lookup - search results
    // ========================================================================

    // noinspection JSUnusedLocalSymbols
    /**
     * Get the results from lookup.
     *
     * @param {Selector} [form]
     *
     * @returns {LookupResults|undefined}
     */
    function getSearchResultsData(form) {
        return lookupButton(form)?.data(LookupModal.SEARCH_RESULT_DATA);
    }

    /**
     * Clear the search terms from the button.
     *
     * @param {Selector} [form]
     */
    function clearSearchResultsData(form) {
        lookupButton(form)?.removeData(LookupModal.SEARCH_RESULT_DATA);
    }

    // ========================================================================
    // Functions - bibliographic lookup - user-selected values
    // ========================================================================

    /**
     * Get the user-selected field values from lookup.
     *
     * @param {Selector} [form]
     *
     * @returns {LookupResponseItem|undefined}
     */
    function getFieldResultsData(form) {
        return lookupButton(form)?.data(LookupModal.FIELD_RESULTS_DATA);
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

        const $form   = formElement(form);
        const $fields = inputFields($form);

        handleEvent($fields, 'change', onChange);
        handleEvent($fields, 'input',  delayedBy(REVALIDATE_DELAY, onInput));

        /**
         * Revalidate the form after the element's content changes. <p/>
         *
         * In the case of checkboxes/radio buttons this happens when the value
         * of the element changes; otherwise it happens when the element loses
         * focus.
         *
         * @param {ElementEvt} event
         */
        function onChange(event) {
            DEBUG_INPUT && OUT.debug('*** CHANGE ***');
            validateInputField(event);
        }

        /**
         * Respond to key presses only after the user has paused, rather than
         * re-validating the entire form with every key stroke.  This also
         * applies to cut, paste, drag, drop, and delete input event types.
         *
         * @param {InputEvt} event
         *
         * @see https://www.w3.org/TR/input-events-1#interface-InputEvent
         */
        function onInput(event) {
            const type = (event?.originalEvent || event)?.inputType || '';
            DEBUG_INPUT && OUT.debug(`*** INPUT ${type} ***`);
            if (!type.startsWith('format')) {
                validateInputField(event, undefined, false);
            }
        }

        /**
         * Update a single input field then revalidate the form.
         *
         * @param {ElementEvt}  event
         * @param {string|null} [value] Default: current element value.
         * @param {boolean}     [trim]  If **false**, don't trim white space.
         */
        function validateInputField(event, value, trim) {
            const $field = $(event.target);
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
        const $form   = formElement(form);
        const $fields = inputFields($form);
        let ready     = !$fields.is(INVALID);
        if ((ready &&= !menuMultiFields($form).is(INVALID))) {
            const editing = isEditForm($form);
            let recheck   = editing;
            if (uploader) {
                if (uploader.fileSelected()) {
                    recheck = false;
                } else if (!editing) {
                    ready = false;
                }
            }
            if (editing) {
                let changed = false;
                $fields.each((_, field) => {
                    const $field   = $(field);
                    const current  = valueOf($field);
                    const original = getOriginalValue($field);
                    if (current !== original) {
                        if (original && !current) {
                            markForDeletion($field);
                        } else {
                            unmarkForDeletion($field);
                        }
                        changed = true;
                    }
                });
                if (recheck) {
                    ready = changed;
                }
            } else if (recheck) {
                const items = $fields.toArray();
                ready = items.some(i => (valueOf(i) !== getOriginalValue(i)));
            }
        }
        enableSubmit($form, ready);
    }

    /**
     * Enable form submission.
     *
     * @param {Selector} [form]       Default: {@link formElement}.
     * @param {boolean}  [enable]     If **false** run {@link disableSubmit}.
     *
     * @returns {jQuery}              The submit button.
     */
    function enableSubmit(form, enable) {
        if (enable === false) {
            return disableSubmit(form);
        }
        const $form = formElement(form);
        const tip   = submitReadyTooltip($form);
        return submitButton($form)
            .addClass(BEST_CHOICE_MARKER)
            .removeClass('forbidden disabled')
            .prop('disabled', false)
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
        const $form = formElement(form);
        const tip   = submitNotReadyTooltip($form);
        return submitButton($form)
            .removeClass(BEST_CHOICE_MARKER)
            .addClass('forbidden')
            .prop('disabled', true)
            .attr('title', tip)
            .attr('data-state', 'not-ready');
    }

    // ========================================================================
    // Functions - reCAPTCHA verification
    // ========================================================================

    /**
     * CSS class for a form requiring reCAPTCHA verification.
     *
     * @readonly
     * @type {string}
     */
    const RECAPTCHA_FORM_CLASS = 'recaptcha-verification';

    /**
     * Determine whether submission of the form is dependent on reCAPTCHA.
     *
     * @note This should never be *true* for the test environment.
     *
     * @param {Selector} [form]         Passed to {@link formElement}.
     *
     * @returns {boolean}
     */
    function requiresRecaptcha(form) {
        return formElement(form).hasClass(RECAPTCHA_FORM_CLASS);
    }

    /**
     * Get reCAPTCHA verification, first making the callback functions
     * available globally so that reCAPTCHA can find them.
     *
     * @param {ElementEvt} [event]
     */
    function verifyRecaptcha(event) {
        window.successfulRecaptcha = successfulRecaptcha;
        window.failedRecaptcha     = failedRecaptcha;
        event.preventDefault();
        clearFlash();
        // noinspection JSUnresolvedReference
        grecaptcha.execute();
    }

    /**
     * Called after reCAPTCHA verification is successful to complete submission
     * of the form.
     *
     * (Set by name as the :callback option in RecaptchaHelper#recaptcha in
     * place of the function "invisibleRecaptchaSubmit" that would be generated
     * by the "recaptcha" gem.)
     */
    function successfulRecaptcha() {
        const $form = formElement();
        setFormSubmitting($form);
        $form[0].submit();
    }

    /**
     * Called after reCAPTCHA verification failure.
     *
     * (Only called if the :'error-callback' option is set to this name in
     * RecaptchaHelper#recaptcha.)
     */
    function failedRecaptcha() {
        console.error('failedRecaptcha:', arguments);
    }

    // ========================================================================
    // Functions - form submission
    // ========================================================================

    /**
     * Indicate that submission process has been initiated.
     *
     * @param {ElementEvt} [event]
     */
    function startSubmission(event) {
        const $button = $(event.currentTarget || event.target);
        const $form   = formElement($button);
        clearFlash();
        setFormSubmitting($form);
        if (isEditForm($form)) {
            fieldContainer($form).find(`[${TO_DELETE_ATTR}]`).each((_, f) => {
                markAsDeleting(f);
            });
        }
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
     * Actively cancel the current action. <p/>
     *
     * The Upload record is restored to its original state (non-existence in
     * the case of the create form).
     *
     * @param {ElementEvt} [event]
     */
    function cancelSubmission(event) {
        const $button = $(event.currentTarget || event.target);
        const $form   = formElement($button);
        clearFlash();
        if (!formState($form)) {
            setFormCanceled($form);
            if (PROPERTIES.Path.cancel) {
                const path   = $button.attr('data-path');
                const fields = isEditForm($form) && revertEditData($form);
                cancelCurrent($form, path, fields);
            } else {
                cancelAction($button);
            }
        }
        event.stopPropagation();
        event.preventDefault();
    }

    /**
     * Cancel the current action.
     *
     * @param {Selector}      [form]        Default: {@link formElement}.
     * @param {string}        [redirect]
     * @param {string|object} [fields]
     */
    function cancelCurrent(form, redirect, fields) {
        const $form  = formElement(form);
        const sid    = submissionParams($form);
        const params = { redirect: PROPERTIES.Path.index, ...sid };
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
        const $form = formElement(form);
        if (formState($form)) {
            // Either Submit or Cancel has already been invoked.
        } else if (isEditForm($form)) {
            abortCurrent($form, revertEditData($form));
        } else {
            abortCurrent($form);
        }
    }

    /**
     * Inform the server that the submission should be canceled.
     *
     * @param {Selector}      [form]        Default: {@link formElement}.
     * @param {string|object} [fields]
     * @param {string}        [url]
     */
    function abortCurrent(form, fields, url = PROPERTIES.Path.cancel) {
        const $form = formElement(form);
        setFormCanceled($form);
        if (isEmpty(url)) {
            return;
        }
        const params = submissionParams($form);
        if (fields) {
            params.revert = encodeURIComponent(
                (typeof fields === 'string') ? fields : JSON.stringify(fields)
            );
        }
        $.ajax({
            url:     makeUrl(url, params),
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

        const $form = formElement(form);

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
            _debugXhr('ajax:before - arguments', Array.from(arguments));
        }

        /**
         * Pre-process form fields before the form is actually submitted.
         *
         * @param {object} arg
         */
        function beforeAjaxFormSubmission(arg) {
            _debugXhr('ajax:beforeSend - arguments', Array.from(arguments));

            // Disable empty database fields so they are not transmitted back
            // as form data.
            inputFields($form).each((_, input) => {
                if (isEmpty(input.value) || (input.value === EMPTY_VALUE)) {
                    input.disabled = true;
                }
            });

            // If the source repository control is disabled (when editing a
            // completed submission), re-enable it so that it *is* transmitted.
            const $repo = sourceRepositoryMenu($form);
            if ($repo.prop('disabled')) {
                $repo.prop('disabled', false);
            }
        }

        /**
         * Called if "ajax:before" or "ajax:beforeSend" rejects the request.
         *
         * @param {object} arg
         */
        function onAjaxStopped(arg) {
            _debugXhr('ajax:stopped - arguments', Array.from(arguments));
        }

        /**
         * Process rails-ujs "ajax:success" event data.
         *
         * @param {object} arg
         */
        function onAjaxFormSubmissionSuccess(arg) {
            _debugXhr('ajax:success - arguments', Array.from(arguments));
            const data  = arg.data;
            const event = arg.originalEvent || {};
            // noinspection JSUnusedLocalSymbols
            const [_resp, _status_text, xhr] = event.detail || [];
            const status = xhr.status;
            onCreateSuccess(data, status, xhr);
        }

        /**
         * Process rails-ujs "ajax:error" event data.
         *
         * @param {object} arg
         */
        function onAjaxFormSubmissionError(arg) {
            _debugXhr('ajax:error - arguments', Array.from(arguments));
            const error = arg.data;
            const event = arg.originalEvent || {};
            // noinspection JSUnusedLocalSymbols
            const [_resp, _status_text, xhr] = event.detail || [];
            const status = xhr.status;
            OUT.error('ajax:error', status, 'error', error, 'xhr', xhr);
            onCreateError(xhr, status, error);
        }

        /**
         * Process rails-ujs "ajax:complete" event data.
         *
         * @param {object} arg
         */
        function onAjaxFormSubmissionComplete(arg) {
            _debugXhr('ajax:complete - arguments', Array.from(arguments));
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
            const func   = 'onCreateSuccess';
            const flash  = compact(extractFlashMessage(xhr));
            const entry  = pluralize(Emma.Messages.entry, flash.length);
            const action = termActionOccurred();
            let message  = `${Emma.Messages.EMMA} ${entry} ${action}`;
            if (isPresent(flash)) {
                message += ` ${Emma.Messages.for}: ` + flash.join(', ');
            }
            OUT.debug(`${func}:`, message);
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
            const action = termAction($form);
            let message  = `${action} ${Emma.Messages.error}:`.toUpperCase();
            if (flash.length > 1) {
                message += "\n" + flash.join("\n");
            } else if (flash.length === 1) {
                message += ' ' + flash[0];
            } else {
                message += ` ${status}: ${error}`;
            }
            OUT.warn(`${func}:`, message);
            showFlashError(message);
            requireFormCancellation($form);
        }

        /**
         * Restore empty database fields at the end of the submission response.
         *
         * @param {XMLHttpRequest} [_xhr]
         * @param {string}         [_status]
         */
        function onCreateComplete(_xhr, _status) {
            databaseInputFields($form).each((_, e) => { e.disabled = false });
        }
    }

    // ========================================================================
    // Functions - form field filtering
    // ========================================================================

    let filter_initialized;

    /**
     * A flag to indicate whether field filtering has occurred yet.
     *
     * @type {boolean}  **false** on the first invocation; **true** thereafter
     */
    function filterInitialized() {
        const initialized  = filter_initialized || false;
        filter_initialized = true;
        return initialized;
    }

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
        const $form = formElement(form);
        let mode    = new_mode;
        if (notDefined(mode)) {
            let [action, general, first] = [];
            const current = termAction($form);
            const filters = Object.entries(PROPERTIES.Filter);
            for (const [group, property] of filters) {
                if (property.default === current) {
                    action = group;
                } else if (property.default) {
                    general = group;
                } else {
                    first = first || group;
                }
            }
            mode = action || general || first;
        }
        const $buttons = fieldDisplayFilterButtons($form);
        const $button  = $buttons.filter(`[value="${mode}"]`);
        $button.prop('checked', true)
        $button.trigger('change');
    }

    /**
     * Listen for changes on field display filter selection.
     *
     * @param {Selector} [form]  Passed to {@link fieldDisplayFilterButtons}.
     *
     * @see "BaseDecorator::Form#field_group_controls"
     */
    function monitorFieldDisplayFilterButtons(form) {

        const $form    = formElement(form);
        const $buttons = fieldDisplayFilterButtons($form);

        handleEvent($buttons, 'change', fieldDisplayFilterHandler);

        /**
         * Update field display filtering if the target is checked.
         *
         * @param {ElementEvt} event
         */
        function fieldDisplayFilterHandler(event) {
            const $target = $(event.currentTarget || event.target);
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
        const func  = 'filterFieldDisplay';
        const obj   = (typeof new_mode === 'object');
        const form  = obj ? new_mode  : form_sel;
        const $form = formElement(form);
        const mode  =
            (obj ? undefined : new_mode) || fieldDisplayFilterCurrent($form);
        switch (mode) {
            case 'available': fieldDisplayAvailable($form); break;
            case 'invalid':   fieldDisplayInvalid($form);   break;
            case 'filled':    fieldDisplayFilled($form);    break;
            case 'all':       fieldDisplayAll($form);       break;
            default:          OUT.error(`${func}: invalid mode:`, mode);
        }
        // Scroll so that the first visible field is at the top of the display
        // beneath the field display controls.
        if (filterInitialized()) {
            $form[0].scrollIntoView();
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
        const $fields    = fieldContainer(form).children().hide();
        const $visible   = $fields.filter(match);
        const $no_fields = $fields.filter('.no-fields');
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
        const $fields = fieldContainer(form).children().show();
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
        const $element = $(element);
        let old_tip    = $element.attr('data-title');
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
        const $element = $(element);
        const old_tip  = $element.attr('data-title');
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
        const $element = $(element);
        const $icon    = presence($element.children(SYMBOL)) || $element;
        let old_icon   = $element.attr('data-icon');
        if (isMissing(old_icon)) {
            old_icon = $icon.text();
            if (isPresent(old_icon)) {
                $element.attr('data-icon', old_icon);
            }
        }
        const new_icon = icon || PROPERTIES.Status.blank.label;
        $icon.text(new_icon);
    }

    /**
     * Change the previous status marker icon.
     *
     * @param {Selector} element
     */
    function restoreIcon(element) {
        const $element = $(element);
        const $icon    = presence($element.children(SYMBOL)) || $element;
        const old_icon = $element.attr('data-icon') || '';
        $icon.text(old_icon);
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
        const $form = form && selfOrParent(form, FORM_SELECTOR);
        return presence($form) || presence($bulk_op_form) || $model_form;
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
            OUT.warn(`No submission ID for ${MODEL}`);
        } else {
            const value = formField('id', form).val();
            if (value) { return { id: value } }
            OUT.warn(`No database record ID for ${MODEL}`);
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
     * @see SingleUploader.fileInputTarget
     */
    function buttonTray(form) {
        const MATCH = BUTTON_TRAY;
        const $elem = form && $(form);
        return $elem?.is(MATCH) ? $elem : formElement($elem).find(MATCH);
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
        const MATCH = SUBMIT_BUTTON;
        const $elem = form && $(form);
        return $elem?.is(MATCH) ? $elem : buttonTray($elem).children(MATCH);
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
        const MATCH = CANCEL_BUTTON;
        const $elem = form && $(form);
        return $elem?.is(MATCH) ? $elem : buttonTray($elem).children(MATCH);
    }

    /**
     * The container for the field filtering controls.
     *
     * @param {Selector} [form]       Default: {@link formElement}.
     *
     * @returns {jQuery}
     */
    function fieldDisplayFilterContainer(form) {
        return formElement(form).find(FIELD_GROUP);
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
        return formElement(form).find(FIELD_CONTAINER);
    }

    /**
     * All input fields.
     *
     * @param {Selector} [form]       Passed to {@link fieldContainer}.
     *
     * @returns {jQuery}
     */
    function inputFields(form) {
        return fieldContainer(form).find(FORM_FIELD);
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
        return fieldContainer(form).find(`${MENU_MULTI}.value[data-field]`);
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
     * @param {Selector} [_form]      Passed to {@link cancelButton}.
     *
     * @returns {boolean}
     */
    function canCancel(_form) {
        return true; // TODO: canCancel ???
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
        const $form   = formElement(form);
        const message = Emma.Messages.form.cancel_first;
        const tooltip = { 'title': message };
        uploader?.cancel();
        uploader?.disableFileSelectButton();
        disableSubmit($form).attr(tooltip);
        fieldContainer($form).attr(tooltip);
        inputFields($form).attr(tooltip).each((_, e) => { e.disabled = true });
        cancelButton($form).addClass(BEST_CHOICE_MARKER);
    }

    /**
     * The state of form submission.
     *
     * @param {Selector} [form]       Default: {@link formElement}.
     *
     * @returns {string|undefined}
     */
    function formState(form) {
        return formElement(form).data(FORM_STATE_DATA);
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
        const $form = formElement(form);
        const value = isDefined(state) ? state.toString() : undefined;
        if (isDefined(value)) {
            $form.data(FORM_STATE_DATA, value);
        } else {
            $form.removeData(FORM_STATE_DATA);
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
    function isNewForm(form) {
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
    function isEditForm(form) {
        return formElement(form).hasClass('edit');
    }

    /**
     * Displayable term for the action associated with the form.
     *
     * @param {Selector} [form]       Passed to {@link isEditForm}.
     *
     * @returns {string}
     */
    function termAction(form) {
        return isEditForm(form) ? UPDATE : CREATE;
    }

    /**
     * Displayable term for the past-tense action associated with the form.
     *
     * @param {Selector} [form]       Passed to {@link isEditForm}.
     *
     * @returns {string}
     */
    function termActionOccurred(form) {
        return isEditForm(form) ? UPDATED : CREATED;
    }

    /**
     * The label for the Submit button.
     *
     * @param {Selector} [form]         Passed to {@link formElement}.
     * @param {boolean}  [can_submit]   Default: {@link canSubmit}.
     *
     * @returns {string}
     */
    function submitLabel(form, can_submit) {
        const $form = formElement(form);
        const asset = endpointProperties($form).submit || {};
        const state = selectProperties($form, 'submit', can_submit, asset);
        return state?.label || asset.label;
    }

    /**
     * The tooltip for the Submit button.
     *
     * @param {Selector} [form]         Passed to {@link formElement}.
     * @param {boolean}  [can_submit]   Default: {@link canSubmit}.
     *
     * @returns {string}
     */
    function submitTooltip(form, can_submit) {
        const $form = formElement(form);
        const asset = endpointProperties($form).submit || {};
        const state = selectProperties($form, 'submit', can_submit, asset);
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
     * @param {boolean}  [can_cancel]   Default: {@link canCancel}.
     *
     * @returns {string}
     */
    function cancelLabel(form, can_cancel) {
        const $form = formElement(form);
        const asset = endpointProperties($form).cancel || {};
        const state = selectProperties($form, 'cancel', can_cancel, asset);
        return state?.label || asset?.label;
    }

    /**
     * The current tooltip for the Cancel button.
     *
     * @param {Selector} [form]         Default: {@link formElement}.
     * @param {boolean}  [can_cancel]   Default: {@link canCancel}.
     *
     * @returns {string}
     */
    function cancelTooltip(form, can_cancel) {
        const $form = formElement(form);
        const asset = endpointProperties($form).cancel || {};
        const state = selectProperties($form, 'cancel', can_cancel, asset);
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
     * @see SingleUploader._selectProperties
     */
    function selectProperties(form, op_name, can_perform, asset) {
        const func  = 'selectProperties';
        const $form = formElement(form);
        let perform = can_perform;
        if (notDefined(perform)) {
            switch (op_name) {
                case 'submit': perform = canSubmit($form); break;
                case 'cancel': perform = canCancel($form); break;
              //case 'select': perform = canSelect($form); break;
                default:       OUT.error(`${func}: invalid: "${op_name}"`);
            }
        }
        /** @type {ActionProperties} */
        const op = asset || endpointProperties($form)[op_name];
        return op && (perform ? op.if_enabled : op.if_disabled);
    }

    /**
     * Get the configuration properties for the current form action.
     *
     * @param {Selector} [form]       Passed to {@link isEditForm}.
     *
     * @returns {EndpointProperties}
     *
     * @see SingleUploader._endpointProperties
     */
    function endpointProperties(form) {
        const $form  = formElement(form);
        const action = PROPERTIES.Action || {};
        if (isBulkOpForm($form)) {
            return isEditForm($form) ? action.bulk_edit : action.bulk_new;
        } else {
            return isEditForm($form) ? action.edit : action.new;
        }
    }

    // ========================================================================
    // Functions - flash messages
    // ========================================================================

    /**
     * Show flash messages (unless disabled).
     *
     * @param {string|string[]} text
     */
    function showFlashMessage(text) {
        FLASH_MESSAGES && flashMessage(text);
    }

    /**
     * Show flash errors (unless disabled).
     *
     * @param {string} text
     */
    function showFlashError(text) {
        FLASH_ERRORS && flashError(text);
    }

    // ========================================================================
    // Functions - other
    // ========================================================================

    /**
     * Emit a console message if debugging communications.
     *
     * @param {...*} args
     */
    function _debugXhr(...args) {
        DEBUG_XHR && OUT.debug('XHR:', ...args);
    }

    // ========================================================================
    // Actions
    // ========================================================================

    // Setup bibliographic lookup first so that linkages are in place before
    // setupLookupButton() executes.
    if (lookupButton($model_form)) { LookupModal.initializeAll() }

    // Setup Uppy for any `<input type="file">` elements.
    $model_form.each((_, form) => initializeModelForm(form));

    // Setup handlers for bulk operation pages.
    $bulk_op_form.each((_, form) => initializeBulkOpForm(form));

});
