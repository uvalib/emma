// app/assets/javascripts/controllers/manifest-edit.js


import { AppDebug }                           from '../application/debug';
import { appSetup }                           from '../application/setup';
import { arrayWrap }                          from '../shared/arrays';
import { Emma }                               from '../shared/assets';
import { HIDDEN, selector, toggleHidden }     from '../shared/css';
import * as Field                             from '../shared/field';
import { turnOffAutocompleteIn }              from '../shared/form';
import { InlinePopup }                        from '../shared/inline-popup';
import { LookupModal }                        from '../shared/lookup-modal';
import { LookupRequest }                      from '../shared/lookup-request';
import { ModalHideHooks, ModalShowHooks }     from '../shared/modal_hooks';
import { compact, deepDup, hasKey, toObject } from '../shared/objects';
import { randomizeName }                      from '../shared/random';
import { timestamp }                          from '../shared/time';
import { MultiUploader }                      from '../shared/uploader';
import { cancelAction }                       from '../shared/url';
import {
    isDefined,
    isEmpty,
    isMissing,
    isPresent,
    notDefined,
    presence,
} from '../shared/definitions';
import {
    debounce,
    handleClickAndKeypress,
    handleEvent,
    handleHoverAndFocus,
    onPageExit,
    windowEvent,
} from '../shared/events';
import {
    addFlashError,
    clearFlash,
    flashError,
    flashMessage,
} from '../shared/flash';
import {
    selfOrDescendents,
    selfOrParent,
    single,
    uniqAttrs,
} from '../shared/html';
import {
    ITEM_ATTR,
    ITEM_MODEL,
    MANIFEST_ATTR,
    PAGE_PROPERTIES,
    attribute,
    buttonFor,
    enableButton,
    initializeButtonSet,
    serverBulkSend,
    serverSend,
} from '../shared/manifests';


const MODULE = 'ManifestEdit';
const DEBUG  = true;

AppDebug.file('controllers/manifest-edit', MODULE, DEBUG);

// noinspection SpellCheckingInspection, FunctionTooLongJS
appSetup(MODULE, function() {

    /**
     * Manifest creation page.
     *
     * @type {jQuery}
     */
    const $body = $('body.manifest:not(.select)').filter('.new, .edit');

    // Only perform these actions on the appropriate pages.
    if (isMissing($body)) {
        return;
    }

    // ========================================================================
    // Type definitions
    // ========================================================================

    /**
     * @typedef {object} Manifest
     *
     * @property {string} id
     * @property {string} user_id
     * @property {string} name
     * @property {string} created_at
     * @property {string} updated_at
     */

    /**
     * @typedef {EmmaData} ManifestItemData
     *
     * @see ManifestItem
     *
     * @property {number}  [id]
     * @property {string}  [manifest_id]
     * @property {number}  row
     * @property {number}  delta
     * @property {boolean} editing
     * @property {boolean} deleting
     * @property {string}  last_saved
     * @property {string}  last_lookup
     * @property {string}  last_submit
     * @property {string}  created_at
     * @property {string}  updated_at
     * @property {string}  data_status
     * @property {string}  file_status
     * @property {string}  ready_status
     * @property {string}  repository
     * @property {object}  backup
     * @property {string}  last_indexed
     * @property {string}  submission_id
     */

    /**
     * @typedef {object} ManifestItem
     *
     * @see ManifestItemData
     *
     * @property {number}       id
     * @property {string}       manifest_id
     * @property {number}       row
     * @property {number}       delta
     * @property {boolean}      editing
     * @property {boolean}      deleting
     * @property {string}       [last_saved]
     * @property {string}       [last_lookup]
     * @property {string}       [last_submit]
     * @property {string}       created_at
     * @property {string}       updated_at
     * @property {string}       data_status
     * @property {string}       file_status
     * @property {string}       ready_status
     * @property {object}       [file_data]
     * @property {string}       repository
     * @property {singleString} emma_publicationDate
     * @property {multiString}  emma_formatFeature
     * @property {singleString} emma_version
     * @property {singleString} bib_series
     * @property {singleString} bib_seriesType
     * @property {singleString} bib_seriesPosition
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
     * @property {singleString} rem_complete            NOTE: not boolean
     * @property {singleString} rem_coverage
     * @property {multiString}  rem_remediatedAspects
     * @property {singleString} rem_textQuality
     * @property {singleString} rem_status
     * @property {singleString} rem_remediationDate
     * @property {singleString} rem_comments
     * @property {object}       [backup]
     * @property {string}       [last_indexed]
     * @property {string}       [submission_id]
     */

    /**
     * ManifestItemTable
     *
     * ManifestItem record values per record ID.
     *
     * @typedef {Object.<number,ManifestItem>} ManifestItemTable
     */

    /**
     * MessageTable
     *
     * One or more message strings per topic.
     *
     * @typedef {Object.<string,(string|string[])>} MessageTable
     */

    /**
     * JSON format of a response message containing a list of ManifestItems.
     *
     * @see "ManifestItemController#bulk_update_response"
     *
     * @typedef {{
     *      items: {
     *          properties: RecordMessageProperties,
     *          list:       ManifestItem[],
     *      }
     * }} ManifestRecordMessage
     */

    /**
     * JSON format of a response message containing a list of ManifestItems.
     *
     * @typedef {{
     *      items: {
     *          list:       number[],
     *      }
     * }} ManifestItemIdMessage
     */

    /**
     * CreateResponse
     *
     * @see "ManifestItemConcern#create_manifest_item"
     *
     * @typedef {ManifestItem} CreateResponse
     */

    /**
     * UpdateResponse
     *
     * @see "ManifestItemConcern#finish_editing"
     *
     * @typedef {{
     *     items:     ManifestItemTable|null|undefined,
     *     pending?:  ManifestItemTable|null|undefined,
     *     problems?: MessageTable|null|undefined,
     * }} UpdateResponse
     */

    /**
     * FinishEditResponse
     *
     * @typedef {UpdateResponse} FinishEditResponse
     */

    /**
     * JSON format of a response from "/manifest/create" or "/manifest/update".
     *
     * @typedef {Manifest} ManifestMessage
     */

    /**
     * JSON format of a response message from "/manifest/save.
     *
     * @typedef {{ items: ManifestItemTable }} ManifestSaveMessage
     */

    // ========================================================================
    // Constants
    // ========================================================================

    /**
     * Indicates whether expand/contract controls rotate (via CSS transition)
     * or whether their state is indicated by different icons (if *false*).
     *
     * @type {boolean}
     *
     * @see file:stylesheets/controllers/_manifest_item.scss $controls-rotate
     */
    const CONTROLS_ROTATE = true;

    /**
     * Name of the attribute indicating the ManifestItem database table column
     * associated with a grid cell and its descendents.
     *
     * @type {string}
     */
    const FIELD_ATTR = 'data-field';

    const HEADING_CLASS         = 'heading-bar';
    const TITLE_TEXT_CLASS      = `text.name`;
    const TITLE_EDIT_CLASS      = `title-edit`;
    const TITLE_EDITOR_CLASS    = `line-editor`;
    const TITLE_UPDATE_CLASS    = `update`;
    const TITLE_CANCEL_CLASS    = `cancel`;

    const CONTAINER_CLASS       = 'manifest-grid-container';
    const SUBMIT_CLASS          = 'submit-button';
    const CANCEL_CLASS          = 'cancel-button';
    const IMPORT_CLASS          = 'import-button';
    const EXPORT_CLASS          = 'export-button';
    const SUBMISSION_CLASS      = 'submission-button';
    const COMM_STATUS_CLASS     = 'comm-status';
    const GRID_CLASS            = 'manifest_item-grid';
    const CTRL_EXPANDED_MARKER  = 'controls-expanded';
    const HEAD_EXPANDED_MARKER  = 'head-expanded';
    const TO_DELETE_MARKER      = 'deleting';
    const ROW_CLASS             = 'manifest_item-grid-item';
    const HEADER_CLASS          = 'head';
    const COL_EXPANDER_CLASS    = 'column-expander';
    const ROW_EXPANDER_CLASS    = 'row-expander';
    const EXPANDED_MARKER       = 'expanded';
    const CONTROLS_CELL_CLASS   = 'controls';
    const TRAY_CLASS            = 'icon-tray';
    const ICON_CLASS            = 'icon';
    const DETAILS_CLASS         = 'details';
    const INDICATORS_CLASS      = 'indicators';
    const INDICATOR_CLASS       = 'indicator';
    const DATA_CELL_CLASS       = 'cell';
    const EDITING_MARKER        = 'editing';
    const CHANGED_MARKER        = 'changed';
    const ERROR_MARKER          = 'error';
    //const REQUIRED_MARKER     = 'required';
    const ROW_FIELD_CLASS       = 'value';
    const CELL_VALUE_CLASS      = ROW_FIELD_CLASS;
    const CELL_DISPLAY_CLASS    = CELL_VALUE_CLASS;
    const CELL_EDIT_CLASS       = 'edit';

    const HEADING       = selector(HEADING_CLASS);
    const TITLE_TEXT    = selector(TITLE_TEXT_CLASS);
    const TITLE_EDIT    = selector(TITLE_EDIT_CLASS);
    const TITLE_EDITOR  = selector(TITLE_EDITOR_CLASS);
    const TITLE_UPDATE  = selector(TITLE_UPDATE_CLASS);
    const TITLE_CANCEL  = selector(TITLE_CANCEL_CLASS);

    const CONTAINER     = selector(CONTAINER_CLASS);
    const SUBMIT        = selector(SUBMIT_CLASS);
    const CANCEL        = selector(CANCEL_CLASS);
    const IMPORT        = selector(IMPORT_CLASS);
    const EXPORT        = selector(EXPORT_CLASS);
    const SUBMISSION    = selector(SUBMISSION_CLASS);
    const COMM_STATUS   = selector(COMM_STATUS_CLASS);
    const GRID          = selector(GRID_CLASS);
    const TO_DELETE     = selector(TO_DELETE_MARKER);
    const ROW           = selector(ROW_CLASS);
    const HEADER        = selector(HEADER_CLASS);
    const HEAD_ROW      = `${ROW}${HEADER}`;
    const ALL_DATA_ROW  = `${ROW}:not(${HEADER})`;
    const DATA_ROW      = `${ALL_DATA_ROW}:not(${HIDDEN})`;
    const COL_EXPANDER  = selector(COL_EXPANDER_CLASS);
    const ROW_EXPANDER  = selector(ROW_EXPANDER_CLASS);
    const EXPANDED      = selector(EXPANDED_MARKER);
    const CONTROLS_CELL = selector(CONTROLS_CELL_CLASS);
    const TRAY          = selector(TRAY_CLASS);
    const ICON          = selector(ICON_CLASS);
    const DETAILS       = selector(DETAILS_CLASS);
    const INDICATORS    = selector(INDICATORS_CLASS);
    const INDICATOR     = selector(INDICATOR_CLASS);
    const DATA_CELL     = selector(DATA_CELL_CLASS);
    const EDITING       = selector(EDITING_MARKER);
    //const CHANGED     = selector(CHANGED_MARKER);
    //const ERROR       = selector(ERROR_MARKER);
    //const REQUIRED    = selector(REQUIRED_MARKER);
    const ROW_FIELD     = selector(`${ROW_FIELD_CLASS}[${FIELD_ATTR}]`);
    //const CELL_VALUE  = selector(CELL_VALUE_CLASS);
    const CELL_DISPLAY  = selector(CELL_DISPLAY_CLASS);
    const CELL_EDIT     = selector(CELL_EDIT_CLASS);

    /**
     * CSS classes for the data cell which indicate the status of the data.
     *
     * @type {string[]}
     */
    const STATUS_MARKERS = [EDITING_MARKER, CHANGED_MARKER, ERROR_MARKER];

    // ========================================================================
    // Variables
    // ========================================================================

    /**
     * The container for the Manifest title and associated controls.
     *
     * @type {jQuery}
     */
    const $title_heading = $(HEADING);
    const $title_text    = $title_heading.find(TITLE_TEXT);
    const $title_edit    = $title_heading.find(TITLE_EDIT);
    const $title_editor  = $title_heading.find(TITLE_EDITOR);
    const $title_input   = $title_editor.find('input[name="name"]');
    const $title_update  = $title_editor.find(TITLE_UPDATE);
    const $title_cancel  = $title_editor.find(TITLE_CANCEL)

    /**
     * The container for the grid and pagination controls.
     *
     * @type {jQuery}
     */
    const $container = $body.find(CONTAINER);

    /**
     * The manifest item grid.
     *
     * @type {jQuery}
     */
    const $grid = $container.find(GRID);

    /**
     * Save/update button.
     *
     * @type {jQuery}
     */
    const $save = $container.find(SUBMIT);

    /**
     * Cancel button.
     *
     * @type {jQuery}
     */
    const $cancel = $container.find(CANCEL);

    /**
     * CSV import button.
     *
     * @type {jQuery}
     */
    const $import = $container.find(IMPORT).find('input');

    /**
     * CSV export button.
     *
     * @type {jQuery}
     */
    const $export = $container.find(EXPORT);

    /**
     * Submit manifest button.
     *
     * @type {jQuery}
     */
    const $submission = $container.find(SUBMISSION);

    /**
     * The element holding transient communication status.
     *
     * @type {jQuery}
     */
    const $comm_status = $container.find(COMM_STATUS);

    // ========================================================================
    // Functions - heading
    // ========================================================================

    const TITLE_DATA = 'titleValue';

    /**
     * Enter title edit mode.
     *
     * @param {jQuery.Event|UIEvent} event
     */
    function onBeginTitleEdit(event) {
        _debug('onBeginTitleEdit: event =', event);
        beginTitleEdit();
    }

    /**
     * Enter title edit mode.
     */
    function beginTitleEdit() {
        //_debug('beginTitleEdit');
        const old_name = $title_text.text()?.trim() || '';
        $title_input.val(old_name);
        $title_heading.data(TITLE_DATA, old_name);
        $title_heading.toggleClass(EDITING_MARKER, true);
    }

    /**
     * Update the name of the Manifest and leave title edit mode.
     *
     * @param {jQuery.Event|UIEvent} event
     */
    function onUpdateTitleEdit(event) {
        _debug('onUpdateTitleEdit: event =', event);
        const new_name = $title_input.val()?.trim() || '';
        const old_name = $title_heading.data(TITLE_DATA) || '';
        const update   = (new_name === old_name) ? undefined : new_name;
        endTitleEdit(update);
    }

    /**
     * Leave title edit mode without changing the Manifest title.
     *
     * @param {jQuery.Event|UIEvent} event
     */
    function onCancelTitleEdit(event) {
        _debug('onCancelTitleEdit: event =', event);
        endTitleEdit();
    }

    /**
     * Create or update the Manifest then leave title edit mode.
     *
     * @param {string} [new_name]    If present, update the Manifest record.
     */
    function endTitleEdit(new_name) {
        //_debug(`endTitleEdit: new_name = "${new_name}"`);
        if (new_name) {
            setManifestName(new_name);
            $title_text.text(new_name);
        }
        $title_heading.toggleClass(EDITING_MARKER, false);
    }

    /**
     * Allow ENTER to work as "Change" and ESC to work as "Keep".
     *
     * @param {jQuery.Event|KeyboardEvent} event
     *
     * @returns {boolean|undefined}
     */
    function onTitleEditKeypress(event) {
        const key = event.key;
        if (key === 'Escape') {
            event.stopImmediatePropagation();
            onCancelTitleEdit(event);
            return false;
        } else if (key === 'Enter') {
            event.stopImmediatePropagation();
            onUpdateTitleEdit(event);
            return false;
        }
    }

    // ========================================================================
    // Functions - form
    // ========================================================================

    /**
     * Initialize the grid and controls.
     */
    function initializeEditForm() {
        _debug('initializeEditForm');
        setTimeout(scrollToTop, 0);
        initializeGrid();
        initializeAllDataRows();
        initializeControlButtons();
    }

    /**
     * Update the condition of the grid and controls.
     */
    function refreshEditForm() {
        refreshGrid();
        enableSave();
        enableExport();
        enableSubmission();
    }

    // ========================================================================
    // Functions - form - buttons
    // ========================================================================

    /**
     * Table of symbolic names for button elements.
     *
     * @type {Object.<string,jQuery>}
     */
    const CONTROL_BUTTONS = {
        submit:     $save,
        cancel:     $cancel,
        import:     $import,
        export:     $export,
        submission: $submission,
    };

    /**
     * initializeControlButtons
     *
     * @see "ManifestDecorator#submit_button"
     */
    function initializeControlButtons() {
        const func = 'initializeControlButtons'; //_debug(func);
        initializeButtonSet(CONTROL_BUTTONS, func);
        // enableSave(false); // NOTE: Initial state determined by server.
        enableExport();
        enableSubmission();
    }

    /**
     * Enable/disable the Save button.
     *
     * @param {boolean} [setting]     Default: {@link checkFormChanged}.
     *
     * @returns {jQuery|undefined}
     */
    function enableSave(setting) {
        //_debug(`enableSave: setting = "${setting}"`);
        const enable = isDefined(setting) ? setting : checkFormChanged();
        return enableControlButton('submit', enable);
    }

    /**
     * Enable/disable the Export button.
     *
     * @param {boolean} [setting]     Def.: presence of {@link activeDataRows}.
     *
     * @returns {jQuery|undefined}
     */
    function enableExport(setting) {
        //_debug(`enableExport: setting = "${setting}"`);
        const yes = isDefined(setting) ? setting : isPresent(activeDataRows());
        return enableControlButton('export', yes);
    }

    /**
     * Enable/disable the Submit button.
     *
     * @param {boolean} [setting]     Def.: presence of {@link activeDataRows}.
     *
     * @returns {jQuery|undefined}
     */
    function enableSubmission(setting) {
        //_debug(`enableSubmission: setting = "${setting}"`);
        const yes = isDefined(setting) ? setting : isPresent(activeDataRows());
        return enableControlButton('submission', yes);
    }

    /**
     * Change control button state.
     *
     * @param {string}  type          One of {@link CONTROL_BUTTONS} keys.
     * @param {boolean} enable
     *
     * @returns {jQuery|undefined}
     */
    function enableControlButton(type, enable) {
        const func = 'enableControlButton';
        _debug(`${func}: type = "${type}"; enable = "${enable}"`);
        const $button = buttonFor(type, CONTROL_BUTTONS, func);
        return enableButton($button, enable, type);
    }

    // ========================================================================
    // Functions - form - update
    // ========================================================================

    /**
     * Save updated row(s).
     *
     * If there is a cell being edited, that edit is abandoned since completing
     * it could change the validation state so that it's not longer safe to
     * save the updates that have been made so far.
     *
     * @param {jQuery.Event|UIEvent} event
     *
     * @see "ManifestConcern#save_changes!"
     */
    function saveUpdates(event) {
        const func     = 'saveUpdates'; _debug(`${func}: event =`, event);
        const manifest = manifestId();

        cancelActiveCell();             // Abandon any active edit.
        finalizeDataRows('original');   // Update "original" cell values.

        // It should not be possible to get here unless the form is associated
        // with a real persisted Manifest record.
        if (!manifest) {
            _error(`${func}: no manifest ID`);
            return;
        }

        // Inform the server to allow it to recalculate row/delta values and
        // update related ManifestItem records.
        /** @type {ManifestSaveMessage} */
        serverManifestSend(`save/${manifest}`, {
            caller:    func,
            onSuccess: onSuccess,
        });

        /**
         * Process the response to replace the provisional row/delta values
         * with the real row numbers (and no deltas).
         *
         * @param {ManifestSaveMessage|undefined} body
         */
        function onSuccess(body) {
            _debug(`${func}: body =`, body);
            // noinspection JSValidateTypes
            /** @type {ManifestItemTable} */
            const data = body?.items || body;
            if (isEmpty(body)) {
                _error(func, 'no response data');
            } else if (isEmpty(data)) {
                _error(func, 'no items present in response data');
            } else {
                flashMessage('Changes saved.');
                updateRowValues(data);
                refreshEditForm();
            }
        }
    }

    /**
     * Cancel all changes since the last save.
     *
     * @param {jQuery.Event|UIEvent} event
     *
     * @see "ManifestConcern#cancel_changes!"
     */
    function cancelUpdates(event) {
        const func     = 'cancelUpdates'; _debug(`${func}: event =`, event);
        const manifest = manifestId();
        const finalize = () => cancelAction($cancel);

        cancelActiveCell();             // Abandon any active edit.
        deleteRows(blankDataRows());    // Eliminate rows unseen by the server.
        finalizeDataRows('original');   // Restore original cell values.

        // The form never resulted in the creation of a Manifest record so
        // there is nothing to inform the server about.
        if (!manifest) {
            _debug(`${func}: canceling un-persisted manifest`);
            finalize();
            return;
        }

        // Inform the server to allow it to discard incomplete records.
        serverManifestSend(`cancel/${manifest}`, {
            caller:     func,
            onComplete: finalize,
        });
    }

    // ========================================================================
    // Functions - form - import
    // ========================================================================

    /**
     * Import manifest item rows.
     *
     * @param {jQuery.Event|UIEvent} event
     */
    function importRows(event) {
        const func = 'importRows'; _debug(`${func}: event =`, event);
        let input, file;
        if (!(input = $import[0])) {
            _error(`${func}: no $import element`);
        } else if (!(file = input.files[0])) {
            _debug(`${func}: no file selected`);
        } else if (manifestId()) {
            importFile(file);
        } else {
            createManifest(undefined, () => importFile(file));
        }
    }

    /**
     * Import manifest items from a CSV file.
     *
     * @param {File} file
     */
    function importFile(file) {
        _debug('importFile: file =', file);
        const reader = new FileReader();
        reader.readAsText(file);
        reader.onloadend = (ev) => importData(ev.target.result, file.name);
    }

    /**
     * Import manifest items from CSV row data.
     *
     * @param {string} data
     * @param {string} [filename]     For diagnostics only.
     */
    function importData(data, filename) {
        const func   = 'importData';
        const type   = dataType(data);
        const params = { data: data, type: type, caller: func };
        const $last  = allDataRows().last();
        if (manifestItemId($last)) {
            params.row   = dbRowValue($last);
            params.delta = dbRowDelta($last);
        }
        _debug(`${func}: from "${filename}": type = "${type}"; data =`, data);
        sendCreateRecords(data, params);
    }

    /**
     * Re-import manifest items from CSV row data.
     *
     * @note This is not functional and is just here to serve as a reminder
     *  that this use-case needs to be considered.
     *
     * @param {string} data
     * @param {string} [filename]     For diagnostics only.
     */
    function reImportData(data, filename) {
        const func   = 'reImportData';
        const type   = dataType(data);
        const params = { data: data, type: type, caller: func };
        sendUpdateRecords(data, params);
   }

    // ========================================================================
    // Functions - form - export
    // ========================================================================

    /**
     * Export manifest items to a CSV file.
     *
     * @param {jQuery.Event|UIEvent} event
     */
    function exportRows(event) {
        _debug('exportRows: event =', event);
        flashMessage('EXPORT - FUTURE ENHANCEMENT'); // TODO: exportRows
    }

    // ========================================================================
    // Functions - form - changed state
    // ========================================================================

    /**
     * Update form controls based on form changed state.
     *
     * @param {boolean} [setting]     Default: {@link checkFormChanged}.
     *
     * @returns {boolean}             Changed status.
     */
    function updateFormChanged(setting) {
        _debug(`updateFormChanged: setting = ${setting}`);
        const changed = isDefined(setting) ? setting : checkFormChanged();
        enableSave(changed);
        enableExport();
        enableSubmission();
        return changed;
    }

    /**
     * Check whether the form is in a state where a save is permitted.
     *
     * @param {Selector} [target]
     *
     * @returns {boolean}             Changed status.
     */
    function checkFormChanged(target) {
        //_debug('checkFormChanged: target =', target);
        return checkGridChanged(target);
    }

    // ========================================================================
    // Functions - grid
    // ========================================================================

    /**
     * Selector for elements which are inputs or which enclose inputs.
     *
     * @type {string}
     */
    const INPUTS = [
        '.menu.multi[role="listbox"]',
        '.menu.single',
        '.input.multi',
        '.input.single',
    ].join(', ');

    /**
     * Initial adjustments for the grid display.
     */
    function initializeGrid() {
        _debug('initializeGrid');
        const $cells = allDataCells();
        initializeCellDisplays($cells);
        initializeCellInputs($cells);
        initializeTextareaColumns($cells);
        initializeUploaderCells($cells);
    }

    /**
     * Refresh all cells so that their associated .data() values are
     * initialized to their currently-displayed values.
     *
     * @param {Selector} [cells]      Default: {@link allDataCells}
     */
    function initializeCellDisplays(cells) {
        //_debug('initializeCellDisplays: cells =', cells);
        dataCells(cells).each((_, cell) => updateCellDisplayValue(cell));
    }

    /**
     * Ensure that required inputs have the proper ARIA attribute.
     *
     * @param {Selector} [cells]      Default: {@link allDataCells}
     */
    function initializeCellInputs(cells) {
        //_debug('initializeCellInputs: cells =', cells);
        const $cells = dataCells(cells);
        const $input = $cells.find(INPUTS);
        $.each(fieldProperty(), (field, prop) => {
            if (prop.required) {
                $input.filter(`[name="${field}"]`).attr('aria-required', true);
            }
        });
    }

    /**
     * Resize textareas for all cells so that their respective grid columns end
     * up having widths that can remain constant whenever any of the cells goes
     * into edit mode.
     *
     * The maximum number of characters of the placeholder and any data line is
     * treated as the desired 'cols' attribute for that textarea.  The maximum
     * 'cols' attribute (with a fudge factor for non-constant-width fonts) is
     * used to explicitly set the 'cols' attribute on all included textareas.
     *
     * @see https://developer.mozilla.org/en-US/docs/Web/HTML/Element/textarea
     *
     * @param {Selector} [cells]      Default: {@link allDataCells}
     * @param {number}   [min_cols]   Minimum 'cols' attribute value.
     * @param {number}   [scale]      Heuristic for variable width fonts.
     */
    function initializeTextareaColumns(cells, min_cols = 20, scale = 1.2) {
        //_debug('initializeTextareaColumns: cells =', cells);
        const $textareas   = dataCells(cells).find('textarea');
        const column_width = (max_cols, textarea) => {
            const $area = $(textarea);
            const min   = $area.attr('placeholder')?.length || 0;
            const lines = cellCurrentValue($area).lines.map(v => v.length);
            return Math.max(min, ...lines, max_cols);
        };
        $.each(fieldProperty(), (field, prop) => {
            if (prop.type?.startsWith('text')) {
                const data_field = `[${FIELD_ATTR}="${field}"]`;
                const $column    = $textareas.filter(data_field);
                const textareas  = $column.toArray();
                const max_width  = textareas.reduce(column_width, min_cols);
                const max_cols   = Math.round(max_width * scale);
                textareas.forEach(ta => $(ta).attr('cols', max_cols));
            }
        });
    }

    /**
     * Records that have a non-empty :file_data column when rendered on the
     * server have the contents of that field put into a 'data-value' attribute
     * which needs to be processed here in order to associate the data with the
     * cell.
     *
     * The attribute is removed so there's one less thing to contend with when
     * duplicating rows.
     *
     * @see "ManifestItemDecorator#grid_data_cell_render_pair"
     *
     * @param {Selector} [cells]      Default: {@link allDataCells}
     */
    function initializeUploaderCells(cells) {
        //_debug('initializeUploaderCells: cells =', cells);
        const attr       = 'data-value';
        const name       = attr.replace(/^data-/, '');
        const with_attr  = `[${attr}]`;
        const $uploaders = dataCells(cells).filter(MultiUploader.UPLOADER);
        $uploaders.each((_, cell) => {
            const $cell  = $(cell);
            const $value = selfOrDescendents($cell, with_attr).first();
            const data   = $value.data(name) || {}; // Let jQuery do the work.
            $cell.removeData(name).removeAttr(attr);
            $cell.find(with_attr).removeData(name).removeAttr(attr);
            delete data.emma_data;
            const value = $cell.makeValue(data);
            setCellOriginalValue($cell, value);
            setCellCurrentValue($cell, value);
            setCellDisplayValue($cell, value);
        });
    }

    /**
     * Refresh all grid rows.
     */
    function refreshGrid() {
        _debug('refreshGrid');
        allDataRows().each((_, row) => refreshDataRow(row));
    }

    // ========================================================================
    // Functions - grid - controls
    // ========================================================================

    /**
     * Respond to click of header row expand/contract control.
     *
     * @param {jQuery.Event|UIEvent} event
     */
    function onToggleHeaderRow(event) {
        //_debug('onToggleHeaderRow: event =', event);
        const target = event.currentTarget || event.target;
        toggleHeaderRow(undefined, target);
    }

    /**
     * Expand/contract the header row.
     *
     * @overload toggleHeaderRow(expanded, button)
     *  @param {boolean}  expand
     *  @param {Selector} [button]
     *
     * @overload toggleHeaderRow(expanded)
     *  @param {boolean}  [expand]
     */
    function toggleHeaderRow(expand, button) {
        const func      = 'toggleHeaderRow';
        _debug(`${func}: expand = ${expand}; button =`, button);
        const $button   = button ? $(button) : headerRowToggle();
        const $target   = selfOrParent($button, HEAD_ROW, func);
        const expanding = isDefined(expand) ? !!expand : !$target.is(EXPANDED);
        const config    = Emma.Grid.Headers.row;
        const mode      = expanding ? config.closer : config.opener;

        $button.attr('aria-expanded', expanding);
        $button.attr('title', mode.tooltip);
        if (!CONTROLS_ROTATE) {
            $button.text(mode.label);
        }

        const $items = headerRow();
        $items.toggleClass(EXPANDED_MARKER, expanding);
        if (!expanding) {
            $items.find('details').removeAttr('open');
        }
        $grid.toggleClass(HEAD_EXPANDED_MARKER, expanding);
    }

    /**
     * Respond to click of controls column expand/contract control.
     *
     * @param {jQuery.Event|UIEvent} event
     */
    function onToggleControlsColumn(event) {
        //_debug('onToggleControlsColumn: event =', event);
        const target = event.currentTarget || event.target;
        toggleControlsColumn(undefined, target);
    }

    /**
     * Expand/contract the controls column.
     *
     * @overload toggleControlsColumn(expanded, button)
     *  @param {boolean}  expand
     *  @param {Selector} [button]
     *
     * @overload toggleControlsColumn(expanded)
     *  @param {boolean}  [expand]
     */
    function toggleControlsColumn(expand, button) {
        const func      = 'toggleControlsColumn';
        _debug(`${func}: expand = ${expand}; button =`, button);
        const $button   = button ? $(button) : controlsColumnToggle();
        const $target   = selfOrParent($button, CONTROLS_CELL, func);
        const expanding = isDefined(expand) ? !!expand : !$target.is(EXPANDED);
        const config    = Emma.Grid.Headers.column;
        const mode      = expanding ? config.closer : config.opener;

        $button.attr('aria-expanded', expanding);
        $button.attr('title', mode.tooltip);
        if (!CONTROLS_ROTATE) {
            $button.text(mode.label);
        }

        const $items = controlsColumn();
        $items.toggleClass(EXPANDED_MARKER, expanding);
        if (!expanding) {
            $items.find('details').removeAttr('open');
        }
        $grid.toggleClass(CTRL_EXPANDED_MARKER, expanding);
    }

    // ========================================================================
    // Functions - grid - data
    // ========================================================================

    /**
     * @typedef {Object.<number,number>} DeltaTable
     */

    /**
     * Name of the data() entry for $grid that manages the next delta value for
     * new rows inserted under an existing row.
     *
     * @type {string}
     */
    const DELTA_TABLE_DATA = 'deltaTable';

    /**
     * Get the delta table, creating it if necessary.
     *
     * @returns {DeltaTable}
     */
    function deltaTable() {
        return $grid.data(DELTA_TABLE_DATA) || setDeltaTable();
    }

    /**
     * Replace the value of the delta table.
     *
     * @param {DeltaTable} [value]    Default: empty object.
     *
     * @returns {DeltaTable}
     */
    function setDeltaTable(value) {
        $grid.data(DELTA_TABLE_DATA, { ...value });
        return $grid.data(DELTA_TABLE_DATA);
    }

    /**
     * Return the incremented value of the target row's delta counter.
     *
     * @param {Selector|number} r     Row element or literal row number.
     *
     * @returns {number}              Always >= 1.
     */
    function nextDeltaCounter(r) {
        const table = deltaTable();
        const row   = (typeof r === 'number') ? r : dbRowValue(r);
        const delta = table[row] = 1 + (table[row] || 0);
        setDeltaTable(table);
        return delta;
    }

    /**
     * Remove the indicated rows from the delta table.
     *
     * @param {Selector|number|(Selector|number)[]} rows
     */
    function removeDeltaCounter(rows) {
        const table = deltaTable();
        if (isPresent(table)) {
            arrayWrap(rows).forEach(r => {
                const row = (typeof r === 'number') ? r : dbRowValue(r);
                delete table[row];
            });
            setDeltaTable(table);
        }
    }

    // ========================================================================
    // Functions - grid - changed state
    // ========================================================================

    /**
     * Update row changed state to determine whether the grid has changed.
     *
     * @param {Selector} [target]     Default: {@link allDataRows}
     *
     * @returns {boolean}             False if no changes.
     */
    function evaluateGridChanged(target) {
        _debug('evaluateGridChanged: target =', target);
        const evaluate_row = (change, row) => updateRowChanged(row) || change;
        return dataRows(target).toArray().reduce(evaluate_row, false);
    }

    /**
     * Check row changed state to determine whether the grid has changed.
     *
     * (No stored data values are updated.)
     *
     * @param {Selector} [target]     Default: {@link allDataRows}
     *
     * @returns {boolean}             False if no changes.
     */
    function checkGridChanged(target) {
        //_debug('checkGridChanged: target =', target);
        const check_row = (change, row) => change || checkRowChanged(row);
        return dataRows(target).toArray().reduce(check_row, false);
    }

    // ========================================================================
    // Functions - row
    // ========================================================================

    /**
     * All grid data rows.
     *
     * @param {boolean} [hidden]      Include hidden rows.
     *
     * @returns {jQuery}
     */
    function allDataRows(hidden) {
        return dataRows(null, hidden);
    }

    /**
     * All grid data rows for the given target.
     *
     * @param {Selector|null} [target]  Default: {@link $grid}.
     * @param {boolean}       [hidden]  Include hidden rows.
     *
     * @returns {jQuery}
     */
    function dataRows(target, hidden) {
        const tgt   = target || $grid;
        const match = hidden ? ALL_DATA_ROW : DATA_ROW;
        return selfOrDescendents(tgt, match);
    }

    /**
     * Get the single row container associated with the target.
     *
     * @param {Selector} target
     * @param {boolean}  [hidden]     If *true*, also match template row(s).
     *
     * @returns {jQuery}
     */
    function dataRow(target, hidden) {
        const func  = 'dataRow'; //_debug(`${func}: target =`, target);
        const match = hidden ? ALL_DATA_ROW : DATA_ROW;
        return selfOrParent(target, match, func);
    }

    /**
     * Indicate whether the given row exists in the database (saved or not).
     *
     * @param {Selector} target
     *
     * @returns {boolean}
     */
    function activeDataRow(target) {
        return manifestItemId(target);
    }

    /**
     * All rows that are associated with database items.
     *
     * @param {Selector} [target]     Default: {@link allDataRows}
     *
     * @returns {jQuery}
     */
    function activeDataRows(target) {
        return dataRows(target).filter((_, row) => activeDataRow(row));
    }

    /**
     * Indicate whether the given row is an empty row which has never caused
     * the creation of a database item.
     *
     * @param {Selector} target
     *
     * @returns {boolean}
     */
    function blankDataRow(target) {
        return !manifestItemId(target);
    }

    /**
     * All rows that are not associated with database items.
     *
     * @param {Selector} [target]     Default: {@link allDataRows}
     *
     * @returns {jQuery}
     */
    function blankDataRows(target) {
        return dataRows(target).filter((_, row) => blankDataRow(row));
    }

    /**
     * Use received data to update cell(s) associated with data values.
     *
     * If the row doesn't have a 'data-item-id' attribute it will be set here
     * if data has an 'id' value.
     *
     * @param {Selector}     target
     * @param {ManifestItem} data
     */
    function updateDataRow(target, data) {
        const func = 'updateDataRow';
        _debug(`${func}: data =`, data, 'target =', target);
        if (isEmpty(data)) { return }
        const $row = dataRow(target);

        if (isPresent(data.id)) {
            const db_id =
                manifestItemId($row) || setManifestItemId($row, data.id);
            if (db_id !== data.id) {
                _error(func,`row item ID = ${db_id} but data.id = ${data.id}`);
                return;
            }
        }
        if (hasKey(data, 'row')) {
            setDbRowValue($row, data.row);
        }
        if (hasKey(data, 'delta')) {
            setDbRowDelta($row, data.delta);
        }
        if (data.deleting) {
            console.error(`${func}: received deleted item:`, data);
        }

        let changed;
        dataCells($row).each((_, cell) => {
            let different;
            const $cell = $(cell);
            const field = cellDbColumn($cell);
            const [data_value, data_field] = valueAndField(data, field);
            if (data_field) {
                const old_value = cellCurrentValue($cell);
                const new_value = $cell.makeValue(data_value);
                if ((different = new_value.differsFrom(old_value))) {
                    updateDataCell($cell, new_value, true);
                    changed = true;
                }
            }
            if (!different && cellChanged($cell)) {
                updateCellValid($cell);
                changed = true;
            }
        });
        if (changed) {
            updateRowChanged($row, true);
            updateFormChanged();
        }

        updateRowIndicators($row, data);
        updateRowDetails($row, data);
        updateLookupCondition($row);
    }

    // ========================================================================
    // Functions - row - initialization
    // ========================================================================

    /**
     * If there are rows present on the page at startup, they are initialized.
     * If not, an empty row is inserted.
     */
    function initializeAllDataRows() {
        _debug('initializeAllDataRows');
        const $rows = allDataRows();
        if (isPresent($rows)) {
            $rows.each((_, row) => initializeDataRow(row));
        } else {
            insertRow();
        }
    }

    /**
     * Prepare a single data row.
     *
     * @param {Selector} row
     *
     * @returns {jQuery}
     */
    function initializeDataRow(row) {
        //_debug('initializeDataRow: row =', row);
        const $row = dataRow(row);
        initializeDbRowValue($row);
        initializeDbRowDelta($row);
        initializeRowIndicators($row);
        setupRowFunctionality($row);
        return $row;
    }

    /**
     * Setup event handlers for a single data row.
     *
     * @param {Selector} row
     */
    function setupRowFunctionality(row) {
        _debug('setupRowFunctionality: row =', row);
        const $row = dataRow(row);
        setupLookup($row);
        setupUploader($row);
        setupRowOperations($row);
        setupDataCellEditing($row);
    }

    // ========================================================================
    // Functions - row - finalization
    // ========================================================================

    /**
     * Finalize data rows and their cells prior to page exit.
     *
     * @param {string}   from         'current' or 'original'
     * @param {Selector} [target]     Default: {@link allDataRows}.
     */
    function finalizeDataRows(from, target) {
        _debug(`finalizeDataRows: from ${from}: target =`, target);
        const $rows = dataRows(target);
        finalizeDataCells(from, $rows);
        removeDeltaCounter($rows);
    }

    // ========================================================================
    // Functions - row - refresh
    // ========================================================================

    /**
     * Reset cell stored data values and cell displays.
     *
     * @param {Selector} row
     *
     * @returns {jQuery}
     */
    function refreshDataRow(row) {
        _debug('refreshDataRow: row =', row);
        const $row = dataRow(row);
        clearRowChanged($row);
        clearLookupCondition($row);
        dataCells($row).each((_, cell) => resetDataCell(cell));
        return $row;
    }

    // ========================================================================
    // Functions - row - controls
    // ========================================================================

    /**
     * The name of the attribute indicating the action of a control button.
     *
     * @type {string}
     */
    const ACTION_ATTR = 'data-action';

    /**
     * Attach handlers for row control icon buttons.
     *
     * @param {Selector} [row]     Default: all {@link rowControls}.
     */
    function setupRowOperations(row) {
        _debug('setupRowOperations: row =', row);
        const $cell     = controlsColumn(row);
        const $controls = rowControls($cell);
        handleClickAndKeypress($controls, rowOperation);
        addToControlsColumnToggle($cell);
    }

    /**
     * Perform an operation on a row item.
     *
     * @param {jQuery.Event|UIEvent} event
     */
    function rowOperation(event) {
        _debug('rowOperation: event =', event);
        const $control = $(event.currentTarget || event.target);
        const action   = $control.attr(ACTION_ATTR);
        switch (action) {
            case 'insert': insertRow($control); break;
            case 'delete': deleteRow($control); break;
            case 'lookup': lookupRow($control); break;
            default:       _error(`No function for "${action}"`);
        }
    }

    /**
     * Per-item control icons.
     *
     * @param {Selector} [target]     Default: {@link controlsColumn}.
     *
     * @returns {jQuery}
     */
    function rowControls(target) {
        const $t    = target ? $(target) : null;
        const match = TRAY;
        const $tray = $t?.is(match) ? $t : controlsColumn($t).children(match);
        return $tray.children(ICON);
    }

    /**
     * Per-item control cells.
     *
     * @param {Selector} [target]     Default: {@link $grid}.
     *
     * @returns {jQuery}
     */
    function controlsColumn(target) {
        const tgt = target || $grid;
        return selfOrDescendents(tgt, CONTROLS_CELL);
    }

    /**
     * A operation button for the given row.
     *
     * @param {Selector} row
     * @param {string}   action
     *
     * @returns {jQuery}
     */
    function rowButton(row, action) {
        const match = `[${ACTION_ATTR}="${action}"]`;
        const $row  = $(row);
        return $row.is(match) ? $row : rowControls($row).filter(match);
    }

    /**
     * Enable operation button for the given row.
     *
     * @param {Selector} row
     * @param {string}   action
     * @param {boolean}  [enable]     If *false* then disable.
     * @param {boolean}  [forbid]     If *true* add '.forbidden' if disabled.
     *
     * @returns {jQuery}              The submit button.
     */
    function enableRowButton(row, action, enable, forbid) {
        _debug(`enableRowButton: ${action}: row =`, row);
        return toggleRowButton(row, action, (enable !== false), forbid);
    }

    /**
     * Enable/disable operation button for the given row.
     *
     * @param {Selector} row
     * @param {string}   action
     * @param {boolean}  [enable]
     * @param {boolean}  [forbid]     If *true* add '.forbidden' if disabled.
     *
     * @returns {jQuery}              The submit button.
     */
    function toggleRowButton(row, action, enable, forbid) {
        /** @type {ActionProperties} */
        let config    = Emma.Grid.Icons[action];
        const func    = `toggleRowButton: ${action}`;
        const $button = rowButton(row, action);
        //_debug(`${func}: row =`, row);
        if (!config) {
            console.error(`${func}: invalid action`);
            return $button;
        }

        const is_forbidden      = $button.hasClass('forbidden');
        const old_was_forbidden = $button.hasClass('was-forbidden');
        let now_disabled, now_forbidden, new_was_forbidden;
        if (enable === true) {
            config            = { ...config, ...config.enabled };
            now_disabled      = false;
            now_forbidden     = false;
            new_was_forbidden = is_forbidden || old_was_forbidden;
            if (forbid) { console.warn(`${func}: cannot enable and forbid`) }
        } else if (enable === false) {
            config            = { ...config, ...config.disabled };
            now_disabled      = true;
            now_forbidden     = forbid || false;
            new_was_forbidden = false;
        } else if ($button.hasClass('disabled')) { // Toggle to enabled
            now_disabled      = false;
            now_forbidden     = false;
            new_was_forbidden = is_forbidden || old_was_forbidden;
        } else { // Toggle to disabled
            now_disabled      = true;
            now_forbidden     = forbid || old_was_forbidden;
            new_was_forbidden = !old_was_forbidden;
        }

        const tooltip = (action === 'lookup') && now_forbidden && (
            "Bibliographic metadata is inherited from\n" + // TODO: I18n
            'the original repository entry.'
        );
        $button.attr('title', (tooltip || config.tooltip || ''));

        $button.prop('disabled', now_disabled);
        $button.toggleClass('disabled',      now_disabled);
        $button.toggleClass('forbidden',     now_forbidden);
        $button.toggleClass('was-forbidden', new_was_forbidden);
        return $button;
    }

    // ========================================================================
    // Functions - row - insert
    // ========================================================================

    /**
     * Insert a new empty row after the row associated with the target.
     * If no target is provided a new empty row is inserted into <tbody>.
     *
     * This insertion does not affect the database, although it may be invoked
     * as a response to record creation in order to reflect a new database item
     * on the display.
     *
     * @param {Selector}     [after]        Default: prepend to tbody.
     * @param {ManifestItem} [data]
     * @param {boolean}      [intermediate] If more row changes coming.
     *
     * @returns {jQuery}                    The new row.
     */
    function insertRow(after, data, intermediate) {
        _debug('insertRow after', after);
        let $new_row;
        if (after) {
            const $row = dataRow(after);
            $new_row = emptyDataRow($row);
            $new_row.insertAfter($row);
        } else {
            $new_row = emptyDataRow();
            $new_row.attr('id', 'manifest_item-item-1');
            $grid.children('tbody').prepend($new_row);
        }
        if (isPresent(data)) {
            updateDataRow($new_row, data);
        }
        if (!intermediate) {
            updateGridRowCount(1);
        }
        return $new_row;
    }

    /**
     * Insert new row(s) after the last row in the grid.
     *
     * @param {ManifestItem[]} list
     * @param {boolean}        [intermediate]   If more row changes coming.
     */
    function appendRows(list, intermediate) {
        _debug('appendRows: list =', list);
        const items = arrayWrap(list);
        const $last = allDataRows().last();

        let $row; // When undefined, first insertRow starts with $template_row.
        if (manifestItemId($last)) {
            $row = $last;   // Insert after last row.
        } else if (isPresent($last)) {
            $last.remove(); // Discard empty row.
        }
        let row   = $row ? dbRowValue($row) : 0;
        let delta = $row ? dbRowDelta($row) : 0;
        let mod   = {};
        items.forEach(record => {
            let r, d;
            $row  = insertRow($row, record, true);
            row   = dbRowValue($row) || (r = setDbRowValue($row, row));
            delta = dbRowDelta($row) || (d = setDbRowDelta($row, ++delta));
            setRowChanged($row, true);
            if (r || d) { mod[manifestItemId($row)] = { row: r, delta: d } }
        });
        if (!intermediate) {
            updateGridRowCount(items.length);
        }
        if (isPresent(mod)) {
            sendUpdateRecords(mod);
        }
    }

    /**
     * Create multiple ManifestItem records.
     *
     * @param {object|string} items
     * @param {object}        [opt]
     */
    function sendCreateRecords(items, opt = {}) {
        const caller = opt?.caller || 'sendCreateRecords';
        sendUpsertRecords(items, { caller, ...opt, create: true });
    }

    /**
     * Update multiple ManifestItem records.
     *
     * @param {object|string} items
     * @param {object}        [opt]
     */
    function sendUpdateRecords(items, opt = {}) {
        const caller = opt?.caller || 'sendUpdateRecords';
        sendUpsertRecords(items, { caller, ...opt, create: false });
    }

    /**
     * Create/update multiple ManifestItem records.
     *
     * @param {object|string} items
     * @param {object}        [opt]
     */
    function sendUpsertRecords(items, opt = {}) {
        const func      = opt?.caller || 'sendUpsertRecords';
        const manifest  = manifestId();
        const operation = opt?.create ? 'create' : 'update';
        const action    = `bulk/${operation}/${manifest}`;
        const content   = 'multipart/form-data';
        const accept    = 'text/html';
        _debug(`${func}: items =`, items);

        if (!manifest) {
            _error(`${func}: no manifest ID`);
            return;
        }

        const hdr = opt?.headers;
        if (hdr) { delete opt.headers }
        const prm = opt?.params || opt;

        serverItemSend(action, {
            caller:     func,
            params:     { data: items, ...prm },
            headers:    { 'Content-Type': content, Accept: accept, ...hdr },
            onSuccess:  processReceivedItems,
        });
    }

    /**
     * Append ManifestItems returned from the server.
     *
     * @param {ManifestRecordMessage} body
     *
     * @see "ManifestItemController#bulk_update_response"
     * @see "SerializationConcern#index_values"
     */
    function processReceivedItems(body) {
        const func = 'processReceivedItems'; _debug(`${func}: body =`, body);
        const data = body?.items || body || {};
        const list = data.list;
        if (isEmpty(data)) {
            _error(func, 'no response data');
        } else if (isEmpty(list)) {
            _error(func, 'no items present in response data');
        } else {
            appendRows(list);
        }
    }

    // ========================================================================
    // Functions - row - delete
    // ========================================================================

    /**
     * Mark the indicated row for deletion.
     *
     * @param {Selector} target
     *
     * @returns {jQuery}
     */
    function markRow(target) {
        const func = 'markRow'; //_debug(`${func}: target =`, target);
        const $row = dataRow(target);
        if ($row.is(TO_DELETE)) {
            _debug(`${func}: already marked ${TO_DELETE} -`, $row);
        } else {
            $row.addClass(TO_DELETE_MARKER);
        }
        return $row;
    }

    /**
     * Mark the indicated row for deletion.
     *
     * If it is a blank row (not yet associated with a ManifestItem) then it is
     * removed directly; otherwise request that the associated ManifestItem
     * record be marked for deletion.
     *
     * @param {Selector} target
     * @param {boolean}  [intermediate]     If more row changes coming.
     */
    function deleteRow(target, intermediate) {
        const func = 'deleteRow'; _debug(`${func}: target =`, target);
        const $row = dataRow(target);

        // Avoid removing the final row of the grid.
        if (allDataRows().length <= 1) {
            _debug(`${func}: cannot delete the final row`);
            if ($row.is(TO_DELETE)) {
                _debug(`${func}: un-marking for deletion -`, $row);
                $row.removeClass(TO_DELETE_MARKER);
            }
            return;
        }

        // Mark row for deletion then update the grid and/or database.
        markRow($row);
        const db_id = manifestItemId($row);
        if (db_id) {
            sendDeleteRecords(db_id, intermediate);
        } else {
            _debug(`${func}: removing blank row -`, $row);
            removeGridRow($row, intermediate);
        }
    }

    /**
     * Mark the indicated rows for deletion.
     *
     * If all are blank rows (not yet associated with ManifestItems) then they
     * are removed directly; otherwise request that the associated ManifestItem
     * records be marked for deletion.
     *
     * @param {number|ManifestItem|jQuery|HTMLElement|array} list
     * @param {boolean} [preserve_last]     Default: *true*.
     * @param {boolean} [intermediate]      If more row changes coming.
     */
    function deleteRows(list, preserve_last, intermediate) {
        const func   = 'deleteRows'; _debug(`${func}: list =`, list);
        const $rows  = allDataRows();
        const blanks = [];
        const db_ids =
            arrayWrap(list).map(item => {
                let $row;
                if (item instanceof jQuery) {
                    $row = item;
                } else if (item instanceof HTMLElement) {
                    $row = $(item);
                } else if (isDefined(item?.id)) {
                    return item.id;
                } else {
                    return item;
                }
                const db_id = manifestItemId($row);
                if (!db_id) {
                    blanks.push($row);
                }
                return db_id;
            }).filter(v => v);

        // Mark rows for deletion.
        blanks.forEach($row => markRow($row));
        db_ids.forEach(db_id => {
            const $row = rowForManifestItem(db_id, $rows);
            if ($row) {
                markRow($row);
            } else {
                _debug(`${func}: no row for db_id ${db_id}`);
            }
        });

        // Avoid deleting all rows of the grid unless directed.
        let b_size = blanks.length;
        let d_size = db_ids.length;
        if ((preserve_last !== false) && ((b_size + d_size) >= $rows.length)) {
            let $row;
            if (d_size && !b_size) {
                $row   = db_ids.shift();
                d_size = db_ids.length;
            } else {
                $row   = blanks.shift();
                b_size = blanks.length;
            }
            _debug(`${func}: cannot delete the final row`);
            _debug(`${func}: un-marking for deletion -`, $row);
            $row?.removeClass(TO_DELETE_MARKER);
        }

        if (b_size) {
            _debug(`${func}: removing blank rows -`, blanks);
            removeGridRows($(blanks), intermediate);
        }
        if (d_size) {
            sendDeleteRecords(db_ids, intermediate);
        }
        if (!b_size && !d_size) {
            _debug(`${func}: nothing to do`);
        }
    }

    /**
     * Cause the server to delete the indicated ManifestItem records.
     *
     * @param {number|number[]} items
     * @param {boolean}         [intermediate]  If more row changes coming.
     */
    function sendDeleteRecords(items, intermediate) {
        const func     = 'sendDeleteRecords';
        const manifest = manifestId();
        const action   = `bulk/destroy/${manifest}`;
        const content  = 'multipart/form-data';
        const accept   = 'application/json';
        const id_list  = arrayWrap(items);
        _debug(`${func}: items =`, items);

        if (!manifest) {
            _error(`${func}: no manifest ID`);
            return;
        }

        serverItemSend(action, {
            caller:     func,
            method:     'DELETE',
            params:     { ids: id_list },
            headers:    { 'Content-Type': content, Accept: accept },
            onSuccess:  processDeleteResponse,
        });

        /**
         * Remove the data rows associated with the deleted ManifestItems.
         *
         * @param {ManifestItemIdMessage} body
         *
         * @see "ManifestItemController#bulk_id_response"
         * @see "SerializationConcern#index_values"
         */
        function processDeleteResponse(body) {
            _debug(`${func}: body =`, body);
            const data = body?.items || body || {};
            const list = data.list || [];
            if (isEmpty(data)) {
                _error(func, 'no response data');
            } else if (isEmpty(list)) {
                _error(func, 'no items present in response data');
            } else {
                removeDeletedRows(list, intermediate);
            }
        }
    }

    /**
     * Respond to deletion of ManifestItems by removing their associated rows.
     *
     * @param {(ManifestItem|number)[]} list
     * @param {boolean}                 [intermediate]
     */
    function removeDeletedRows(list, intermediate) {
        const func    = 'removeDeletedRows'; _debug(`${func}: list =`, list);
        const $rows   = allDataRows();
        const $marked = $rows.filter(TO_DELETE);
        const marked  = compact($marked.toArray().map(e => manifestItemId(e)));
        const db_ids  = arrayWrap(list).map(r => isDefined(r?.id) ? r.id : r);

        // Mark rows for deletion if not already marked.
        db_ids.forEach(db_id => {
            const $row = rowForManifestItem(db_id, $rows);
            if (!$row) {
                _debug(`${func}: no row for db_id ${db_id}`);
            } else if (!$row.is(TO_DELETE)) {
                _debug(`${func}: ${db_id}: not already marked ${TO_DELETE}`);
                $row.addClass(TO_DELETE_MARKER);
                marked.push(db_id);
            }
        });

        // Look for rows that had been marked but were not reported as deleted.
        // These have to be unmarked because (for whatever reason) they weren't
        // actually removed so the row should remain to reflect that.
        const undeleted = marked.filter(id => !db_ids.includes(id));
        if (isPresent(undeleted)) {
            undeleted.forEach(db_id => {
                const $row = rowForManifestItem(db_id, $rows);
                $row?.removeClass(TO_DELETE_MARKER);
            });
            console.warn(`${func}: not deleted:`, undeleted);
        }

        // It is assumed that any blank rows have already been marked (or have
        // already been removed).
        removeGridRows($rows.filter(TO_DELETE), intermediate);
    }

    /**
     * Delete the indicated grid rows.
     *
     * @param {Selector} rows
     * @param {boolean}  [intermediate]     If more row changes coming.
     */
    function removeGridRows(rows, intermediate) {
        _debug('removeGridRows: rows =', rows);
        const $rows = dataRows(rows);
        destroyGridRowElements($rows, intermediate);
    }

    /**
     * Remove the indicated single grid data row.
     *
     * @param {Selector} target
     * @param {boolean}  [intermediate]     If more row changes coming.
     */
    function removeGridRow(target, intermediate) {
        _debug('removeGridRow: item =', target);
        const $row = dataRow(target);
        destroyGridRowElements($row, intermediate);
    }

    /**
     * Remove row element(s) from the grid.
     *
     * The elements are hidden first in order to allow the re-render to happen
     * all at once.
     *
     * @param {jQuery}  $rows
     * @param {boolean} [intermediate]      If more row changes coming.
     */
    function destroyGridRowElements($rows, intermediate) {
        //_debug('destroyGridRowElements: $rows =', $rows);
        const row_count = $rows.length;
        toggleHidden($rows, true);
        $rows.each((_, row) => removeFromControlsColumnToggle(row));
        $rows.remove();
        if (!intermediate) {
            updateGridRowCount(-row_count);
        }
    }

    /**
     * The delete button for the given row.
     *
     * @param {Selector} row
     *
     * @returns {jQuery}
     */
    function deleteButton(row) {
        return rowButton(row, 'delete');
    }

    /**
     * Enable the delete button for the given row.
     *
     * @param {Selector} row
     * @param {boolean}  [enable]     If *false* run {@link disableDelete}.
     * @param {boolean}  [forbid]     If *true* add '.forbidden' if disabled.
     *
     * @returns {jQuery}              The submit button.
     */
    function enableDelete(row, enable, forbid) {
        return enableRowButton(row, 'delete', enable, forbid);
    }

    /**
     * Disable operation button for the given row.
     *
     * @param {Selector} row
     * @param {boolean}  [forbid]     If *true* add '.forbidden'.
     *
     * @returns {jQuery}              The submit button.
     */
    function disableDelete(row, forbid) {
        return enableDelete(row, false, forbid);
    }

    /**
     * If there is only one grid row, disable
     */
    function updateDeleteButtons() {
        _debug('updateDeleteButtons');
        const $rows = allDataRows();
        if ($rows.length > 1) {
            $rows.each((_, row) => enableDelete(row));
        } else if ($rows.length === 1) {
            disableDelete($rows.first(), true);
        }
    }

    // ========================================================================
    // Functions - row - bibliographic lookup
    // ========================================================================

    /**
     * Name of the data() entry for a row's lookup instance.
     *
     * @type {string}
     */
    const LOOKUP_DATA = 'lookup';

    /**
     * Invoke bibliographic lookup for the row associated with the target.
     *
     * @note This is here for consistency however it doesn't actually do
     *  anything -- activation of the feature is performed by the LookupModal
     *  instance initialized in {@link setupLookup}.
     *
     * @param {Selector} target
     */
    function lookupRow(target) {
        _debug('lookupRow: target =', target);
    }

    /**
     * The lookup button for the given row.
     *
     * @param {Selector} row
     *
     * @returns {jQuery}
     */
    function lookupButton(row) {
        return rowButton(row, 'lookup');
    }

    /**
     * Initialize bibliographic lookup for a data row.
     *
     * @param {Selector} row
     */
    function setupLookup(row) {
        _debug('setupLookup: row =', row);

        const $row    = dataRow(row);
        const $button = lookupButton($row);

        clearSearchResultsData($row);
        clearSearchTermsData($row);
        updateLookupCondition($row);

        LookupModal.setupFor($button, onLookupStart, onLookupComplete);
        handleClickAndKeypress($button, function() { clearFlash() });

        /**
         * Invoked to update search terms when the popup opens.
         *
         * @param {jQuery}  $activator
         * @param {boolean} check_only
         * @param {boolean} [halted]
         *
         * @returns {boolean|undefined}
         *
         * @see onShowModalHook
         */
        function onLookupStart($activator, check_only, halted) {
            _debug('LOOKUP START | $activator =', $activator);
            if (check_only || halted) { return }
            clearSearchResultsData($row);
            setSearchTermsData($row);
            setOriginalValues($row);
        }

        /**
         * Invoked to update form fields when the popup closes.
         *
         * @param {jQuery}  $activator
         * @param {boolean} check_only
         * @param {boolean} [halted]
         *
         * @returns {boolean|undefined}
         *
         * @see onHideModalHook
         */
        function onLookupComplete($activator, check_only, halted) {
            _debug('LOOKUP COMPLETE | $activator =', $activator);
            if (check_only || halted) { return }
            const func  = 'onLookupComplete';
            let message = 'No fields changed.'; // TODO: I18n
            const data  = getFieldResultsData($row);

            if (isPresent(data)) {
                const $cells  = dataCells($row);
                const updates = { Added: [], Changed: [], Removed: [] };
                $.each(data, (field, value) => {
                    const $field = dataField($cells, field, func);
                    if (isMissing($field)) {
                        // No addition to updates.
                    } else if (!value) {
                        updates.Removed.push(field);
                    } else if (cellCurrentValue($field)?.nonBlank) {
                        updates.Changed.push(field);
                    } else {
                        updates.Added.push(field);
                    }
                });
                message = $.map(compact(updates), (fields, update_type) => {
                    const s     = (fields.length === 1) ? '' : 's';
                    const label = `${update_type} item${s}`; // TODO: I18n
                    const names = dataFields($cells, fields)
                        .toArray()
                        .map(c => $(c).find('.label .text').text())
                        .sort()
                        .join(', ');
                    const type  = `<span class="type">${label}:</span>`;
                    const list  = `<span class="list">${names}.</span>`;
                    return `${type} ${list}`;
                }).join("\n");

                // NOTE: This is a hack due to the way that publication date is
                //  handled versus copyright year.
/*
            if (Object.keys(data).includes('emma_publicationDate')) {
                const $input = formField('emma_publicationDate', $row);
                const $label = $input.siblings(`[for="${$input.attr('id')}"]`);
                $input.attr('title', $label.attr('title'));
                $input.prop({ readonly: false, disabled: false });
                [$input, $label].forEach($e => {
                    $e.css('display','revert').toggleClass('disabled', false)
                });
            }
*/

                // Update the ManifestItem with the updated data.
                // noinspection JSCheckFunctionSignatures
                postRowUpdate($row, data);
            }

            flashMessage(message);
        }
    }

    /**
     * Enable bibliographic lookup.
     *
     * @param {Selector} row
     * @param {boolean}  [enable]     If *false* run {@link disableLookup}.
     * @param {boolean}  [forbid]     If *true* add '.forbidden' if disabled.
     *
     * @returns {jQuery}              The submit button.
     */
    function enableLookup(row, enable, forbid) {
        return enableRowButton(row, 'lookup', enable, forbid);
    }

    /**
     * Disable bibliographic lookup.
     *
     * @param {Selector} row
     * @param {boolean}  [forbid]     If *true* add '.forbidden'.
     *
     * @returns {jQuery}              The submit button.
     */
    function disableLookup(row, forbid) {
        return enableLookup(row, false, forbid);
    }

    // ========================================================================
    // Functions - bibliographic lookup - conditions
    // ========================================================================

    const LOOKUP_CONDITION_DATA = LookupRequest.LOOKUP_CONDITION_DATA;

    /**
     * Get the field value(s) for bibliographic lookup.
     *
     * @param {Selector} row
     *
     * @returns {LookupCondition}
     */
    function getLookupCondition(row) {
        const condition = lookupButton(row).data(LOOKUP_CONDITION_DATA);
        return condition || setLookupCondition(row);
    }

    /**
     * Set the field value(s) for bibliographic lookup.
     *
     * @param {Selector}        row
     * @param {LookupCondition} [value] Def.: {@link evaluateLookupCondition}
     *
     * @returns {LookupCondition}
     */
    function setLookupCondition(row, value) {
        _debug('setLookupCondition: row =', row);
        const condition = value || evaluateLookupCondition(row);
        lookupButton(row).data(LOOKUP_CONDITION_DATA, condition);
        return condition;
    }

    /**
     * Set the field value(s) for bibliographic lookup to the initial state.
     *
     * @param {Selector} row
     *
     * @returns {LookupCondition}
     */
    function clearLookupCondition(row) {
        _debug('clearLookupCondition: row =', row);
        return setLookupCondition(row, LookupRequest.blankLookupCondition());
    }

    /**
     * Update the internal condition values for the Lookup button based on the
     * state of form values, and change the button's enabled/disabled state if
     * appropriate.
     *
     * @param {Selector} row
     * @param {boolean}  [permit]
     */
    function updateLookupCondition(row, permit) {
        _debug('updateLookupCondition: row =', row);
        const $row    = dataRow(row);
        const $button = lookupButton($row);
        let allow, enable = false;
        if (isDefined(permit)) {
            allow = permit;
        } else {
            allow = defaultRepository(repositoryFor($row));
        }
        if (allow) {
            const condition = evaluateLookupCondition($row);
            enable ||= Object.values(condition.or).some(v => v);
            enable ||= Object.values(condition.and).every(v => v);
        }
        if (enable) {
            clearSearchTermsData($button);
        }
        enableLookup($button, enable, !allow);
    }

    /**
     * Determine the readiness of a row for bibliographic lookup.
     *
     * @param {Selector} row
     *
     * @returns {LookupCondition}
     */
    function evaluateLookupCondition(row) {
        const func      = 'evaluateLookupCondition';
        _debug(`${func}: row =`, row);
        const $row      = dataRow(row);
        const $cells    = dataCells($row);
        _debug(`${func}: $cells =`, $cells);
        const condition = LookupRequest.blankLookupCondition();
        $.each(condition, (logical_op, entry) => {
            $.each(entry, (field, _) => {
                const $field = dataField($cells, field, func);
                const valid  = isPresent($field) && cellValid($field);
                const value  = valid && cellCurrentValue($field);
                condition[logical_op][field] = value && value.nonBlank;
            });
        });
        return condition;
    }

    // ========================================================================
    // Functions - bibliographic lookup - original field values
    // ========================================================================

    /**
     * Set the original field values.
     *
     * @param {Selector} row
     * @param {EmmaData} [data]
     */
    function setOriginalValues(row, data) {
        const func = 'setOriginalValues'; _debug(`${func}: row =`, row);
        const $row = dataRow(row);
        let values;
        if (data) {
            values = deepDup(data);
        } else {
            const $cells = dataCells($row);
            values = toObject(LookupModal.DATA_COLUMNS, field => {
                const $field = dataField($cells, field, func);
                return $field && cellCurrentValue($field)?.value;
            });
        }
        lookupButton($row).data(LookupModal.ENTRY_ITEM_DATA, values);
    }

    // ========================================================================
    // Functions - bibliographic lookup - search terms
    // ========================================================================

    /**
     * Get the search terms to be provided for lookup.
     *
     * @param {Selector} row
     *
     * @returns {LookupRequest|undefined}
     */
    function getSearchTermsData(row) {
        return lookupButton(row).data(LookupModal.SEARCH_TERMS_DATA);
    }

    /**
     * Update the search terms to be provided for lookup.
     *
     * @param {Selector}                      row
     * @param {LookupRequest|LookupCondition} [value]
     *
     * @returns {LookupRequest}     The data object assigned to the button.
     */
    function setSearchTermsData(row, value) {
        _debug('setSearchTermsData:', row, (value || '-'));
        let request;
        if (value instanceof LookupRequest) {
            request = value;
        } else {
            request = generateLookupRequest(row, value);
        }
        lookupButton(row).data(LookupModal.SEARCH_TERMS_DATA, request);
        return request;
    }

    /**
     * Clear the search terms to be provided for lookup.
     *
     * @param {Selector} row
     *
     * @returns {jQuery}
     */
    function clearSearchTermsData(row) {
        _debug('clearSearchTermsData: row =', row);
        return lookupButton(row).removeData(LookupModal.SEARCH_TERMS_DATA);
    }

    // noinspection JSUnusedLocalSymbols
    /**
     * Update data on the Lookup button if required.
     *
     * To avoid excessive work, {@link setSearchTermsData} will only be run
     * if truly required to regenerate the data.
     *
     * @param {jQuery.Event|Event} event
     */
    function updateSearchTermsData(event) {
        _debug('updateSearchTermsData: event =', event);
        const $button = $(event.currentTarget || event.target);
        if ($button.prop('disabled')) { return }
        if (isPresent(getSearchTermsData($button))) { return }
        clearSearchResultsData($button);
        setSearchTermsData($button);
    }

    /**
     * Create a LookupRequest instance.
     *
     * @param {Selector}        row
     * @param {LookupCondition} [value]     Def: {@link getLookupCondition}
     *
     * @returns {LookupRequest}
     */
    function generateLookupRequest(row, value) {
        const func      = 'generateLookupRequest'; _debug(func, row, value);
        const request   = new LookupRequest();
        const $row      = dataRow(row);
        const $cells    = dataCells($row);
        const condition = value || getLookupCondition(row);
        $.each(condition, function(_logical_op, entry) {
            $.each(entry, function(field, active) {
                if (active) {
                    const $field = dataField($cells, field, func);
                    const values = $field && cellCurrentValue($field)?.value;
                    if (isPresent(values)) {
                        const prefix = LookupRequest.LOOKUP_PREFIX[field];
                        if (prefix === '') {
                            request.add(values);
                        } else {
                            request.add(values, (prefix || 'keyword'));
                        }
                    }
                }
            });
        });
        return request;
    }

    // ========================================================================
    // Functions - bibliographic lookup - search results
    // ========================================================================

    /**
     * Clear the search terms from the button.
     *
     * @param {Selector} row
     *
     * @returns {jQuery}
     */
    function clearSearchResultsData(row) {
        _debug('clearSearchResultsData: row =', row);
        return lookupButton(row).removeData(LookupModal.SEARCH_RESULT_DATA);
    }

    // ========================================================================
    // Functions - bibliographic lookup - user-selected values
    // ========================================================================

    /**
     * Get the user-selected field values from lookup.
     *
     * @param {Selector} row
     *
     * @returns {LookupResponseItem|undefined}
     */
    function getFieldResultsData(row) {
        return lookupButton(row).data(LookupModal.FIELD_RESULTS_DATA);
    }

    // ========================================================================
    // Functions - bibliographic lookup - database update
    // ========================================================================

    /**
     * Inform the server of updated values for a row associated with a
     * ManifestItem record.
     *
     * @param {Selector} changed_row
     * @param {EmmaData} new_values
     *
     * @see "ManifestItemController#start_edit"
     */
    function postRowUpdate(changed_row, new_values) {
        const func = 'postRowUpdate';
        if (isEmpty(new_values)) {
            _error(`${func}: no data field changes`);
            return;
        }
        const $row   = dataRow(changed_row);
        const db_id  = manifestItemId($row);
        const action = `row_update/${db_id}`;
        const row    = dbRowValue($row);
        const delta  = dbRowDelta($row);
        const data   = { row: row, delta: delta, ...new_values };
        serverItemSend(action, {
            caller:     func,
            params:     { manifest_item: data },
            onSuccess:  (body => parseUpdateResponse($row, body)),
        });
    }

    /**
     * Receive updated fields for the item, plus problem reports, plus invalid
     * fields for each item that would prevent a save from occurring.
     *
     * @param {Selector}                                  row
     * @param {UpdateResponse|{response: UpdateResponse}} body
     *
     * @see "ManifestItemConcern#finish_editing"
     * @see "Manifest::ItemMethods#pending_items_hash"
     * @see "ActiveModel::Errors"
     */
    function parseUpdateResponse(row, body) {
        _debug('parseUpdateResponse: body =', body);
        /** @type {UpdateResponse} */
        const data     = body?.response || body || {};
        const items    = presence(data.items);
        const pending  = presence(data.pending);
        const problems = presence(data.problems);

        // Update fields(s) echoed back from the server.  This may also include
        // 'file_status' and/or 'data_status'
        // @see "ManifestItemConcern#finish_editing"
        const $row   = dataRow(row);
        const db_id  = manifestItemId($row);
        const record = items && items[db_id];
        if (isPresent(record)) {
            updateDataRow($row, record);
            if (pending && isPresent(statusData(record))) {
                delete pending[db_id];
            }
        }

        // Update status indicators
        // @see "Manifest::ItemMethods#pending_items_hash"
        if (pending) {
            const $rows = allDataRows();
            $.each(pending, (id, item) => {
                const $row = isPresent(item) && rowForManifestItem(id, $rows);
                if ($row) { updateRowIndicators($row, item) }
            });
        }

        // Error message(s) to display.
        // @see "ActiveModel::Errors"
        if (problems) {
            let count = 0;
            $.each(problems, (type, lines) => {
                const message =
                    (!Array.isArray(lines) && `${type}: ${lines}`)    ||
                    ((lines.length === 1)  && `${type}: ${lines[0]}`) ||
                    (                         [type, ...lines])
                if (count++) {
                    addFlashError(message);
                } else {
                    flashError(message);
                }
            });
        }
    }

    // ========================================================================
    // Functions - bibliographic lookup - other
    // ========================================================================

    /**
     * The repository selected for the given row.
     *
     * @param {Selector} row
     *
     * @returns {string|undefined}
     */
    function repositoryFor(row) {
        const func  = 'repositoryFor';
        const field = ['repository', 'emma_repository'];
        const $cell = dataField(row, field, func);
        return $cell && cellCurrentValue($cell)?.value;
    }

    /**
     * Indicate whether the given repository is the default (local) repository
     * or an (external) member repository.
     *
     * @param {string} [repo]
     *
     * @returns {boolean}
     */
    function defaultRepository(repo) {
        return !repo || (repo === PAGE_PROPERTIES.Repo.default);
    }

    // ========================================================================
    // Functions - row - uploader
    // ========================================================================

    /**
     * @typedef { ManifestItemData | {error: string} } ManifestItemDataOrError
     */

    /**
     * Name of the data() entry for a row's uploader instance.
     *
     * @type {string}
     */
    const UPLOADER_DATA = 'uploader';

    /**
     * Get the uploader instance for the row.
     *
     * @param {Selector} row
     *
     * @returns {MultiUploader|undefined}
     */
    function getUploader(row) {
        return dataRow(row).data(UPLOADER_DATA);
    }

    /**
     * Set (or clear) the uploader instance for the row.
     *
     * @param {Selector}                row
     * @param {MultiUploader|undefined} uploader
     */
    function setUploader(row, uploader) {
        //_debug('setUploader: row =', row);
        const $row = dataRow(row);
        if (uploader) {
            $row.data(UPLOADER_DATA, uploader);
        } else {
            $row.removeData(UPLOADER_DATA);
        }
    }

    /**
     * Create a new uploader instance.
     *
     * @param {Selector} row
     *
     * @returns {MultiUploader}
     */
    function newUploader(row) {
        //_debug('newUploader: row =', row);
        // noinspection JSUnusedGlobalSymbols
        const cbs      = { onSelect, onStart, onError, onSuccess };
        const $row     = dataRow(row);
        const features = { debugging: DEBUG };
        const instance = new MultiUploader($row, ITEM_MODEL, features, cbs);
        const exists   = instance.isUppyInitialized();
        const func     = 'uploader';
        let name_shown;

        // Clear display elements of an existing uploader.
        if (exists) {
            instance.$root.find(MultiUploader.FILE_SELECT).remove();
            instance.$root.find(MultiUploader.DISPLAY).empty();
        }

        // Ensure that the uploader is fully initialized and set up handlers
        // for added input controls.
        instance.initialize({ added: initializeAddedControls });

        return instance;

        /**
         * Callback invoked when the file select button is pressed.
         *
         * @param {jQuery.Event} [event]    Ignored.
         */
        function onSelect(event) {
            _debug(`${func}: onSelect: event =`, event);
            clearFlash();
            if (!manifestId()) {
                createManifest();
            }
        }

        /**
         * This event occurs between the 'file-added' and 'upload-started'
         * events.
         *
         * The current value of the submission's database ID applied to the
         * upload endpoint URL in order to correlate the upload with the
         * appropriate workflow.
         *
         * @param {UppyFileUploadStartData} data
         *
         * @returns {object}          URL parameters for the remote endpoint.
         */
        function onStart(data) {
            _debug(`${func}: onStart: data =`, data);
            clearFlash();
            name_shown = instance.isFilenameDisplayed();
            instance.hideFilename(); // Make room for .uploader-feedback
            return compact({
                id:          manifestItemId($row),
                row:         dbRowValue($row),
                delta:       dbRowDelta($row),
                manifest_id: manifestId(),
            });
        }

        /**
         * This event occurs when the response from POST /manifest_item/upload
         * is received with a failure status (4xx).
         *
         * @param {UppyFile}                       file
         * @param {Error}                          error
         * @param {{status: number, body: string}} [response]
         */
        function onError(file, error, response) {
            _debug(`${func}: onError: file =`, file);
            flashError(error?.message || error);
            if (name_shown) { instance.hideFilename(false) }
        }

        /**
         * This event occurs when the response from POST /manifest_item/upload
         * is received with success status (200).  At this point, the file has
         * been uploaded by Shrine, but has not yet been validated.
         *
         * **Implementation Notes**
         * The normal Shrine response has been augmented to include an
         * 'emma_data' object in addition to the fields associated with
         * 'file_data'.
         *
         * @param {UppyFile}            file
         * @param {UppyResponseMessage} response
         *
         * @see "Shrine::UploadEndpointExt#make_response"
         */
        function onSuccess(file, response) {
            _debug(`${func}: onSuccess: file =`, file);

            const body = response.body  || {};
            let error  = undefined;

            // Extract uploaded EMMA metadata.
            // noinspection JSValidateTypes
            /** @type {ManifestItemDataOrError} */
            const emma_data = { ...body.emma_data };
            error ||= emma_data.error;
            delete emma_data.error;
            delete body.emma_data;

            // Set hidden field value to the uploaded file data so that it is
            // submitted with the form as the attachment.
            /** @type {FileData} */
            const file_data = body.file_data || body;
            error ||= file_data?.error || body.error;
            if (file_data) {
                if (!emma_data.dc_format) {
                    const mime = file_data.metadata?.mime_type;
                    const fmt  = PAGE_PROPERTIES.Mime.to_fmt[mime] || [];
                    if (fmt[0]) { emma_data.dc_format = fmt[0] }
                }
                emma_data.file_data = file_data;
            }

            // Save uploaded EMMA metadata (including received file data).
            if (isPresent(emma_data)) {
                // noinspection JSCheckFunctionSignatures
                updateDataRow($row, emma_data);
            }

            if (error) {
                flashError(error);
                if (name_shown) { instance.hideFilename(false) }
            } else {
                instance.displayUploadedFilename(file_data);
            }
        }

        /**
         * Setup handlers for added input controls.
         *
         * @param {Selector} container
         *
         * @see "ManifestItemDecorator#render_grid_file_input"
         */
        function initializeAddedControls(container) {
            _debug(`${func}: initializeAddedControls: container =`, container);
            const HOVER_ATTR = 'data-hover';

            /** @type {jQuery} */
            const $cell  = $row.find(MultiUploader.UPLOADER),
                  $name  = $cell.find(MultiUploader.FILE_NAME),
                  $lines = $name.children();
            $(container).each((_, element) => {
                const popup   = new InlinePopup(element);
                const $toggle = popup.modalControl;
                const $panel  = popup.modalPanel;
                const $input  = $panel.find('input');
                const $submit = $panel.find('button.input-submit');
                const $cancel = $panel.find('button.input-cancel');

                handleEvent($input, 'keyup',    onInput);
                handleClickAndKeypress($submit, onSubmit);
                handleClickAndKeypress($cancel, onCancel);

                handleHoverAndFocus($toggle, hoverToggle, unhoverToggle);
                ModalShowHooks.set($toggle, onShow);
                ModalHideHooks.set($toggle, onHide);

                const $element  = $(element);
                const type      = $element.attr('data-type');
                const from_type = `.from-${type}`;
                const $type     = $lines.filter(from_type);

                /**
                 * Make the "Enter" key a proxy for onSubmit.
                 *
                 * @param {jQuery.Event|KeyboardEvent} event
                 *
                 * @returns {boolean|undefined}
                 */
                function onInput(event) {
                    //_debug('onInput: event =', event);
                    const key = event.key;
                    if (key === 'Enter') {
                        event.stopImmediatePropagation();
                        $submit.click();
                        return false;
                    }
                }

                /**
                 * If a value was given update the displayed file value and
                 * send the new :file_data value to the server.
                 *
                 * @param {Event} event
                 */
                function onSubmit(event) {
                    _debug('onSubmit: event =', event);
                    let show_name = false;
                    const value = $input.val()?.trim();
                    if (value) {
                        setUploaderDisplayValue($cell, value, type);
                        const file_data = { [type]: value };
                        atomicEdit($cell, file_data);
                    }
                    $name.toggleClass('complete', show_name);
                    popup.close();
                }

                /**
                 * Just close the modal.
                 *
                 * @param {Event} event
                 */
                function onCancel(event) {
                    _debug('onCancel: event =', event);
                    popup.close();
                }

                /**
                 * Add an attribute to the cell element indicating the button
                 * being hovered, allowing for CSS rules relative to the cell.
                 *
                 * @param {Event} event
                 */
                function hoverToggle(event) {
                    //_debug('hoverToggle: event =', event);
                    $cell.attr(HOVER_ATTR, type);
                }

                /**
                 * Remove the attribute unless it has been changed by something
                 * else.
                 *
                 * @param {Event} event
                 */
                function unhoverToggle(event) {
                    //_debug('unhoverToggle: event =', event);
                    if ($cell.attr(HOVER_ATTR) === type) {
                        $cell.removeAttr(HOVER_ATTR);
                    }
                }

                /**
                 * Initialize the input with the current value if there is one.
                 *
                 * @param {jQuery}  $target
                 * @param {boolean} [check_only]
                 * @param {boolean} [halted]
                 */
                function onShow($target, check_only, halted) {
                    _debug('onShow:', $target, check_only, halted);
                    if (check_only || halted) { return }
                    const value = $type.text()?.trim();
                    if (value) {
                        $input.val(value);
                    }
                    debounce(adjustGridHeight, 50)();
                }

                /**
                 * Restore grid height if {@link onShow} was forced to grow the
                 * grid in order to display the whole popup.
                 *
                 * @param {jQuery}  $target
                 * @param {boolean} [check_only]
                 * @param {boolean} [halted]
                 */
                function onHide($target, check_only, halted) {
                    _debug('onHide:', $target, check_only, halted);
                    if (check_only || halted) { return }
                    restoreGridHeight();
                }

                let grid_resize, grid_height;

                /**
                 * If the popup cannot be fully displayed at its current
                 * position because it is clipped by the bottom of the grid,
                 * temporarily grow the grid vertically to make room for it.
                 */
                function adjustGridHeight() {
                    const panel_box = $panel[0].getBoundingClientRect();
                    const grid_box  = $grid[0].getBoundingClientRect();
                    const obscured  = panel_box.bottom - grid_box.bottom;
                    if (obscured > 0) {
                        grid_height = $grid.prop('style').height;
                        grid_resize = true;
                        const old_ht    = grid_box.height;
                        const scrollbar = old_ht - $grid[0].clientHeight;
                        $grid.css('height', (old_ht + obscured + scrollbar));
                    }
                }

                /**
                 * If the grid was temporarily resized, restore the element by
                 * removing the fixed height value set above.
                 */
                function restoreGridHeight() {
                    if (grid_resize) {
                        $grid.prop('style').height = grid_height;
                        grid_resize = grid_height = undefined;
                    }
                }
            });

            const $upload = instance.fileSelectButton();
            const type    = 'uploader';
            handleHoverAndFocus($upload, hoverUpload, unhoverUpload);

            /**
             * Add an attribute to the cell element indicating the button
             * being hovered, allowing for CSS rules relative to the cell.
             *
             * @param {Event} event
             */
            function hoverUpload(event) {
                //_debug('hoverUpload: event =', event);
                $cell.attr(HOVER_ATTR, type);
            }

            /**
             * Remove the attribute unless it has been changed by something
             * else.
             *
             * @param {Event} event
             */
            function unhoverUpload(event) {
                //_debug('unhoverUpload: event =', event);
                if ($cell.attr(HOVER_ATTR) === type) {
                    $cell.removeAttr(HOVER_ATTR);
                }
            }
        }
    }

    /**
     * Create a new uploader instance if not already present for the row.
     *
     * @param {Selector} row
     */
    function initializeUploader(row) {
        //_debug('initializeUploader: row =', row);
        const $row = dataRow(row);
        if (!getUploader($row)) {
            setUploader($row, newUploader($row));
        }
    }

    /**
     * Initialize uploading for each grid row.
     *
     * @param {Selector} [target]
     */
    function setupUploader(target) {
        _debug('setupUploader: target =', target);
        dataRows(target).each((_, row) => initializeUploader(row));
    }

    // ========================================================================
    // Functions - row - grid row index
    // ========================================================================

    /**
     * Name of the row attribute specifying the relative position of the row
     * within a "virtual grid" which spans pagination.
     *
     * Header row(s) always have the same index value (starting with 1)
     * regardless of the page; data rows have index values within a range that
     * increases with the page number.
     *
     * @type {string}
     */
    const GRID_ROW_INDEX_ATTR = 'aria-rowindex';

    /**
     * The start of CSS class names related to the ordering of grid-spanning
     * elements within the grid container.  The range of values is the same
     * regardless of the page.
     *
     * @type {string}
     */
    const ROW_CLASS_PREFIX = 'row-';

    /**
     * Get the grid row index associated with the target.
     *
     * @param {Selector} target
     *
     * @returns {number|undefined}
     */
    function gridRowIndex(target) {
        const index = attribute(target, GRID_ROW_INDEX_ATTR);
        return Number(index) || undefined;
    }

    /**
     * The number portion of the CSS 'row-N' class.
     *
     * @param {Selector} target
     * @param {string}   [prefix]
     *
     * @returns {number|undefined}
     */
    function gridRowClassNumber(target, prefix = ROW_CLASS_PREFIX) {
        const css_class = getClass(target, prefix);
        return css_class && Number(css_class.replace(prefix, '')) || undefined;
    }

    /**
     * Renumber grid row indexes and rewrite delta values so that ordering
     * database records on [row, delta] will yield the same order as what
     * appears on the screen.
     *
     * This mitigates the case where a row is inserted within a range of
     * inserted rows (rather than at the end of the range where it's highest
     * delta number would appropriately reflect its ordinal position).
     */
    function updateGridRowIndexes() {
        _debug('updateGridRowIndexes');
        const $rows   = allDataRows();
        const first_c = `${ROW_CLASS_PREFIX}first`; // E.g. 'row-first'
        const last_c  = `${ROW_CLASS_PREFIX}last`;  // E.g. 'row-last'
        const start_i = gridRowIndex($rows.first());
        const start_c = gridRowClassNumber($rows.first());
        let row_index = start_i || gridRowIndex(headerRow())       || 1;
        let row_class = start_c || gridRowClassNumber(headerRow()) || 1;
        let last_row_value, last_row_delta;

        $rows.each((_, row) => {
            const $row = $(row);
            $row.removeClass([first_c, last_c]);
            replaceClass($row, 'row-', row_class++);
            $row.attr(GRID_ROW_INDEX_ATTR, row_index++);

            if (dbRowDelta($row)) {
                const db_row = dbRowValue($row);
                if (db_row !== last_row_value) {
                    last_row_value = db_row;
                    last_row_delta = 0;
                }
                setDbRowDelta($row, ++last_row_delta);
            }
        });
        $rows.first().addClass(first_c);
        $rows.last().addClass(last_c);
    }

    /**
     * updateGridRowCount
     *
     * @param {number} by
     */
    function updateGridRowCount(by) {
        const func = 'updateGridRowCount'; _debug(`${func}: by`, by);
        changeItemCount(by);
        updateDeleteButtons();
        updateGridRowIndexes();
    }

    // ========================================================================
    // Functions - row - database row/delta
    // ========================================================================

    const DB_ROW_ATTR   = 'data-item-row';
    const DB_DELTA_ATTR = 'data-item-delta';

    const DB_ROW_DATA   = 'itemRow';
    const DB_DELTA_DATA = 'itemDelta';

    /**
     * ManifestItem 'row' column value for the row.
     *
     * Inserted rows will have the same value for this as the template row from
     * which they were created.
     *
     * @param {Selector} target
     *
     * @returns {number}
     */
    function dbRowValue(target) {
        const $row  = dataRow(target, true);
        const value = $row.data(DB_ROW_DATA);
        return value || 0;
    }

    /**
     * Set the ManifestItem 'row' column value for the row.
     *
     * @param {Selector}                target
     * @param {string|number|undefined} setting
     *
     * @returns {number}
     */
    function setDbRowValue(target, setting) {
        //_debug(`setDbRowValue: setting = "${setting}"; target =`, target);
        const $row   = dataRow(target, true);
        const number = Number(setting);
        const value  = number || 0;
        if (number) { $row.removeAttr(DB_ROW_ATTR) }
        $row.data(DB_ROW_DATA, value);
        return value;
    }

    /**
     * ManifestItem 'row' column value for the row.
     *
     * Inserted rows will have the same value for this as the template row from
     * which they were created.
     *
     * @param {Selector} target
     *
     * @returns {number}
     */
    function initializeDbRowValue(target) {
        const $row = dataRow(target, true);
        const attr = $row.attr(DB_ROW_ATTR);
        return attr ? setDbRowValue($row, attr) : dbRowValue($row);
    }

    /**
     * ManifestItem 'delta' column value for the row.
     *
     * A value of 1 or greater indicates that the row has been inserted but has
     * not yet been finalized via Save.
     *
     * @param {Selector} target
     *
     * @returns {number}
     */
    function dbRowDelta(target) {
        const $row  = dataRow(target, true);
        const value = $row.data(DB_DELTA_DATA);
        return value || 0;
    }

    /**
     * Set (or clear) the ManifestItem 'delta' column value for the row.
     *
     * Clearing (setting to 0) declares the row to represent a real (persisted)
     * ManifestItem record.
     *
     * @param {Selector}                     target
     * @param {string|number|null|undefined} setting
     *
     * @returns {number}
     */
    function setDbRowDelta(target, setting) {
        //_debug(`setDbRowDelta: setting = "${setting}"; target =`, target);
        const $row   = dataRow(target, true);
        const number = Number(setting);
        const value  = number || 0;
        if (number) { $row.removeAttr(DB_DELTA_ATTR) }
        $row.data(DB_DELTA_DATA, value);
        return value;
    }

    /**
     * ManifestItem 'delta' column value for the row.
     *
     * A value of 1 or greater indicates that the row has been inserted but has
     * not yet been finalized via Save.
     *
     * @param {Selector} target
     *
     * @returns {number}
     */
    function initializeDbRowDelta(target) {
        const $row = dataRow(target, true);
        const attr = $row.attr(DB_DELTA_ATTR);
        return attr ? setDbRowDelta($row, attr) : dbRowDelta($row);
    }

    /**
     * Replace item row/delta values.
     *
     * @param {Selector}            target
     * @param {ManifestItem|number} data
     *
     * @see "ManifestController#row_table"
     */
    function updateDbRowDelta(target, data) {
        const func = 'updateDbRowDelta';
        const $row = $(target);
        _debug(`${func}: target = `, target, `data =`, data);
        if (isEmpty(data)) {
            _debug(`${func}: no data supplied`);
        } else if (typeof data === 'number') {
            setDbRowValue($row, data);
            setDbRowDelta($row, 0);
        } else {
            setDbRowValue($row, data.row);
            setDbRowDelta($row, data.delta);
        }
    }

    /**
     * Update derived row values.
     *
     * @param {ManifestItemTable} table
     *
     * @see "ManifestController#row_table"
     */
    function updateRowValues(table) {
        const func = 'updateRowValues'; _debug(`${func}: table =`, table);
        allDataRows().each((_, row) => {
            const $row  = $(row);
            const db_id = manifestItemId($row);
            const entry = db_id && table[db_id];
            if (isMissing(db_id)) {
                _debug(`${func}: no db_id for $row =`, $row);
            } else if (isEmpty(entry)) {
                _debug(`${func}: no response data for db_id ${db_id}`);
            } else {
                updateDbRowDelta($row, entry);
                updateRowIndicators($row, entry);
            }
        });
    }

    // ========================================================================
    // Functions - row - status display
    // ========================================================================

    /**
     * A table status values and label for each of the status columns defined
     * by ManifestItem.
     *
     * @type {Object.<string,StringTable>}
     */
    const STATUS_TYPE_VALUES = Emma.ManifestItem.Label;

    /**
     * Status columns from ManifestItem.
     *
     * @type {string[]}
     */
    const STATUS_TYPES = Object.keys(STATUS_TYPE_VALUES);

    /**
     * The status type for a cleared indicator.
     *
     * @type {string}
     */
    const STATUS_DEFAULT = 'missing';

    /**
     * Extract status data fields.
     *
     * @param {ManifestItem|undefined} data
     *
     * @returns {object}
     *
     * @see "ManifestItemDecorator#row_indicators"
     */
    function statusData(data) {
        if (isEmpty(data)) { return {} }
        if (hasKey(data, 'last_saved')) {
            if (data.ready_status === 'ready') {
                const last_saved = timestamp(data.last_saved);
                const updated_at = timestamp(data.updated_at);
                if (!last_saved || (last_saved < updated_at)) {
                    data.ready_status = 'unsaved';
                }
            } else if (!hasKey(data, 'ready_status')) {
                const last_saved = timestamp(data.last_saved);
                const updated_at = timestamp(data.updated_at);
                if (last_saved > updated_at) {
                    data.ready_status = 'ready';
                }
            }
        }
        return compact(toObject(STATUS_TYPE_VALUES, t => presence(data[t])));
    }

    /**
     * Lookup the label for *value* based on *type*.
     *
     * @param {string} type
     * @param {string} value
     *
     * @returns {string}              Defaults to *value* if *type* not valid.
     */
    function statusLabel(type, value) {
        const entry = STATUS_TYPE_VALUES[type];
        return entry && entry[value] || value;
    }

    /**
     * The container for all indicators for the row.
     *
     * @param {Selector} target
     *
     * @returns {jQuery}
     */
    function rowIndicatorPanel(target) {
        return dataRow(target).find(`${CONTROLS_CELL} ${INDICATORS}`);
    }

    /**
     * All indicator value elements for the row.
     *
     * @param {Selector} target
     *
     * @returns {jQuery}
     */
    function rowIndicators(target) {
        return rowIndicatorPanel(target).find(INDICATOR);
    }

    /**
     * Reset the given indicator to the starting state.
     *
     * @param {Selector} target
     * @param {string}   type
     *
     * @see "ManifestItem::Config::STATUS"
     */
    function clearRowIndicator(target, type) {
        _debug(`clearRowIndicator: ${type}; target =`, target);
        updateRowIndicator(target, type, STATUS_DEFAULT);
    }

    /**
     * Modify the given indicator's CSS and displayed text.
     *
     * @param {Selector} target
     * @param {string}   type
     * @param {string}   [status]
     * @param {string}   [text]
     *
     * @see "ManifestItem::Config::STATUS"
     */
    function updateRowIndicator(target, type, status, text) {
        const func       = 'updateRowIndicator';
        const value      = status || STATUS_DEFAULT;
        const $indicator = rowIndicators(target).filter(`.${type}`);
        _debug(`${func}: ${type}: status = "${status}"`);

        // Update status text description.
        const label = isDefined(text) ? text : statusLabel(type, value);
        const l_id  = $indicator.attr('aria-labelledby');
        let $label;
        if (isPresent(l_id)) {
            $label  = $(`#${l_id}`);
        } else {
            $label  = $indicator.next('.label');
            console.warn(`${func}: no id for`, $indicator);
        }
        $label.text(label);
        $indicator.attr('title', label);

        // Update indicator CSS.
        replaceClass($indicator, 'value-', value);
    }

    /**
     * updateRowIndicators
     *
     * @param {Selector}                          target
     * @param {ManifestItemData|object|undefined} data
     */
    function updateRowIndicators(target, data) {
        //_debug('updateRowIndicators: target =', target);
        const $row   = dataRow(target);
        const status = statusData(data);
        $.each(status, (type, value) => updateRowIndicator($row, type, value));
    }

    /**
     * resetRowIndicators
     *
     * @param {Selector} target
     */
    function resetRowIndicators(target) {
        //_debug('resetRowIndicators: target =', target);
        const $row = dataRow(target);
        STATUS_TYPES.forEach(type => clearRowIndicator($row, type));
    }

    /**
     * Ensure that indicators have the appropriate tooltip from the start.
     *
     * @param {Selector} target
     */
    function initializeRowIndicators(target) {
        //_debug('initializeRowIndicators: target =', target);
        const $panel = rowIndicatorPanel(target);
        $panel.find(INDICATOR).each((_, indicator) => {
            const $indicator = $(indicator);
            const tooltip    = $indicator.attr('title');
            const label_id   = $indicator.attr('aria-labelledby');
            if (label_id && !tooltip) {
                const $label = $panel.find(`#${label_id}`);
                $indicator.attr('title', $label.text());
            }
        });
    }

    // ========================================================================
    // Functions - row - details display
    // ========================================================================

    const BLANK_DETAIL_VALUE = Field.Value.EMPTY_VALUE;

    /**
     * All details value elements for the row.
     *
     * @param {Selector} target
     *
     * @returns {jQuery}
     */
    function rowDetailsItems(target) {
        const $row = dataRow(target);
        return $row.find(`${CONTROLS_CELL} ${DETAILS} ${ROW_FIELD}`);
    }

    /**
     * Update row details entries from supplied field values.
     *
     * @param {Selector}                         target
     * @param {ManifestItemData|object|undefined} data
     */
    function updateRowDetails(target, data) {
        //_debug('updateRowDetails: target =', target);
        if (isEmpty(data)) { return }
        rowDetailsItems(target).each((_, item) => {
            const $item = $(item);
            const field = $item.attr(FIELD_ATTR);
            if (hasKey(data, field)) {
                const value = data[field] || BLANK_DETAIL_VALUE;
                $item.text(value);
            }
        });
    }

    /**
     * Set all row details entries to {@link BLANK_DETAIL_VALUE}.
     *
     * @param {Selector} target
     */
    function resetRowDetails(target) {
        //_debug('resetRowDetails: target =', target);
        rowDetailsItems(target).each((_, i) =>  $(i).text(BLANK_DETAIL_VALUE));
    }

    // ========================================================================
    // Functions - row - changed state
    // ========================================================================

    /**
     * Name of the data() entry indicating whether the data row has changed.
     *
     * @type {string}
     */
    const ROW_CHANGED_DATA = 'changed';

    /**
     * Indicate whether any of the cells of the related data row have changed.
     *
     * An undefined result means that the row hasn't been evaluated.
     *
     * @param {Selector} row
     *
     * @returns {boolean|undefined}
     */
    function rowChanged(row) {
        return dataRow(row).data(ROW_CHANGED_DATA);
    }

    /**
     * Set the related data row's changed state.
     *
     * @param {Selector} row
     * @param {boolean}  [setting]    If *false*, set as unchanged.
     *
     * @returns {boolean}
     */
    function setRowChanged(row, setting) {
        //_debug(`setRowChanged: "${setting}"; row =`, row);
        const $row    = dataRow(row)
        const changed = (setting !== false);
        $row.data(ROW_CHANGED_DATA, changed);
        return changed;
    }

    /**
     * Modify the related data row's changed state.
     *
     * @param {Selector} row
     * @param {boolean}  [setting]    Default: {@link evaluateRowChanged}
     *
     * @returns {boolean}
     */
    function updateRowChanged(row, setting) {
        _debug(`updateRowChanged: "${setting}"; row =`, row);
        const $row   = dataRow(row)
        const change = isDefined(setting) ? setting : evaluateRowChanged($row);
        setRowChanged($row, change);
        $row.toggleClass(CHANGED_MARKER, change);
        return change;
    }

    /**
     * Evaluate whether any of a row's data cells have changed.
     *
     * (No changes are made to element attributes or data.)
     *
     * @param {Selector} row
     *
     * @returns {boolean}
     */
    function evaluateRowChanged(row) {
        _debug('evaluateRowChanged: row =', row);
        const $row    = dataRow(row);
        const changed = (change, cell) => evaluateCellChanged(cell) || change;
        return dataCells($row).toArray().reduce(changed, false);
    }

    /**
     * Consult row .data() to determine if the row has changed and only attempt
     * to re-evaluate if that result is missing.
     *
     * (No changes are made to element attributes or data.)
     *
     * @param {Selector} row
     *
     * @returns {boolean}
     */
    function checkRowChanged(row) {
        //_debug('checkRowChanged: row =', row);
        const $row  = dataRow(row);
        let changed = rowChanged($row);
        if (notDefined(changed)) {
            const check = (change, cell) => change || cellChanged(cell);
            changed = dataCells($row).toArray().reduce(check, false) || false;
        }
        return changed;
    }

    /**
     * Remove the original value data item for the associated cell.
     *
     * @param {Selector} row
     */
    function clearRowChanged(row) {
        //_debug('clearRowChanged: row =', row);
        dataRow(row).removeData(ROW_CHANGED_DATA);
    }

    // ========================================================================
    // Functions - row - creation
    // ========================================================================

    /**
     * Hidden row which is used as a template when there are no actual data
     * rows to clone from.
     *
     * @type {jQuery}
     */
    const $template_row = $grid.find(`${ALL_DATA_ROW}${HIDDEN}`);

    /**
     * Create an empty unattached data row based on a previous data row.
     *
     * The {@link ITEM_ATTR} attribute is removed so that editing logic knows
     * this is a row unrelated to any ManifestItem record.
     *
     * @param {Selector} [original]   Source data row.
     *
     * @returns {jQuery}
     */
    function emptyDataRow(original) {
        _debug('emptyDataRow: original =', original);
        const $copy = cloneDataRow(original);
        removeManifestItemId($copy);
        initializeDataCells($copy);
        resetRowIndicators($copy);
        resetRowDetails($copy);
        return $copy;
    }

    /**
     * Create an unattached copy of a data row.
     *
     * @param {Selector} [original]   Source data row.
     *
     * @returns {jQuery}
     */
    function cloneDataRow(original) {
        //_debug('cloneDataRow: original =', original);
        const $row  = original ? dataRow(original) : $template_row;
        const $copy = $row.clone();

        //_debugWantNoDataValues($copy, '$copy');

        // If the row is being inserted after an inserted row, look to the
        // original row for information.
        const row   = dbRowValue($row);
        const delta = nextDeltaCounter(row);
        setDbRowValue($copy, row);
        setDbRowDelta($copy, delta);

        // Make numbered attributes unique for the row element itself and all
        // of the elements within it.
        uniqAttrs($copy, delta);
        $copy.find('*').each((_, element) => uniqAttrs(element, delta));
        toggleHidden($copy, false);

        // Hook up event handlers.
        setupRowFunctionality($copy);

        return $copy;
    }

    // ========================================================================
    // Functions - cell
    // ========================================================================

    /**
     * All grid data cells.
     *
     * @param {boolean} [hidden]      Include hidden rows.
     *
     * @returns {jQuery}
     */
    function allDataCells(hidden) {
        return dataCells(null, hidden);
    }

    /**
     * All grid data cells for the given target.
     *
     * @param {Selector|null} [target]  Default: {@link dataRows}.
     * @param {boolean}       [hidden]  Include hidden rows.
     *
     * @returns {jQuery}
     */
    function dataCells(target, hidden) {
        const $t    = target ? $(target) : null;
        const match = DATA_CELL;
        return $t?.is(match) ? $t : dataRows($t, hidden).children(match);
    }

    /**
     * Get the single grid data cell associated with the target.
     *
     * @param {Selector} target
     *
     * @returns {jQuery}
     */
    function dataCell(target) {
        const func = 'dataCell'; //_debug(`${func}: target =`, target);
        return selfOrParent(target, DATA_CELL, func);
    }

    /**
     * All matching grid data cells for the given target.
     *
     * @param {Selector}        target
     * @param {string|string[]} fields  Value(s) of {@link FIELD_ATTR}.
     *
     * @returns {jQuery}
     */
    function dataFields(target, fields) {
        const selectors = arrayWrap(fields).map(f => `[${FIELD_ATTR}="${f}"]`);
        return dataCells(target).filter(selectors.join(', '));
    }

    /**
     * Get the single matching grid data cell associated with the target.
     *
     * @param {Selector}        target
     * @param {string|string[]} field     Value for {@link FIELD_ATTR}.
     * @param {string|null}     [caller]  For diagnostics; null for no warning.
     *
     * @returns {jQuery|undefined}
     */
    function dataField(target, field, caller) {
        let $cell, match;
        if (Array.isArray(field)) {
            match = `${FIELD_ATTR} in ${field}`;
            $cell = dataFields(target, field);
        } else {
            match = `[${FIELD_ATTR}="${field}"]`;
            $cell = dataCells(target).filter(match);
        }
        if (isPresent($cell)) { return $cell }
        if (caller === null)  { return }
        const func = caller || 'dataField';
        console.warn(`${func}: no dataCell with ${match} in target =`, target);
    }

    /**
     * Get the database ManifestItem table column associated with the target.
     * *
     * @param {Selector} cell
     * *
     * @returns {string}
     */
    function cellDbColumn(cell) {
        return dataCell(cell).attr(FIELD_ATTR);
    }

    /**
     * Get the properties of the field associated with the target.
     * *
     * @param {Selector} cell
     * *
     * @returns {Properties}
     */
    function cellProperties(cell) {
        const func   = 'cellProperties';
        const field  = cellDbColumn(cell);
        const result = field && fieldProperty()[field];
        if (!field) {
            console.error(`${func}: no ${FIELD_ATTR} for`, cell);
        } else if (!result) {
            console.error(`${func}: no entry for "${field}"`);
        }
        return result || {};
    }

    /**
     * Use received data to update cell(s) associated with data values.
     *
     * @param {Selector} cell
     * @param {Value}    value
     * @param {boolean}  [change]   Default: check {@link cellOriginalValue}
     *
     * @returns {boolean}           Whether the cell value changed.
     */
    function updateDataCell(cell, value, change) {
        _debug('updateDataCell: value =', value, cell);
        const $cell = dataCell(cell);
        setCellCurrentValue($cell, value);
        setCellDisplayValue($cell, value);
        let changed = change;
        if (notDefined(changed)) {
            changed = value.differsFrom(cellOriginalValue($cell));
        }
        updateCellChanged($cell, changed);
        updateCellValid($cell);
        return changed;
    }

    // ========================================================================
    // Functions - cell - initialization
    // ========================================================================

    /**
     * Prepare all of the data cells within the target data row.
     *
     * @param {Selector} target
     */
    function initializeDataCells(target) {
        _debug('initializeDataCells: target =', target);
        dataCells(target).each((_, cell) => initializeDataCell(cell));
    }

    /**
     * Prepare the single data cell associated with the target.
     *
     * @param {Selector} cell
     *
     * @returns {jQuery}
     */
    function initializeDataCell(cell) {
        //_debug('initializeDataCell: cell =', cell);
        const $cell = dataCell(cell);
        turnOffAutocompleteIn($cell);
        clearCellDisplay($cell);
        clearCellEdit($cell);
        refreshDataCell($cell);
        return $cell;
    }

    /**
     * Reset cell stored data values and refresh cell display.
     *
     * @param {Selector} cell
     *
     * @returns {jQuery}
     */
    function resetDataCell(cell) {
        //_debug('resetDataCell: cell =', cell);
        const $cell = dataCell(cell);
        clearCellOriginalValue($cell);
        clearCellCurrentValue($cell);
        clearCellChanged($cell);
        refreshDataCell($cell);
        return $cell;
    }

    /**
     * Refresh cell display.
     *
     * @param {Selector} cell
     *
     * @returns {jQuery}
     */
    function refreshDataCell(cell) {
        //_debug('refreshDataCell: cell =', cell);
        const $cell = dataCell(cell);
        $cell.removeClass(STATUS_MARKERS);
        updateCellDisplayValue($cell);
        return $cell;
    }

    /**
     * Attach handlers for editing in all of the data cells associated with
     * the target.
     *
     * @param {Selector} [target]     Default: {@link allCellDisplays}.
     */
    function setupDataCellEditing(target) {
        _debug('setupDataCellEditing: target =', target);
        const $displays = cellDisplays(target).not('.field-FileData');
        //handleEvent($displays, 'mouseenter', _debugDataValuesTooltip);
        handleClickAndKeypress($displays, onStartValueEdit);
    }

    // ========================================================================
    // Functions - cell - finalization
    // ========================================================================

    /**
     * Finalize data cells prior to page exit.
     *
     * @param {string}   from         'current' or 'original'
     * @param {Selector} [target]     Default: {@link allDataRows}.
     */
    function finalizeDataCells(from, target) {
        _debug(`finalizeDataCells: from ${from}: target =`, target);

        let v;
        const curr      = $c => cellCurrentValue($c);
        const orig      = $c => cellOriginalValue($c);
        const from_curr = $c => (v = curr($c)) && setCellOriginalValue($c, v);
        const from_orig = $c => (v = orig($c)) && setCellCurrentValue($c, v);
        const from_disp = $c => cellDisplayValue($c);
        const current   = notDefined(from) || (from === 'current');

        dataCells(target).each((_, cell) => {
            const $cell = $(cell);
            if (current) {
                from_curr($cell) || from_orig($cell) || from_disp($cell);
            } else {
                from_orig($cell) || from_curr($cell) || from_disp($cell);
            }
            clearCellChanged($cell);
        });
    }

    // ========================================================================
    // Functions - cell - changed state
    // ========================================================================

    /**
     * Name of the data() entry indicating whether the cell value has changed
     * since the last save.
     *
     * @type {string}
     */
    const VALUE_CHANGED_DATA = 'valueChanged';

    /**
     * Indicate whether the related cell's data has changed.
     *
     * An undefined result means that the cell hasn't been evaluated.
     *
     * @param {Selector} cell
     *
     * @returns {boolean|undefined}
     */
    function cellChanged(cell) {
        return dataCell(cell).data(VALUE_CHANGED_DATA);
    }

    /**
     * Set the related data cell's changed state.
     *
     * @param {Selector} cell
     * @param {boolean}  [setting]    Default: *true*.
     *
     * @returns {boolean}
     */
    function setCellChanged(cell, setting) {
        _debug(`setCellChanged: "${setting}"; cell =`, cell);
        const $cell   = dataCell(cell);
        const changed = (setting !== false);
        $cell.data(VALUE_CHANGED_DATA, changed);
        return changed;
    }

    /**
     * Set the related data cell's changed state to 'undefined'.
     *
     * @param {Selector} cell
     */
    function clearCellChanged(cell) {
        _debug('clearCellChanged: cell =', cell);
        dataCell(cell).removeData(VALUE_CHANGED_DATA);
    }

    /**
     * Change the related data cell's changed status.
     *
     * @param {Selector} cell
     * @param {boolean}  setting
     *
     * @returns {boolean}
     */
    function updateCellChanged(cell, setting) {
        _debug(`updateCellChanged: "${setting}"; cell =`, cell);
        const $cell   = dataCell(cell);
        const changed = setCellChanged($cell, setting);
        $cell.toggleClass(CHANGED_MARKER, changed);
        return changed;
    }

    /**
     * Refresh the related data cell's changed status.
     *
     * @param {Selector} cell
     *
     * @returns {boolean}
     */
    function evaluateCellChanged(cell) {
        _debug('evaluateCellChanged: cell =', cell);
        const $cell = dataCell(cell);
        let changed = cellChanged($cell);
        if (notDefined(changed)) {
            const original = cellOriginalValue($cell);
            const current  = cellCurrentValue($cell);
            changed = current.differsFrom(original);
        }
        return updateCellChanged($cell, changed);
    }

    // ========================================================================
    // Functions - cell - validity state
    // ========================================================================

    /**
     * Name of the data() entry indicating whether the data cell is valid.
     *
     * @type {string}
     */
    const CELL_VALID_DATA = 'valid';

    /**
     * Indicate whether the related cell's data is currently valid.
     *
     * @param {Selector} cell
     *
     * @returns {boolean}
     */
    function cellValid(cell) {
        const $cell = dataCell(cell);
        const valid = $cell.data(CELL_VALID_DATA);
        return isDefined(valid) ? valid : updateCellValid($cell);
    }

    /**
     * Set the related data cell's valid state.
     *
     * @param {Selector} cell
     * @param {boolean}  [setting]    If *false*, make invalid.
     *
     * @returns {boolean}             True if set to valid.
     */
    function setCellValid(cell, setting) {
        //_debug(`setCellValid: "${setting}"; cell =`, cell);
        const $cell  = dataCell(cell);
        const field  = $cell.attr('data-field');
        const $input = $cell.find(`[name="${field}"]`);
        const valid  = (setting !== false);
        if (!valid) {
            $input.attr('aria-invalid', true);
        } else if ($input.attr('aria-required') === 'true') {
            $input.attr('aria-invalid', false);
        } else {
            $input.removeAttr('aria-invalid');
        }
        $cell.toggleClass(ERROR_MARKER, !valid);
        $cell.data(CELL_VALID_DATA, valid);
        return valid;
    }

    /**
     * Change the related data cell's validity status.
     *
     * @param {Selector} cell
     * @param {boolean}  [setting]    Default: {@link evaluateCellValid}
     *
     * @returns {boolean}             True if valid.
     */
    function updateCellValid(cell, setting) {
        //_debug(`updateCellValid: "${setting}"; cell =`, cell);
        const $cell = dataCell(cell);
        const valid = isDefined(setting) ? setting : evaluateCellValid($cell);
        return setCellValid($cell, valid);
    }

    /**
     * Evaluate the current value of the associated data cell to determine
     * whether it is acceptable.
     *
     * (No changes are made to element attributes or data.)
     *
     * @param {Selector} cell
     * @param {Value}    [current]    Default: {@link cellCurrentValue}.
     *
     * @returns {boolean}
     */
    function evaluateCellValid(cell, current) {
        //_debug('evaluateCellValid: cell =', cell);
        const $cell = dataCell(cell);
        const prop  = cellProperties($cell);
        if (!prop.required) {
            return true;
        }
        /** @type {Value|undefined} */
        let value;
        if (isDefined(current)) {
            value = $cell.makeValue(current, prop);
        } else {
            value = cellCurrentValue($cell);
        }
        return !!value?.nonBlank;
    }

    // ========================================================================
    // Functions - cell - original value
    // ========================================================================

    /**
     * Name of the data() entry holding the original value of a cell.
     *
     * @type {string}
     */
    const ORIGINAL_VALUE_DATA = 'originalValue';

    /**
     * The original value of the associated cell.
     * *
     * @param {Selector} cell
     * *
     * @returns {Value|undefined}
     */
    function cellOriginalValue(cell) {
        return dataCell(cell).data(ORIGINAL_VALUE_DATA);
    }

    /**
     * Assign the original value for the associated cell.
     *
     * @param {Selector} cell
     * @param {Value|*}  new_value
     *
     * @returns {Value}
     */
    function setCellOriginalValue(cell, new_value) {
        //_debug('setCellOriginalValue: new_value =', new_value, cell);
        const $cell = dataCell(cell);
        const value = $cell.makeValue(new_value);
        $cell.data(ORIGINAL_VALUE_DATA, value);
        return value;
    }

    /**
     * Initialize the original value for the associated cell.
     *
     * @param {Selector} cell
     * @param {Value}    value
     *
     * @returns {Value}
     */
    function initCellOriginalValue(cell, value) {
        //_debug('initCellOriginalValue: value =', value, cell);
        const $cell = dataCell(cell);
        return cellOriginalValue($cell) || setCellOriginalValue($cell, value);
    }

    /**
     * Remove the original value data item for the associated cell.
     *
     * @param {Selector} cell
     */
    function clearCellOriginalValue(cell) {
        //_debug('clearCellOriginalValue: cell =', cell);
        dataCell(cell).removeData(ORIGINAL_VALUE_DATA);
    }

    // ========================================================================
    // Functions - cell - current value
    // ========================================================================

    /**
     * Name of the data() entry holding the current value of a cell.
     *
     * @type {string}
     */
    const CURRENT_VALUE_DATA = 'currentValue';

    /**
     * The current value of the associated cell.
     * *
     * @param {Selector} cell
     * *
     * @returns {Value|undefined}
     */
    function cellCurrentValue(cell) {
        return dataCell(cell).data(CURRENT_VALUE_DATA);
    }

    /**
     * Assign the current value for the associated cell.
     *
     * @param {Selector} cell
     * @param {Value|*}  new_value
     *
     * @returns {Value}
     */
    function setCellCurrentValue(cell, new_value) {
        //_debug('setCellCurrentValue: new_value =', new_value, cell);
        const $cell = dataCell(cell);
        const value = $cell.makeValue(new_value);
        $cell.data(CURRENT_VALUE_DATA, value);
        return value;
    }

    /**
     * Initialize the current value for the associated cell.
     *
     * @param {Selector} cell
     * @param {Value}    value
     *
     * @returns {Value}
     */
    function initCellCurrentValue(cell, value) {
        //_debug('initCellCurrentValue: value =', value, cell);
        const $cell = dataCell(cell);
        return cellCurrentValue($cell) || setCellCurrentValue($cell, value);
    }

    /**
     * Remove the current value data item for the associated cell.
     *
     * @param {Selector} cell
     */
    function clearCellCurrentValue(cell) {
        //_debug('clearCellCurrentValue: cell =', cell);
        dataCell(cell).removeData(CURRENT_VALUE_DATA);
    }

    // ========================================================================
    // Functions - cell - display
    // ========================================================================

    /**
     * All grid data cell display elements.
     *
     * @param {boolean} [hidden]      Include hidden rows.
     *
     * @returns {jQuery}
     */
    function allCellDisplays(hidden) {
        return cellDisplays(null, hidden);
    }

    /**
     * All grid data cell display elements for the given target.
     *
     * @param {Selector|null} [target]  Default: {@link dataCells}.
     * @param {boolean}       [hidden]  Include hidden rows.
     *
     * @returns {jQuery}
     */
    function cellDisplays(target, hidden) {
        const $t    = target ? $(target) : null;
        const match = CELL_DISPLAY;
        return $t?.is(match) ? $t : dataCells($t, hidden).children(match);
    }

    /**
     * The display element for a single grid data cell.
     *
     * @param {Selector} target
     *
     * @returns {jQuery}
     */
    function cellDisplay(target) {
        const match   = CELL_DISPLAY;
        const $target = $(target);
        return $target.is(match) ? $target : dataCell($target).children(match);
    }

    /**
     * Remove content from a data cell display element.
     *
     * @param {Selector} target
     */
    function clearCellDisplay(target) {
        //_debug('clearCellDisplay: target =', target);
        const $cell = dataCell(target);
        if ($cell.is(MultiUploader.UPLOADER)) {
            setUploaderDisplayValue($cell);
        } else {
            cellDisplay($cell).empty();
        }
    }

    // ========================================================================
    // Functions - cell - display - value
    // ========================================================================

    /**
     * Get the displayed value for a data cell.
     *
     * @param {Selector} cell
     * *
     * @returns {Value}
     */
    function cellDisplayValue(cell) {
        const $cell = dataCell(cell);
        const text  = cellDisplay($cell).text();
        const value = $cell.makeValue(text);
        initCellOriginalValue($cell, value);
        initCellCurrentValue($cell, value);
        return value;
    }

    /**
     * Set the displayed value for a data cell.
     *
     * @param {Selector} cell
     * @param {Value}    new_value
     */
    function setCellDisplayValue(cell, new_value) {
        //_debug('setCellDisplayValue: new_value =', new_value, cell);
        const $cell = dataCell(cell);
        if ($cell.is(MultiUploader.UPLOADER)) {
            setUploaderDisplayValue(cell, new_value);
        } else {
            const $value = cellDisplay($cell);
            if (notDefined(new_value)) {
                $value.text('');
            } else {
                const value = $cell.makeValue(new_value);
                const list  = $cell.is('.textbox');
                $value.html(list ? value.toHtml() : value.forDisplay(true));
            }
        }
    }

    /**
     * Refresh the cell display according to the data type.
     *
     * @param {Selector} cell
     * @param {Value}    [new_value]    Default: from {@link cellDisplay}.
     */
    function updateCellDisplayValue(cell, new_value) {
        //_debug('updateCellDisplayValue: new_value =', new_value, cell);
        const $cell = dataCell(cell);
        let value;
        if (isDefined(new_value)) {
            value = $cell.makeValue(new_value);
        } else {
            value = cellDisplayValue($cell);
        }
        setCellDisplayValue($cell, value);
        updateCellValid($cell);
    }

    // ========================================================================
    // Functions - cell - display - file_data
    // ========================================================================

    function setUploaderDisplayValue(cell, new_value, data_type) {
        const $cell = dataCell(cell);
        const $name = $cell.find(MultiUploader.FILE_NAME);
        let file, type;
        if (typeof new_value === 'string') {
            file = new_value;
            type = data_type;
        } else {
            const value = new_value ? $cell.makeValue(new_value).value : {};
            type =
                ((file = value.metadata?.filename) && 'uploader') ||
                ((file = value.name)               && 'name') ||
                ((file = value.url)                && 'url');
        }
        const from_type = `.from-${type}`;
        let show_name   = false;
        $name.children().each((_, line) => {
            const $line  = $(line);
            const active = $line.is(from_type);
            $line.text(active && file || '');
            $line.attr('aria-hidden', !active);
            $line.toggleClass('active', active);
            show_name = active || show_name;
        });
        $name.toggleClass('complete', show_name);
    }

    // ========================================================================
    // Functions - cell - display - edit input
    // ========================================================================

    /**
     * The edit element for a data cell.
     *
     * @param {Selector} target
     * *
     * @returns {jQuery}
     */
    function cellEdit(target) {
        const match   = CELL_EDIT;
        const $target = $(target);
        return $target.is(match) ? $target : dataCell($target).children(match);
    }

    /**
     * Remove content from a data cell edit element.
     *
     * @param {Selector} cell
     */
    function clearCellEdit(cell) {
        //_debug('clearCellEdit:', cell);
        const $edit = cellEdit(cell);
        editClear($edit);
    }

    /**
     * Get the input value for a data cell.
     *
     * @param {Selector} cell
     * *
     * @returns {Value}
     */
    function cellEditValue(cell) {
        const $edit = cellEdit(cell);
        const value = editGet($edit);
        return $edit.makeValue(value);
    }

    /**
     * Set the input value for a data cell.
     *
     * @param {Selector} cell
     * @param {Value}    [new_value]  Default from displayed value.
     */
    function setCellEditValue(cell, new_value) {
        //_debug('setCellEditValue: new_value =', new_value, cell);
        const $cell = dataCell(cell);
        const $edit = cellEdit($cell);
        let value;
        if (isDefined(new_value)) {
            value = $cell.makeValue(new_value);
        } else {
            value = cellCurrentValue($cell) || cellDisplayValue($cell);
        }
        editSet($edit, value);
    }

    // ========================================================================
    // Functions - cell - editing
    // ========================================================================

    /**
     * Combine {@link startValueEdit} and {@link finishValueEdit}.
     *
     * @param {Selector} cell
     * @param {*}        new_value
     */
    function atomicEdit(cell, new_value) {
        const func  = 'atomicEdit';
        const $cell = dataCell(cell)
        if (inCellEditMode($cell)) {
            _debug(`--- ${func}: already editing $cell =`, $cell);
        } else {
            _debug(`>>> ${func}: $cell =`, $cell);
            setCellEditMode($cell, true);
            cellEditBegin($cell);
            postStartEdit($cell);
            debounce(() => {
                const value = $cell.makeValue(new_value);
                postFinishEdit($cell, value);
                setCellEditMode($cell, false);
            })();
        }
    }

    /**
     * Respond to click within a data cell value.
     *
     * @param {jQuery.Event|UIEvent} event
     */
    function onStartValueEdit(event) {
        _debug('onStartValueEdit: event =', event);
        const $cell = dataCell(event.currentTarget || event.target);
        startValueEdit($cell);
        cellEdit($cell).focus();
        // TODO: move the caret to the perceived location of the mouse click
    }

    /**
     * Begin editing a cell.
     *
     * @param {Selector} cell
     */
    function startValueEdit(cell) {
        const func  = 'startValueEdit';
        const $cell = dataCell(cell);
        if (inCellEditMode($cell)) {
            _debug(`--- ${func}: already editing $cell =`, $cell);
        } else {
            _debug(`>>> ${func}: $cell =`, $cell);
            setCellEditMode($cell, true);
            cellEditBegin($cell);
            postStartEdit($cell);
        }
    }

    /**
     * Inform the server that a row associated with a ManifestItem record is
     * being edited.
     *
     * @param {Selector} cell
     *
     * @see "ManifestItemController#start_edit"
     */
    function postStartEdit(cell) {
        const func = 'postStartEdit';

        if (!manifestId()) {
            _debug(`${func}: triggering manifest creation`);
            createManifest();
            return;
        }

        const $cell = dataCell(cell);
        const $row  = dataRow($cell);
        const db_id = manifestItemId($row);
        if (!db_id) {
            _debug(`${func}: no db_id for $row =`, $row);
            return;
        }

        _debug(`${func}: $row = `, $row);
        const action = `start_edit/${db_id}`;
        const row    = dbRowValue($row);
        const delta  = dbRowDelta($row);

        serverItemSend(action, {
            caller:     func,
            params:     { row: row, delta: delta },
            onError:    () => finishValueEdit($cell),
        });
    }

    /**
     * End editing a cell.
     *
     * @param {Selector} cell
     */
    function finishValueEdit(cell) {
        const func  = 'finishValueEdit';
        const $cell = dataCell(cell);
        if (inCellEditMode($cell)) {
            _debug(`<<< ${func}: $cell =`, $cell);
            const new_value = cellEditEnd($cell);
            postFinishEdit($cell, new_value);
            setCellEditMode($cell, false);
        } else {
            _debug(`--- ${func}: not editing $cell =`, $cell);
        }
    }

    /**
     * Transition a data cell into edit mode.
     *
     * @param {Selector} cell
     * @param {Value}    [new_value]  Default from displayed value.
     */
    function cellEditBegin(cell, new_value) {
        _debug('cellEditBegin: new_value =', new_value, cell);
        const $cell = dataCell(cell);
        setCellEditValue($cell, new_value);
        registerActiveCell($cell);
    }

    /**
     * Transition a data cell out of edit mode.
     *
     * @param {Selector} cell
     *
     * @returns {Value|undefined}
     */
    function cellEditEnd(cell) {
        _debug('cellEditEnd:', cell);
        const $cell     = dataCell(cell);
        const old_value = cellCurrentValue($cell);
        const new_value = cellEditValue($cell);
        if (new_value.differsFrom(old_value)) {
            const $row        = dataRow($cell);
            const row_change  = rowChanged($row);
            const cell_change = updateDataCell($cell, new_value);
            if (cell_change !== row_change) {
                updateRowChanged($row);
                updateFormChanged();
            }
        }
        return new_value;
    }

    /**
     * Inform the server that a row associated with a ManifestItem record is no
     * longer being edited.
     *
     * If a value is supplied, the associated record field is updated (or used
     * to create a new record).
     *
     * @param {Selector}        cell
     * @param {Value|undefined} new_value
     *
     * @see "ManifestItemController#start_edit"
     */
    function postFinishEdit(cell, new_value) {
        const func     = 'postFinishEdit';
        const $cell    = dataCell(cell);
        const $row     = dataRow($cell);
        const db_id    = manifestItemId($row);
        const manifest = manifestId();

        if (!manifest) {
            _error(`${func}: no manifest ID`);
            return;
        }

        let data, action, on_success;
        if (isDefined(new_value)) {
            const field = cellDbColumn($cell);
            data        = { [field]: new_value.toString() };
            data.row    = dbRowValue($row);
            data.delta  = dbRowDelta($row);
        }
        if (db_id) {
            action     = `finish_edit/${db_id}`;
            on_success = parseFinishEditResponse;
        } else if (data) {
            action     = `create/${manifest}`;
            on_success = parseCreateResponse;
        } else {
            _debug(`${func}: nothing to transmit`);
            return;
        }
        const params = data ? { manifest_item: data } : {};
        _debug(`${func}: params =`, params);

        serverItemSend(action, {
            caller:     func,
            params:     params,
            onSuccess:  body => on_success($cell, body),
        });
    }

    /**
     * Receive updated fields for the item.
     *
     * @param {jQuery}                                    $cell
     * @param {CreateResponse|{response: CreateResponse}} body
     *
     * @see "ManifestItemConcern#create_manifest_item"
     */
    function parseCreateResponse($cell, body) {
        _debug('parseCreateResponse: body =', body);
        // noinspection JSValidateTypes
        /** @type {CreateResponse} */
        const data = body?.response || body;
        if (isPresent(data)) {
            updateDataRow($cell, data);
        }
    }

    /**
     * Receive updated fields for the item, plus problem reports, plus invalid
     * fields for each item that would prevent a save from occurring.
     *
     * @param {jQuery}                                            $cell
     * @param {FinishEditResponse|{response: FinishEditResponse}} body
     *
     * @see "ManifestItemConcern#finish_editing"
     * @see "Manifest::ItemMethods#pending_items_hash"
     * @see "ActiveModel::Errors"
     */
    function parseFinishEditResponse($cell, body) {
        _debug('parseFinishEditResponse: body =', body);
        /** @type {FinishEditResponse} */
        const data     = body?.response || body || {};
        const items    = presence(data.items);
        const pending  = presence(data.pending);
        const problems = presence(data.problems);

        // Update fields(s) echoed back from the server.  This may also include
        // 'file_status' and/or 'data_status'
        // @see "ManifestItemConcern#finish_editing"
        const $row   = dataRow($cell);
        const db_id  = manifestItemId($row);
        const record = items && items[db_id];
        if (isPresent(record)) {
            updateDataRow($row, record);
            if (pending && isPresent(statusData(record))) {
                delete pending[db_id];
            }
        }

        // Update status indicators
        // @see "Manifest::ItemMethods#pending_items_hash"
        if (pending) {
            const $rows = allDataRows();
            $.each(pending, (id, item) => {
                const $row = isPresent(item) && rowForManifestItem(id, $rows);
                if ($row) { updateRowIndicators($row, item) }
            });
        }

        // Error message(s) to display.
        // @see "ActiveModel::Errors"
        if (problems) {
            let count = 0;
            $.each(problems, (type, lines) => {
                const message =
                    (!Array.isArray(lines) && `${type}: ${lines}`)    ||
                    ((lines.length === 1)  && `${type}: ${lines[0]}`) ||
                    (                         [type, ...lines])
                if (count++) {
                    addFlashError(message);
                } else {
                    flashError(message);
                }
            });
        }
    }

    // ========================================================================
    // Functions - cell - editing - operations
    // ========================================================================

    /**
     * EditElementOperations
     *
     * @typedef {{
     *     clr?: function(jQuery)        : void,
     *     get?: function(jQuery)        : string[]|string|undefined,
     *     set?: function(jQuery, Value) : void,
     * }} EditElementOperations
     */

    /**
     * Element operations that are different the default ones.
     *
     * @type {Object.<string, EditElementOperations>}
     */
    const EDIT = {
        multi_select: {
            clr: ($e)    => checkboxes($e).prop('checked', false),
            get: ($e)    => checkboxes($e, true).toArray().map(e => e.value),
            set: ($e, v) => {
                const cbs = checkboxes($e).toArray();
                const set = new Set(v.toArray());
                cbs.forEach(cb => $(cb).prop('checked', set.has(cb.value)));
            },
        },
        checkbox: {
            clr: ($e)    => $e.prop('checked', false),
            get: ($e)    => $e.prop('checked'),
            set: ($e, v) => $e.prop('checked', (v.value === $e.prop('value'))),
        },
        default: {
            clr: ($e)    => $e.val(''),
            get: ($e)    => $e.val(),
            set: ($e, v) => $e.val(v.forInput()),
        },
    }

    /**
     * Types of edit elements and their characteristic CSS selectors.
     *
     * @type {StringTable}
     */
    const EDIT_TYPE = {
        multi_select: '.menu.multi',
        menu:         '.menu.single',
        list:         'textarea',
        checkbox:     'input[type="checkbox"]',
        date:         'input[type="date"]',
        text:         'input[type="text"]',
        string:       'input',
    };

    /**
     * Return the type of the edit element.
     *
     * @param {jQuery} $edit
     *
     * @returns {string}
     */
    function editType($edit) {
        let res;
        $.each(EDIT_TYPE, (type, match) => !($edit.is(match) && (res = type)));
        return res || 'string';
    }

    /**
     * Execute the given edit operation.
     *
     * @param {jQuery} $edit
     * @param {string} op             An EditElementOperations key.
     * @param {string} [edit_type]    Default: {@link editType}
     * @param {Value}  [value]        Only for 'set'.
     */
    function editOp($edit, op, edit_type, value) {
        const type = edit_type || editType($edit);
        const func = EDIT[type] && EDIT[type][op] || EDIT.default[op];
        return (op === 'set') ? func($edit, value) : func($edit);
    }

    /**
     * Get the value of the edit element.
     *
     * @param {jQuery} $edit
     * @param {string} [edit_type]    Default: {@link editType}
     *
     * @returns {string|string[]}
     */
    function editGet($edit, edit_type) {
        return editOp($edit, 'get', edit_type);
    }

    /**
     * Set the value of the edit element.
     *
     * @param {jQuery} $edit
     * @param {Value}  value
     * @param {string} [edit_type]    Default: {@link editType}
     */
    function editSet($edit, value, edit_type) {
        editOp($edit, 'set', edit_type, value);
    }

    /**
     * Reset the value of the edit element.
     *
     * @param {jQuery} $edit
     * @param {string} [edit_type]    Default: {@link editType}
     */
    function editClear($edit, edit_type) {
        editOp($edit, 'clr', edit_type);
    }

    // ========================================================================
    // Functions - cell - editing - life cycle
    // ========================================================================

    /**
     * Name of the $grid data() entry holding a reference to the cell currently
     * being edited.
     *
     * @type {string}
     */
    const ACTIVE_CELL_DATA = 'activeCell';

    /**
     * The data cell which is currently being edited.
     *
     * @returns {jQuery|undefined}
     */
    function activeCell() {
        const active = $grid.data(ACTIVE_CELL_DATA);
        return active && $(active);
    }

    /**
     * Remember the active cell.
     *
     * @param {Selector} cell
     */
    function setActiveCell(cell) {
        const func   = 'setActiveCell';
        const active = dataCell(cell)[0];
        if (active) {
            _debug(`${func}: target =`, cell);
            $grid.data(ACTIVE_CELL_DATA, active);
        } else {
            console.error(`${func}: empty:`, cell);
            clearActiveCell();
        }
    }

    /**
     * Forget the active cell.
     */
    function clearActiveCell() {
        //_debug('discardActiveCell');
        $grid.removeData(ACTIVE_CELL_DATA);
    }

    /**
     * Indicate that the related data cell is being edited.
     *
     * @param {Selector} cell
     */
    function registerActiveCell(cell) {
        _debug('registerActiveCell: cell =', cell);
        deregisterActiveCell();
        setActiveCell(cell);
    }

    /**
     * Resolve the currently active data cell edit by capturing the 'focus'
     * event to see whether it is going somewhere outside the active cell.
     * If so then editing of the active cell is ended.
     *
     * @param {jQuery.Event|Event} [event]
     *
     * @note 'focus' does not bubble; this should be triggered during capture.
     *
     * @see https://javascript.info/bubbling-and-capturing
     */
    function deregisterActiveCell(event) {
        const $active = activeCell();
        if ($active) {
            const func  = 'deregisterActiveCell';
            const $cell = event?.target ? dataCell(event.target) : $(null);
            if ($cell[0] === $active[0]) {
                _debug(`${func}: inside active data cell; event =`, event);
            } else {
                _debug(`${func}: outside of active data cell; event =`, event);
                completeActiveCell();
            }
        }
    }

    /**
     *  Resolve the currently active data cell.
     */
    function completeActiveCell() {
        //_debug('completeActiveCell');
        const $active = activeCell();
        if ($active) {
            finishValueEdit($active);
            clearActiveCell();
        }
    }

    /**
     * Abandon editing of the currently active data cell.
     */
    function cancelActiveCell() {
        _debug('cancelActiveCell');
        const $active = activeCell();
        if ($active) {
            setCellEditMode($active, false);
            clearActiveCell();
        }
    }

    /**
     * setCellEditMode
     *
     * @param {Selector} cell
     * @param {boolean}  [setting]    If *false*, unset edit mode.
     */
    function setCellEditMode(cell, setting) {
        //_debug(`setCellEditMode: setting = "${setting}"; cell =`, cell);
        const editing = (setting !== false);
        dataCell(cell).toggleClass(EDITING_MARKER, editing);
    }

    /**
     * inCellEditMode
     *
     * @param {Selector} cell
     *
     * @returns {boolean}
     */
    function inCellEditMode(cell) {
        return dataCell(cell).is(EDITING);
    }

    // ========================================================================
    // Functions - display - header rows
    // ========================================================================

    let $header_row, $header_columns;
    let $header_row_toggle, $controls_column_toggle;

    /**
     * Grid header row(s).
     *
     * The bottom row is the one that holds field properties and is used as a
     * reference point for grid data rows.
     *
     * @note Currently there is only one header row.
     *
     * @returns {jQuery}
     */
    function headerRow() {
        return $header_row ||= $grid.find(HEAD_ROW).last();
    }

    /**
     * The column headers in the heading row.
     *
     * @returns {jQuery}
     */
    function headerColumns() {
        return $header_columns ||= headerRow().children();
    }

    /**
     * Control to expand/contract the header row(s).
     *
     * @returns {jQuery}
     */
    function headerRowToggle() {
        return $header_row_toggle ||= makeHeaderRowToggle();
    }

    /**
     * Finalize the control for expanding/contracting the header row(s).
     *
     * @param {Selector} [target]
     *
     * @returns {jQuery}
     */
    function makeHeaderRowToggle(target) {
        const id_base = 'col';
        const $toggle = target ? $(target) : headerRow().find(ROW_EXPANDER);
        makeToggle($toggle, id_base);
        headerColumns().filter(DATA_CELL).each(
            (_, col) => addToToggleControlsList($toggle, col)
        );
        return $toggle;
    }

    /**
     * Control to expand/contract the controls column.
     *
     * @returns {jQuery}
     */
    function controlsColumnToggle() {
        return $controls_column_toggle ||= makeControlsColumnToggle();
    }

    /**
     * Finalize the control for expanding/contracting the controls column.
     *
     * @{link setupRowOperations} is relied upon to update 'aria-controls'
     * initially and for rows added subsequently.
     *
     * @param {Selector} [target]
     *
     * @returns {jQuery}
     */
    function makeControlsColumnToggle(target) {
        const id_base = 'row';
        const $toggle = target ? $(target) : headerRow().find(COL_EXPANDER);
        return makeToggle($toggle, id_base);
    }

    /**
     * Include the controls column for a new row into the set of elements
     * controlled by the column toggle.
     *
     * @param {Selector} target
     */
    function addToControlsColumnToggle(target) {
        const $toggle = controlsColumnToggle();
        const $cell   = controlsColumn(target);
        addToToggleControlsList($toggle, $cell);
    }

    /**
     * Remove row(s) from the set of elements controlled by the column toggle.
     *
     * @param {Selector} target
     */
    function removeFromControlsColumnToggle(target) {
        const $toggle = controlsColumnToggle();
        const $cell   = controlsColumn(target);
        removeFromToggleControlsList($toggle, $cell);
    }

    const CONTROLS_IDS_DATA  = 'controlsIds';
    const CONTROLS_BASE_DATA = 'controlsBase';

    /**
     * Finalize a control for expanding/contracting a set of elements.
     *
     * @param {jQuery} $toggle
     * @param {string} base_name
     *
     * @returns {jQuery}
     */
    function makeToggle($toggle, base_name) {
        const list = $toggle.attr('aria-controls');
        const ids  = isPresent(list) ? list.split(/\s+/) : [];
        $toggle.data(CONTROLS_IDS_DATA,  ids);
        $toggle.data(CONTROLS_BASE_DATA, randomizeName(base_name));
        return $toggle;
    }

    /**
     * Update a toggle to control one or more added elements.
     *
     * @param {jQuery}   $toggle
     * @param {Selector} elements
     */
    function addToToggleControlsList($toggle, elements) {
        const base  = $toggle.data(CONTROLS_BASE_DATA);
        const ids   = $toggle.data(CONTROLS_IDS_DATA) || [];
        const start = ids.length;
        let index   = start;
        $(elements).each((_, element) => {
            const $element = $(element);
            let element_id = $element.attr('id');
            if (isMissing(element_id)) {
                element_id = `${base}-${++index}`;
                $element.attr('id', element_id);
            }
            if (!ids.includes(element_id)) {
                ids.push(element_id);
            }
        });
        if (ids.length > start) {
            $toggle.data(CONTROLS_IDS_DATA, ids);
            $toggle.attr('aria-controls', ids.join(' '));
        }
    }

    /**
     * Remove one or more elements from the set a toggle controls.
     *
     * @param {jQuery}   $toggle
     * @param {Selector} elements
     */
    function removeFromToggleControlsList($toggle, elements) {
        const ids       = $(elements).toArray().map(e => $(e).attr('id'));
        const id_set    = new Set(compact(ids));
        const start_ids = $toggle.data(CONTROLS_IDS_DATA) || [];
        const final_ids = start_ids.filter(id => !id_set.has(id));
        if (final_ids.length < start_ids.length) {
            $toggle.data(CONTROLS_IDS_DATA, final_ids);
            $toggle.attr('aria-controls', final_ids.join(' '));
        }
    }

    // ========================================================================
    // Functions - database - Manifest
    // ========================================================================

    let manifest_id;

    /**
     * The Manifest ID associated with these manifest rows.
     *
     * @note Currently this is *only* associated with the $grid element.
     *
     * @returns {string|undefined}
     */
    function manifestId() {
        return manifest_id ||= manifestFor();
    }

    /**
     * The Manifest ID associated with the target.
     *
     * @param {Selector} [target]     Default: {@link $grid}.
     *
     * @returns {string|undefined}
     */
    function manifestFor(target) {
        const func = 'manifestFor'; //_debug(`${func}: target =`, target);
        let id;
        if (target) {
            (id = attribute(target, MANIFEST_ATTR)) ||
                console.error(`${func}: no ${MANIFEST_ATTR} for`, target);
        } else {
            (id = $grid.attr(MANIFEST_ATTR)) ||
                _debug(`${func}: no manifest ID`);
        }
        return id || manifest_id;
    }

    /**
     * Update or create a Manifest with the given title.
     *
     * @param {string}       new_name
     * @param {XmitCallback} [callback]
     */
    function setManifestName(new_name, callback) {
        // noinspection JSValidateTypes
        /** @type {Manifest} */
        const params = { name: new_name }
        if (manifestId()) {
            updateManifest(params, callback);
        } else {
            createManifest(params, callback);
        }
    }

    /**
     * createManifest
     *
     * @param {Manifest}     [data]
     * @param {XmitCallback} [callback]
     */
    function createManifest(data, callback) {
        const func   = 'createManifest';
        const params = { ...data };
        const method = params.method || 'POST';
        const id     = params.id;
        _debug(`${func}: id = ${id}`);

        params.name ||= $title_text.text();
        delete params.method;

        serverManifestSend('create', {
            caller:     func,
            method:     method,
            params:     params,
            onSuccess:  processManifestData,
            onComplete: callback,
        });
    }

    /**
     * updateManifest
     *
     * @param {Manifest}     data
     * @param {XmitCallback} [callback]
     */
    function updateManifest(data, callback) {
        const func   = 'updateManifest';
        const params = { ...data };
        const method = params.method || 'PUT';
        const id     = params.id || manifestId();
        _debug(`${func}: id = ${id}`);

        if (isMissing(id)) {
            const error = 'no manifest ID';
            _error(`${func}: ${error}`);
            callback?.(undefined, undefined, error, new XMLHttpRequest());
            return;
        }
        delete params.id;
        delete params.method;

        serverManifestSend(`update/${id}`, {
            caller:     func,
            method:     method,
            params:     params,
            onSuccess:  processManifestData,
            onComplete: callback,
        });
    }

    /**
     * processManifestData
     *
     * @param {Manifest} data
     */
    function processManifestData(data) {
        const func = 'processManifestData';
        _debug(`${func}: data =`, data);
        if (isEmpty(data)) {
            return;
        }
        if (data.id) {
            const current = manifestId();
            if (!current) {
                $grid.attr(MANIFEST_ATTR, data.id);
            } else if (data.id !== current) {
                _error(`${func}: id ${data.id} !== current ${current}`);
                return;
            }
        }
        if (data.name) {
            $title_text.text(data.name);
        }
    }

    // ========================================================================
    // Functions - database - ManifestItem
    // ========================================================================

    /**
     * The database ID for the ManifestItem associated with the target.
     *
     * The only rows for which this value should be undefined are blank rows
     * which have never had any activity which would have lead to the creation
     * of a ManifestItem to be associated with the row.
     *
     * @param {Selector} target
     *
     * @returns {number|undefined}
     */
    function manifestItemId(target) {
        const value = attribute(target, ITEM_ATTR);
        return Number(value) || undefined;
    }

    /**
     * Set the database ID for the ManifestItem associated with the target.
     *
     * @param {Selector}      target
     * @param {number|string} value
     *
     * @returns {number|undefined}
     */
    function setManifestItemId(target, value) {
        const func = 'setManifestItemId';
        _debug(`${func}: value = "${value}"; target =`, target);
        const db_id = Number(value);
        if (db_id) {
            dataRow(target).attr(ITEM_ATTR, db_id);
        } else {
            console.error(`${func}: invalid value:`, value);
        }
        return db_id || undefined;
    }

    /**
     * Remove the database ID for the ManifestItem associated with the target.
     *
     * @param {Selector} target
     */
    function removeManifestItemId(target) {
        const func = 'removeManifestItemId';
        _debug(`${func}: target =`, target);
        selfOrParent(target, `[${ITEM_ATTR}]`, func).removeAttr(ITEM_ATTR);
    }

    /**
     * Return the row associated with the given database ID.
     *
     * @param {string|number} id
     * @param {Selector}      [rows]    Default: {@link allDataRows}.
     *
     * @returns {jQuery|undefined}
     */
    function rowForManifestItem(id, rows) {
        const $rows = rows ? $(rows) : allDataRows();
        const $row  = $rows.filter(`[${ITEM_ATTR}="${id}"]`);
        if (isPresent($row)) { return $row }
    }

    // ========================================================================
    // Functions - database - ManifestItem fields
    // ========================================================================

    /**
     * @typedef {Object.<string,Properties>} PropertiesTable
     */

    let field_property;

    /**
     * All field names and properties
     *
     * @returns {PropertiesTable}
     */
    function fieldProperty() {
        return field_property ||= getFieldProperties();
    }

    /**
     * Find all field names and properties
     *
     * @returns {PropertiesTable}
     */
    function getFieldProperties() {
        _debug('getFieldProperties');
        const result = {};
        headerColumns().each((_, column) => {
            selfOrDescendents(column, `[${FIELD_ATTR}]`).each(function() {
                const prop    = new Field.Properties(this);
                const field   = prop.field || $(this).attr(FIELD_ATTR);
                result[field] = prop;
            });
        });
        _debug('getFieldProperties ->', result);
        if (isEmpty(result)) {
            _error('no field names could be extracted from the grid');
        }
        return result;
    }

    /**
     * Mapping of database field to related EMMA data field.
     *
     * @type {Object.<string,string>}
     */
    const FIELD_MAP = {
        repository: 'emma_repository',
    }

    /**
     * Extract a field value from a data object, translating between
     * database field and EMMA data field if necessary.
     *
     * @param {object} data
     * @param {string} field
     *
     * @returns {[*,string]|[]}
     */
    function valueAndField(data, field) {
        if (isMissing(data) || isMissing(field)) { return [] }
        if (hasKey(data, field)) { return [data[field], field] }
        let fld;
        $.each(FIELD_MAP, (name1, name2) => {
            if ((field === name1) && hasKey(data, name2)) {
                fld = name2;
            } else if ((field === name2) && hasKey(data, name1)) {
                fld = name1;
            }
            return !fld; // break loop if a data field was identified
        });
        return fld ? [data[fld], fld] : [];
    }

    // ========================================================================
    // Functions - page
    // ========================================================================

    /**
     * Position the page so that the title, controls and grid are all visible.
     *
     * If the URL has a hash, the indicated target item will be scrolled to the
     * center first before aligning the title to the top of the viewport.
     */
    function scrollToTop() {
        _debug('scrollToTop');
        const anchor = window.location.hash;
        if (anchor) { scrollToCenter(anchor) }
        $('#main')[0].scrollIntoView({block: 'start', inline: 'nearest'});
    }

    /**
     * Position the page so that indicated item is scrolled to the center of
     * the viewport.
     *
     * If target has an equals sign it's assumed to be an attribute/value pair
     * which is used to find the indicated item (e.g. "#data-item-id=18" will
     * result in the selector '[data-item-id="18"]`.
     *
     * @params {string} target
     */
    function scrollToCenter(target) {
        const func   = 'scrollToCenter'; _debug(`${func}: target =`, target);
        const anchor = target.trim().replace(/^#/, '');
        const parts  = anchor.split('=');
        let $target;
        if ((parts.length > 1) && !anchor.match(/^\[(.*)]$/)) {
            const attr  = parts.shift();
            const val   = parts.join('=').trim();
            const value = val.match(/^(["'])(.*)\1$/)?.at(2) || val;
            $target     = $(`[${attr}="${value}"]`);
        } else {
            $target     = $(`#${anchor}`);
        }
        if (isPresent($target)) {
            const $rows = dataRows();
            let $row    = $rows.filter($target);
            if (isMissing($row)) {
                const $cell = $rows.find($target);
                if (isPresent($cell)) {
                    $row = dataRow($cell);
                }
            }
            if (isPresent($row)) {
                $target = $row.children(CONTROLS_CELL);
            }
        }
        if (isPresent($target)) {
            $target[0].scrollIntoView({block: 'center', inline: 'start'});
        } else {
            _debug(`${func}: missing target =`, target);
        }
    }

    // ========================================================================
    // Functions - page - pagination values
    // ========================================================================

    let $item_counts, $page_items, $total_items;

    /**
     * The container for display of the number of rows on this page and the
     * total number of rows.
     *
     * @returns {jQuery}
     */
    function itemCounts() {
        return $item_counts ||= $container.find('.search-count');
    }

    /**
     * The element(s) displaying the number of rows on this page.
     *
     * @returns {jQuery}
     */
    function pageItems() {
        return $page_items ||= itemCounts().find('.page-items');
    }

    /**
     * The element(s) displaying the total number of rows.
     *
     * @returns {jQuery}
     */
    function totalItems() {
        return $total_items ||= itemCounts().find('.total-items');
    }

    /**
     * Get the displayed number of rows on this page.
     *
     * @returns {number}
     */
    function getPageItemCount() {
        const count = Number(pageItems().text());
        _debug('getPageItemCount: ', count);
        return count || 0;
    }

    /**
     * Set the displayed number of rows on this page.
     *
     * @param {number|string} value
     *
     * @returns {number}
     */
    function setPageItemCount(value) {
        _debug('setPageItemCount: value =', value);
        const count = Number(value) || 0;
        pageItems().text(count);
        return count;
    }

    /**
     * Get the displayed total number of rows.
     *
     * @returns {number}
     */
    function getTotalItemCount() {
        const count = Number(totalItems().text());
        _debug('getTotalItemCount: ', count);
        return count || 0;
    }

    /**
     * Set the displayed total number of rows.
     *
     * @param {number|string} value
     *
     * @returns {number}
     */
    function setTotalItemCount(value) {
        _debug('setTotalItemCount: value =', value);
        const count = Number(value) || 0;
        totalItems().text(count);
        return count;
    }

    /**
     * Change the number of rows displayed on the page.
     *
     * @param {number} increment
     */
    function changeItemCount(increment) {
        const func  = 'changeItemCount';
        //_debug(`${func}: increment =`, increment);
        let count  = getPageItemCount();
        let total  = getTotalItemCount();
        const step = Number(increment);
        if (step) {
            setPageItemCount( count += step);
            setTotalItemCount(total += step);
        } else {
            console.error(`${func}: invalid:`, increment);
        }
        const single = !(total > count);
        itemCounts().toggleClass('multi-page', !single);
        itemCounts().toggleClass('single-page', single);
    }

    // ========================================================================
    // Functions - page - communication status
    // ========================================================================

    /**
     * Name of the $grid data() entry indicating that the server appears to be
     * offline.
     *
     * @type {string}
     */
    const OFFLINE_DATA = 'offline';

    /**
     * Appended to tooltips when the server is offline. // TODO: I18n
     *
     * @type {string}
     */
    const NOT_CHANGEABLE = 'NOT CHANGEABLE WHILE THE SERVER IS OFFLINE';

    /**
     * Indicate whether the EMMA server appears to be available.
     *
     * @returns {boolean}
     */
    function isOnline() {
        return !isOffline();
    }

    /**
     * Indicate whether the EMMA server appears to be offline.
     *
     * @returns {boolean}
     */
    function isOffline() {
        return $grid.data(OFFLINE_DATA) || false;
    }

    /**
     * Change the display to indicate that the EMMA server is offline.
     *
     * @param {boolean} [setting]     If *false*, indicate not offline.
     */
    function setOffline(setting) {
        const offline    = (setting !== false);
        const is_offline = isOffline();
        _debug(`setOffline: ${is_offline} (setting = "${setting}")`);
        if (offline !== is_offline) {
            const $rows  = allDataRows();
            const note   = `\n${NOT_CHANGEABLE}`;
            const attrs  = ['disabled', 'readonly'];
            const inputs = 'button, input, textarea, select';
            let change_tip, change_attr;
            if (is_offline) {
                change_tip  = ($e, t) => $e.attr('title', t.replace(note, ''));
                change_attr = ($e, a) => $e.removeAttr(a);
            } else {
                change_tip  = ($e, t) => $e.attr('title', `${t}${note}`);
                change_attr = ($e, a) => $e.attr(a, true);
            }
            $rows.find('[title]').each(function() {
                const $element = $(this);
                change_tip($element, $element.attr('title'));
            });
            $rows.find(inputs).each(function() {
                const $input = $(this);
                attrs.forEach(a => change_attr($input, a));
            });
        }
        const marker = 'offline';
        $container.toggleClass(marker, offline);
        $container.find('.button-tray *').toggleClass(marker, offline);
        $comm_status.toggleClass(marker, offline);
        $grid.toggleClass(marker, offline);
        $grid.data(OFFLINE_DATA, offline);
    }

    // ========================================================================
    // Functions - page - server interface
    // ========================================================================

    /**
     * Post to a server ManifestItem endpoint.
     *
     * @param {string|string[]|SendOptions} ctr_act
     * @param {SendOptions}                 [send_options]
     *
     * @see serverSend
     */
    function serverItemSend(ctr_act, send_options) {
        const func = 'serverItemSend';
        const opt  = { ...send_options };
        opt.caller       ||= func;
        opt.onCommStatus ||= onCommStatus
        serverSend(ctr_act, opt);
    }

    /**
     * Post to a Manifest controller endpoint.
     *
     * @param {string|SendOptions} action
     * @param {SendOptions}        [send_options]
     *
     * @see serverBulkSend
     */
    function serverManifestSend(action, send_options) {
        const func = 'serverManifestSend';
        const opt  = { ...send_options };
        opt.caller       ||= func;
        opt.onCommStatus ||= onCommStatus
        serverBulkSend(action, opt);
    }

    /**
     * Throw up a flash message only the first time an offline comm status is
     * triggered.
     *
     * @param {boolean} online
     */
    function onCommStatus(online) {
        const offline = !online;
        const error   = offline && isOnline() && 'EMMA is offline'; // TODO: I18n
        if (error) { flashError(error) }
        setOffline(offline);
    }

    // ========================================================================
    // Functions - generic
    // ========================================================================

    /**
     * Return the class starting with the given base string or matching the
     * given pattern.
     *
     * @param {Selector}      target
     * @param {string|RegExp} base
     * @param {string}        [caller]  Name of caller (for diagnostics).
     *
     * @returns {string|undefined}
     */
    function getClass(target, base, caller) {
        //_debug(`getClass: ${base} for target =`, target);
        const func    = caller || 'getClass';
        const $target = single(target, func);
        if (isMissing($target)) {
            _error(`${func}: no target element`);
        } else {
            const classes = Array.from($target[0].classList);
            let matches;
            if (base instanceof RegExp) {
                matches = classes.filter(c => base.test(c));
            } else {
                matches = classes.filter(c => c.startsWith(base));
            }
            return matches[0];
        }
    }

    /**
     * Replace the element's CSS class whose name starts with _{base}*_ with
     * the CSS class _{base}{value}_.
     *
     * @param {Selector} target
     * @param {string}   base
     * @param {*}        value
     * @param {string}   [caller]     Name of caller (for diagnostics).
     */
    function replaceClass(target, base, value, caller) {
        //_debug(`replaceClass: ${base}${value} for target =`, target);
        const func    = caller || 'replaceClass';
        const $target = single(target, func);
        if (isMissing($target)) {
            _error(`${func}: no target element`);
        } else {
            const classes   = Array.from($target[0].classList);
            const old_class = classes.filter(c => c.startsWith(base));
            $target.removeClass(old_class).addClass(`${base}${value}`);
        }
    }

    /**
     * Return the target if it is a checkbox or all descendents that are
     * checkboxes.
     *
     * @param {Selector} target
     * @param {boolean}  [checked]    Limit results by checked status.
     *
     * @returns {jQuery}
     */
    function checkboxes(target, checked) {
        //_debug(`checkboxes: checked = "${checked}"; target =`, target);
        const $result = selfOrDescendents(target, '[type="checkbox"]');
        if (isDefined(checked)) {
            return $result.filter(checked ? ':checked' : ':not(:checked)');
        }
        return $result;
    }

    // ========================================================================
    // Functions - other
    // ========================================================================

    /**
     * Infer media type based on the nature of the data.
     *
     * @param {string} data
     *
     * @returns {string}
     */
    function dataType(data) {
        switch (true) {
            case isEmpty(data):         return 'text';
            case /^\s*[{[]/.test(data): return 'json';
            case /^\s*</.test(data):    return 'xml';
            default:                    return 'csv';
        }
    }

    /**
     * Create a Value in the context of the jQuery object unless the argument
     * is already a Value object.
     *
     * @param {*}          v
     * @param {Properties} [prop]     Def: element's associated properties
     *
     * @returns {Value}
     */
    jQuery.fn.makeValue = function(v, prop) {
        let field;
        if (v instanceof Field.Value) {
            return v;
        } else if (prop) {
            return new Field.Value(v, prop);
        } else if ((field = this.attr(FIELD_ATTR))) {
            return new Field.Value(v, fieldProperty()[field]);
        } else {
            return new Field.Value(v, cellProperties(this));
        }
    };

    // ========================================================================
    // Functions - diagnostics
    // ========================================================================

    /**
     * Indicate whether console debugging is active.
     *
     * @returns {boolean}
     */
    function _debugging() {
        return AppDebug.activeFor(MODULE, DEBUG);
    }

    /**
     * Emit a console message if debugging.
     *
     * @param {...*} args
     */
    function _debug(...args) {
        _debugging() && console.log(`${MODULE}:`, ...args);
    }

    /**
     * Emit a console error and display as a flash error if debugging.
     *
     * @param {string} caller
     * @param {string} [message]
     */
    function _error(caller, message) {
        const msg = compact([MODULE, caller, message]).join(': ');
        console.error(msg);
        _debugging() && flashError(msg);
    }

    // noinspection JSUnusedLocalSymbols
    /**
     * This is a convenience function that can be added to check all data()
     * values for an element and its descendents.
     *
     * @note Not conditional on _debugging() -- not for normal debug output.
     *
     * @param {jQuery}   $root
     * @param {string}   [leader]     Leading tag for console output.
     * @param {string[]} [names]      data() names
     */
    function _debugWantNoDataValues($root, leader, names = [
        ACTIVE_CELL_DATA,
        CELL_VALID_DATA,
        CURRENT_VALUE_DATA,
        DB_DELTA_DATA,
        DB_ROW_DATA,
        DELTA_TABLE_DATA,
        LOOKUP_DATA,
        OFFLINE_DATA,
        ORIGINAL_VALUE_DATA,
        ROW_CHANGED_DATA,
        UPLOADER_DATA,
        VALUE_CHANGED_DATA,
    ]) {
        const tag = leader ? `${leader} ` : '';
        names.forEach(name => {
            const v = $root.data(name);
            if (isDefined(v)) {
                console.error(`${tag} | ${name} =`, v);
            }
        });
        $root.find('*').toArray().map(e => $(e)).forEach($e => {
            names.forEach(name => {
                const v = $e.data(name);
                if (isDefined(v)) {
                    console.error(`${tag} ${$e[0].className} | ${name} =`, v);
                }
            });
        });
    }

    // noinspection JSUnusedLocalSymbols
    /**
     * This is a convenience function for annotating a tooltip with .data()
     * values for the cell.
     *
     * @param {jQuery.Event|UIEvent|Selector} arg
     */
    function _debugDataValuesTooltip(arg) {
        const target   = arg?.currentTarget || arg?.target || arg;
        const $display = cellDisplay(target);
        const tooltip  = [];
        tooltip.push(`ORIGINAL: "${cellOriginalValue($display)}"`);
        tooltip.push(`CURRENT:  "${cellCurrentValue($display)}"`);
        tooltip.push(`CHANGED:  "${cellChanged($display)}"`);
        if (dataCell($display).attr('title')?.endsWith(NOT_CHANGEABLE)) {
            tooltip.push(NOT_CHANGEABLE);
        }
        $display.attr('title', tooltip.join("\n"));
    }

    // ========================================================================
    // Event handlers
    // ========================================================================

    // Title editing.
    handleClickAndKeypress($title_edit,   onBeginTitleEdit);
    handleClickAndKeypress($title_update, onUpdateTitleEdit);
    handleClickAndKeypress($title_cancel, onCancelTitleEdit);
    handleEvent($title_input, 'keydown',  onTitleEditKeypress);

    // Main control buttons.
    handleClickAndKeypress($save,   saveUpdates);
    handleClickAndKeypress($cancel, cancelUpdates);
    handleClickAndKeypress($export, exportRows);
    handleEvent($import, 'change',  importRows);

    // Grid display toggles.
    handleClickAndKeypress(headerRowToggle(),      onToggleHeaderRow);
    handleClickAndKeypress(controlsColumnToggle(), onToggleControlsColumn);

    // Cell editing.
    windowEvent('focus',     deregisterActiveCell, true);
    windowEvent('mousedown', deregisterActiveCell, true);
    onPageExit(deregisterActiveCell, _debugging());

    // ========================================================================
    // Actions
    // ========================================================================

    // Setup bibliographic lookup first so that linkages are in place before
    // setupLookup() executes.
    LookupModal.initializeAll();

    initializeEditForm();

});
