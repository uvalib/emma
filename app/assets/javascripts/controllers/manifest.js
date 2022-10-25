// app/assets/javascripts/controllers/manifest.js


import { Api }                        from '../shared/api'
import { arrayWrap }                  from '../shared/arrays'
import { Emma }                       from '../shared/assets'
import { pageAction, pageController } from '../shared/controller'
import { selector }                   from '../shared/css'
import * as Field                     from '../shared/field'
import { LookupModal }                from '../shared/lookup-modal'
import { compact, deepFreeze }        from '../shared/objects'
import { randomizeName }              from '../shared/random'
import { camelCase, singularize }     from '../shared/strings'
import { MultiUploader }              from '../shared/uploader'
import { cancelAction }               from '../shared/url'
import {
    isDefined,
    isEmpty,
    isMissing,
    isPresent,
    notDefined,
    presence,
} from '../shared/definitions'
import {
    handleClickAndKeypress,
    handleEvent,
    onPageExit,
} from '../shared/events'
import {
    addFlashError,
    clearFlash,
    flashError,
    flashMessage,
} from '../shared/flash'


// noinspection SpellCheckingInspection, FunctionTooLongJS
$(document).on('turbolinks:load', function() {

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
     * Manifest
     *
     * @typedef {{
     *      id:         string,
     *      user_id:    string,
     *      name:       string,
     *      created_at: string,
     *      updated_at: string,
     * }} Manifest
     */

    /**
     * ManifestItem
     *
     * @note rem_complete is not passed as a boolean
     *
     * @see ManifestItemData
     *
     * @typedef {{
     *      id:                     number,
     *      manifest_id:            string,
     *      row:                    number,
     *      delta:                  number,
     *      editing:                boolean,
     *      deleting:               boolean,
     *      last_saved?:            string,
     *      last_lookup?:           string,
     *      last_submit?:           string,
     *      created_at:             string,
     *      updated_at:             string,
     *      data_status:            string,
     *      file_status:            string,
     *      ready_status:           string,
     *      file_data?:             object,
     *      repository:             string,
     *      emma_publicationDate:   singleString,
     *      emma_formatFeature:     multiString,
     *      emma_version:           singleString,
     *      bib_series:             singleString,
     *      bib_seriesType:         singleString,
     *      bib_seriesPosition:     singleString,
     *      dc_title:               singleString,
     *      dc_creator:             multiString,
     *      dc_identifier:          multiString,
     *      dc_publisher:           singleString,
     *      dc_relation:            multiString,
     *      dc_language:            multiString,
     *      dc_rights:              singleString,
     *      dc_description:         singleString,
     *      dc_format:              singleString,
     *      dc_type:                singleString,
     *      dc_subject:             multiString,
     *      dcterms_dateAccepted:   singleString,
     *      dcterms_dateCopyright:  singleString,
     *      s_accessibilityFeature: multiString,
     *      s_accessibilityControl: multiString,
     *      s_accessibilityHazard:  multiString,
     *      s_accessMode:           multiString,
     *      s_accessModeSufficient: multiString,
     *      s_accessibilitySummary: singleString,
     *      rem_source:             singleString,
     *      rem_metadataSource:     multiString,
     *      rem_remediatedBy:       multiString,
     *      rem_complete:           singleString,
     *      rem_coverage:           singleString,
     *      rem_remediatedAspects:  multiString,
     *      rem_textQuality:        singleString,
     *      rem_status:             singleString,
     *      rem_remediationDate:    singleString,
     *      rem_comments:           singleString,
     *      backup?:                object,
     * }} ManifestItem
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
     * @typedef {{
     *      items: {
     *          properties: RecordMessageProperties,
     *          list:       ManifestItem[],
     *          valid?:     boolean[],
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
     * FinishEditResponse
     *
     * @see "ManifestItemConcern#finish_editing"
     *
     * @typedef {{
     *     items:     ManifestItemTable|null|undefined,
     *     pending?:  ManifestItemTable|null|undefined,
     *     problems?: MessageTable|null|undefined,
     * }} FinishEditResponse
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
    const TITLE_FORM_CLASS      = `mini-form`;
    const TITLE_UPDATE_CLASS    = `update`;
    const TITLE_CANCEL_CLASS    = `cancel`;

    const CONTAINER_CLASS       = 'manifest-grid-container';
    const SUBMIT_CLASS          = 'submit-button';
    const CANCEL_CLASS          = 'cancel-button';
    const IMPORT_CLASS          = 'import-button';
    const EXPORT_CLASS          = 'export-button';
    const COMM_STATUS_CLASS     = 'comm-status';
    const GRID_CLASS            = 'manifest_item-grid';
    const CTRL_EXPANDED_MARKER  = 'controls-expanded';
    const HEAD_EXPANDED_MARKER  = 'head-expanded';
    const DISABLED_MARKER       = 'disabled';
    const HIDDEN_MARKER         = 'hidden';
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
    const TITLE_FORM    = selector(TITLE_FORM_CLASS);
    const TITLE_UPDATE  = selector(TITLE_UPDATE_CLASS);
    const TITLE_CANCEL  = selector(TITLE_CANCEL_CLASS);

    const CONTAINER     = selector(CONTAINER_CLASS);
    const SUBMIT        = selector(SUBMIT_CLASS);
    const CANCEL        = selector(CANCEL_CLASS);
    const IMPORT        = selector(IMPORT_CLASS);
    const EXPORT        = selector(EXPORT_CLASS);
    const COMM_STATUS   = selector(COMM_STATUS_CLASS);
    const GRID          = selector(GRID_CLASS);
    //const DISABLED    = selector(DISABLED_MARKER);
    const HIDDEN        = selector(HIDDEN_MARKER);
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
     * Current controller.
     *
     * @readonly
     * @type {string}
     */
    const PAGE_ACTION = pageAction();

    /**
     * Current controller.
     *
     * @readonly
     * @type {string}
     */
    const PAGE_CONTROLLER = pageController();

    /**
     * Base name (singular of the related database table).
     *
     * @readonly
     * @type {string}
     */
    const PAGE_MODEL = singularize(PAGE_CONTROLLER);

    /**
     * Page assets.js properties.
     *
     * @readonly
     * @type {ModelProperties}
     */
    const PAGE_PROPERTIES = Emma[camelCase(PAGE_MODEL)];

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
    const $title_form    = $title_heading.find(TITLE_FORM);
    const $title_input   = $title_form.find('input[name="name"]');
    const $title_update  = $title_form.find(TITLE_UPDATE);
    const $title_cancel  = $title_form.find(TITLE_CANCEL)

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

    // noinspection FunctionWithInconsistentReturnsJS
    /**
     * Allow ENTER to work as "Change" and ESC to work as "Keep".
     *
     * @param {jQuery.Event|KeyboardEvent} event
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
    function initialize() {
        _debug('initialize');
        setTimeout(scrollToTop, 0);
        initializeControlButtons();
        initializeAllDataRows();
        initializeGrid();
        validateForm();         // Want to initialize validation data...
        updateFormValid(false); // ...but don't want to start with Save enabled
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
        submit: $save,
        cancel: $cancel,
        import: $import,
        export: $export,
    };

    /**
     * Symbolic button names.
     *
     * @type {string[]}
     */
    const CONTROL_BUTTON_TYPES = Object.keys(CONTROL_BUTTONS);

    /**
     * initializeControlButtons
     */
    function initializeControlButtons() {
        if (_debugging()) {
            const func = 'initializeControlButtons';
            _debug(func);
            $.each(CONTROL_BUTTONS, (type, $button) => {
                if (isMissing($button)) {
                    _error(`${func}: no button for "${type}"`);
                }
            });
        }
    }

    /**
     * Enable/disable the Save button.
     *
     * @param {boolean} [setting]     If *false*, disable the button.
     */
    function enableSave(setting) {
        //_debug(`enableSave: setting = "${setting}"`);
        const enable = (setting !== false);
        enableControlButton('submit', enable);
    }

    /**
     * Enable/disable the Export button.
     *
     * @param {boolean} [setting]     If *false*, disable the button.
     */
    function enableExport(setting) {
        //_debug(`enableExport: setting = "${setting}"`);
        const enable = (setting !== false);
        enableControlButton('export', enable);
    }

    /**
     * Change control button state.
     *
     * @param {string}  type          One of {@link CONTROL_BUTTON_TYPES}.
     * @param {boolean} [enable]
     */
    function enableControlButton(type, enable) {
        if (_debugging()) {
            const func = 'enableControlButton';
            _debug(`${func}: type = "${type}"; enable = "${enable}"`);
            if (!CONTROL_BUTTON_TYPES.includes(type)) {
                console.error(`${func}: "${type}" not in`, CONTROL_BUTTONS);
            }
        }
        const enabling  = isDefined(enable) ? enable : checkFormValidation();
        const $button   = CONTROL_BUTTONS[type];
        const config    = PAGE_PROPERTIES.Action || {};
        const action    = config[PAGE_ACTION] || config.new || {};
        const state_cfg = action[type] || {};
        const new_state = enabling ? state_cfg.enabled : state_cfg.disabled;
        if (new_state?.label)   { $button.text(new_state.label) }
        if (new_state?.tooltip) { $button.attr('title', new_state.tooltip) }
        $button.toggleClass(DISABLED_MARKER, !enabling);
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
        const func     = 'saveUpdates';
        const manifest = manifestId();
        _debug(`${func}: event =`, event);

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
                enableSave(false);
                updateDbRowValues(data);
                allDataCells().removeClass(STATUS_MARKERS);
                flashMessage('Changes saved.');
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
        const func     = 'cancelUpdates';
        const manifest = manifestId();
        const finalize = () => cancelAction($cancel);
        _debug(`${func}: event =`, event);

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
        const func = 'importRows';
        _debug(`${func}: event =`, event);
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
        const func     = 'importData';
        const manifest = manifestId();
        const action   = `bulk/create/${manifest}`;
        const type     = dataType(data);
        const content  = 'multipart/form-data';
        const accept   = 'text/html';
        _debug(`${func}: from "${filename}": type = "${type}"; data =`, data);

        if (!manifest) {
            _error(`${func}: no manifest ID`);
            return;
        }

        serverSend(action, {
            caller:     func,
            params:     { data: data, type: type },
            headers:    { 'Content-Type': content, Accept: accept },
            onSuccess:  processReceivedItems,
        });

        /**
         * Append ManifestItems returned from the server.
         *
         * @param {ManifestRecordMessage} body
         *
         * @see "ManifestItemController#bulk_update_response"
         * @see "SerializationConcern#index_values"
         */
        function processReceivedItems(body) {
            _debug(`${func}: body =`, body);
            const data = body?.items || body || {};
            const list = data.list;
            if (isEmpty(data)) {
                _error(func, 'no response data');
            } else if (isEmpty(list)) {
                _error(func, 'no items present in response data');
            } else {
                appendRows(list, data.valid);
            }
        }
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
        const func     = 'reImportData';
        const manifest = manifestId();
        const action   = `bulk/update/${manifest}`;
        _error(`${func}: ${action} TO BE IMPLEMENTED`); // TODO: reimport
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
        flashMessage('EXPORT - TO BE IMPLEMENTED'); // TODO: exportRows
    }

    // ========================================================================
    // Functions - form - validation
    // ========================================================================

    /**
     * Determine the form is in a state where updates can be persisted and
     * update controls accordingly.
     *
     * @returns {boolean}
     */
    function validateForm() {
        _debug('validateForm');
        const ready = validateGrid();
        return updateFormValid(ready);
    }

    /**
     * Update form controls based on form validity.
     *
     * @param {boolean} [setting]     Default: {@link checkFormValidation}.
     *
     * @returns {boolean}             Validation status.
     */
    function updateFormValid(setting) {
        _debug(`updateFormValid: setting = ${setting}`);
        const ready = isDefined(setting) ? setting : checkFormValidation();
        enableSave(ready);
        enableExport(ready);
        return ready;
    }

    /**
     * Check whether the grid is in a state where a save is permitted.
     *
     * @param {Selector} [target]
     *
     * @returns {boolean}             Form readiness.
     */
    function checkFormValidation(target) {
        //_debug('checkFormValidation: target =', target);
        return checkGridValidation(target);
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
        });
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
        const config    = Emma.Grid.row;
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
        const config    = Emma.Grid.column;
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
    // Functions - grid - validation
    // ========================================================================

    /**
     * Determine the row(s) are in a state where updates can be persisted.
     *
     * @param {Selector} [target]     Default: {@link allDataRows}
     *
     * @returns {boolean}             Validation status.
     */
    function validateGrid(target) {
        _debug('validateGrid: target =', target);
        const update_row = (valid, row) => validateDataRow(row) && valid;
        return dataRows(target).toArray().reduce(update_row, true);
    }

    /**
     * Check row validation to indicate whether the grid is in a state where a
     * save is permitted.
     *
     * (No stored data values are updated.)
     *
     * @param {Selector} [target]     Default: {@link allDataRows}
     *
     * @returns {boolean}             Validation status.
     */
    function checkGridValidation(target) {
        //_debug('checkGridValidation: target =', target);
        const check_row = (valid, row) => valid && checkRowValidation(row);
        return dataRows(target).toArray().reduce(check_row, true);
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
     * Indicate whether the given row is an empty row which has never cause the
     * creation of a database item.
     *
     * @param {Selector} target
     *
     * @returns {boolean}
     */
    function blankDataRow(target) {
        return !databaseId(target);
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
     * @param {Selector}    target
     * @param {ManifestItem} data
     */
    function updateDataRow(target, data) {
        const func = 'updateDataRow';
        _debug(`${func}: data =`, data, 'target =', target);
        if (isEmpty(data)) { return }
        const $row = dataRow(target);

        if (isPresent(data.id)) {
            const db_id = databaseId($row) || setDatabaseId($row, data.id);
            if (db_id !== data.id) {
                _error(func,`row item ID = ${db_id} but data.id = ${data.id}`);
                return;
            }
        }
        if (data.hasOwnProperty('row')) {
            setDbRowValue($row, data.row);
        }
        if (data.hasOwnProperty('delta')) {
            setDbRowDelta($row, data.delta);
        }
        if (data.deleting) {
            console.error(`${func}: received deleted item:`, data);
        }

        let changed, row_valid = true;
        dataCells($row).each((_, cell) => {
            let different;
            const $cell = $(cell);
            const field = cellDbColumn($cell);
            if (field && data.hasOwnProperty(field)) {
                const old_value = cellCurrentValue($cell);
                const new_value = $cell.makeValue(data[field]);
                if ((different = new_value.differsFrom(old_value))) {
                    changed   = true;
                    row_valid = updateDataCell($cell, new_value) && row_valid;
                }
            }
            if (!different) {
                if (cellChanged($cell)) {
                    changed   = true;
                    row_valid = validateDataCell($cell) && row_valid;
                } else {
                    row_valid &&= checkCellValidation($cell);
                }
            }
        });
        if (changed) {
            updateRowValid($row, row_valid);
            updateFormValid();
        }

        updateRowIndicators($row, data);
        updateRowDetails($row, data);
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
     * @param {Selector} target
     *
     * @returns {jQuery}
     */
    function initializeDataRow(target) {
        //_debug('initializeDataRow: target =', target);
        const $row = dataRow(target);
        initDbRowValue($row);
        initDbRowDelta($row);
        setupRowEventHandlers($row);
        return $row;
    }

    /**
     * setupRowEventHandlers
     *
     * @param {Selector} [target]     Default: {@link allDataRows}.
     */
    function setupRowEventHandlers(target) {
        _debug('setupRowEventHandlers: target =', target);
        const $row = target && dataRow(target);
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
    // Functions - row - controls
    // ========================================================================

    /**
     * Name of the attribute indicating the action of a control button.
     *
     * @type {string}
     */
    const ACTION_ATTR = 'data-action';

    /**
     * Attach handlers for row control icon buttons.
     *
     * @param {Selector} [target]     Default: all {@link rowControls}.
     */
    function setupRowOperations(target) {
        _debug('setupRowOperations: target =', target);
        const $cell     = controlsColumn(target);
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
        const target   = event.currentTarget || event.target;
        const $control = $(target);
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
     * @param {boolean}      [renumber]     Default: *true*.
     *
     * @returns {jQuery}                    The new row.
     */
    function insertRow(after, data, renumber) {
        _debug('insertRow after', after);
        let $new;
        if (after) {
            const $row = dataRow(after);
            $new = emptyDataRow($row);
            $new.insertAfter($row);
        } else {
            $new = emptyDataRow();
            $new.attr('id', 'manifest_item-item-1');
            $grid.children('tbody').prepend($new);
        }
        if (isPresent(data)) {
            updateDataRow($new, data);
        }
        if (renumber !== false) {
            incrementItemCount();
            updateGridRowIndexes();
        }
        return $new;
    }

    /**
     * Insert new row(s) after the last row in the grid.
     *
     * @param {ManifestItem[]} list
     * @param {boolean[]}      [validity]
     * @param {boolean}        [renumber]   Default: *true*.
     */
    function appendRows(list, validity, renumber) {
        _debug('appendRows: list =', list);
        const items = arrayWrap(list);
        const valid = validity || [];
        const $last = allDataRows().last();

        let $row; // When undefined, first insertRow starts with $template_row.
        if (databaseId($last)) {
            $row = $last;   // Insert after last row.
        } else if (isPresent($last)) {
            $last.remove(); // Discard empty row.
        }
        const row = dbRowValue($row);
        let delta = dbRowDelta($row);
        items.forEach((record, idx) => {
            $row = insertRow($row, record, false);
            setDbRowValue($row, row);
            setDbRowDelta($row, ++delta);
            if (isDefined(valid[idx])) {
                updateRowValid($row, valid[idx]);
            }
        });
        if (renumber !== false) {
            incrementItemCount(items.length);
            updateGridRowIndexes();
        }
    }

    // ========================================================================
    // Functions - row - delete
    // ========================================================================

    /**
     * Mark the indicated row for deletion.
     *
     * If it is a blank row (not yet associated with a ManifestItem) then it is
     * removed directly; otherwise request that the associated ManifestItem
     * record be marked for deletion.
     *
     * @param {Selector} target
     * @param {boolean}  [commit]     If *false* do not update database.
     * @param {boolean}  [renumber]   Default: *true*.
     */
    function deleteRow(target, commit, renumber) {
        const func = 'deleteRow'; _debug(`${func}: target =`, target);
        const $row = dataRow(target);

        // Mark row for deletion.
        if ($row.is(TO_DELETE)) {
            _debug(`${func}: already marked ${TO_DELETE} -`, $row);
        } else {
            $row.addClass(TO_DELETE_MARKER);
        }

        if (commit !== false) {
            const db_id = databaseId($row);
            if (db_id) {
                sendDeleteRecords(db_id, renumber);
            } else {
                _debug(`${func}: removing blank row -`, $row);
                removeGridRow($row, renumber);
            }
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
     * @param {boolean}                 [commit]    If *false* do not update db
     * @param {boolean}                 [renumber]  Default: *true*.
     */
    function deleteRows(list, commit, renumber) {
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
                const db_id = databaseId($row);
                if (!db_id) {
                    blanks.push($row);
                }
                return db_id;
            }).filter(v => v);

        // Mark rows for deletion.
        blanks.forEach($row => deleteRow($row, false));
        db_ids.forEach(db_id => {
            const $row = rowForDatabaseId(db_id, $rows);
            if ($row) {
                deleteRow($row, false);
            } else {
                _debug(`${func}: no row for db_id ${db_id}`);
            }
        });

        if (commit !== false) {
            if (isPresent(blanks)) {
                _debug(`${func}: removing blank rows -`, blanks);
                removeGridRows($(blanks), renumber);
            }
            if (isPresent(db_ids)) {
                sendDeleteRecords(db_ids, renumber);
            }
            if (_debugging() && isEmpty([...blanks, ...db_ids])) {
                _debug(`${func}: nothing to do`);
            }
        }
    }

    /**
     * Cause the server to delete the indicated ManifestItem records.
     *
     * @param {number|number[]} items
     * @param {boolean}         [renumber]   Default: *true*.
     */
    function sendDeleteRecords(items, renumber) {
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

        serverSend(action, {
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
                removeDeletedRows(list, renumber);
            }
        }
    }

    /**
     * Respond to deletion of ManifestItems by removing their associated rows.
     *
     * @param {(ManifestItem|number)[]} list
     * @param {boolean}                 [renumber]  Default: *true*.
     */
    function removeDeletedRows(list, renumber) {
        const func    = 'removeDeletedRows'; _debug(`${func}: list =`, list);
        const $rows   = allDataRows();
        const $marked = $rows.filter(TO_DELETE);
        const marked  = compact($marked.toArray().map(e => databaseId(e)));
        const db_ids  = arrayWrap(list).map(r => isDefined(r?.id) ? r.id : r);

        // Mark rows for deletion if not already marked.
        db_ids.forEach(db_id => {
            const $row = rowForDatabaseId(db_id, $rows);
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
                const $row = rowForDatabaseId(db_id, $rows);
                $row?.removeClass(TO_DELETE_MARKER);
            });
            console.warn(`${func}: not deleted:`, undeleted);
        }

        // It is assumed that any blank rows have already been marked (or have
        // already been removed).
        removeGridRows($rows.filter(TO_DELETE), renumber);
    }

    /**
     * Delete the indicated grid rows.
     *
     * @param {Selector} rows
     * @param {boolean}  [renumber]   Default: *true*.
     */
    function removeGridRows(rows, renumber) {
        _debug('removeGridRows: rows =', rows);
        const $rows = dataRows(rows);
        destroyGridRowElements($rows, renumber);
    }

    /**
     * Remove the indicated single grid data row.
     *
     * @param {Selector} target
     * @param {boolean}  [renumber]   Default: *true*.
     */
    function removeGridRow(target, renumber) {
        _debug('removeGridRow: item =', target);
        const $row = dataRow(target);
        destroyGridRowElements($row, renumber);
    }

    /**
     * Remove row element(s) from the grid.
     *
     * The elements are hidden first in order to allow the re-render to happen
     * all at once.
     *
     * @param {jQuery}  $rows
     * @param {boolean} [renumber]    Default: *true*.
     */
    function destroyGridRowElements($rows, renumber) {
        //_debug('destroyGridRowElements: $rows =', $rows);
        const row_count = $rows.length;
        $rows.addClass(HIDDEN_MARKER);
        $rows.each((_, row) => removeFromControlsColumnToggle(row));
        $rows.remove();
        if (renumber !== false) {
            decrementItemCount(row_count);
            updateGridRowIndexes();
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
     * @param {Selector} target
     */
    function lookupRow(target) {
        _debug('lookupRow: target =', target);
        const lookup = getLookup(target);
        if (lookup) {
            lookup.toggleModal();
        } else {
            console.error('No LookupModal for', target);
        }
        _error('LOOKUP - TO BE IMPLEMENTED'); // TODO: bibliographic lookup
    }

    /**
     * The lookup button for the given row.
     *
     * @param {Selector} row
     *
     * @returns {jQuery}
     */
    function lookupButton(row) {
        return rowControls(row).filter(`[${ACTION_ATTR}="lookup"]`);
    }

    /**
     * Get the lookup instance for the row.
     *
     * @param {Selector} row
     *
     * @returns {LookupModal|undefined}
     */
    function getLookup(row) {
        const $row    = dataRow(row);
        const $button = lookupButton($row);
        return LookupModal.instanceFor($button);
    }

    /**
     * Create a new lookup instance.
     *
     * @param {Selector} row
     *
     * @returns {LookupModal|undefined}
     */
    function newLookup(row) {
        //_debug('newLookup: row =', row);
        const $button = lookupButton(row);
        LookupModal.setup($button, onLookupStart, onLookupComplete).then(
            result => _debug('lookup loaded:', (result || 'OK')),
            reason => console.warn('lookup failed:', reason)
        );

        /**
         * Invoked to update search terms when the popup opens.
         *
         * @param {jQuery}  $toggle
         * @param {boolean} check_only
         * @param {boolean} [halted]
         *
         * @returns {boolean|undefined}
         *
         * @see onShowModalHook
         */
        function onLookupStart($toggle, check_only, halted) {
            _debug('LOOKUP START for $toggle', $toggle);
            if (check_only || halted) { return }
            //clearSearchResultsData($toggle);
            //setSearchTermsData($toggle);
            //setOriginalValues($toggle);
            _debug('TODO: bibliographic lookup'); // TODO: bibliographic lookup
        }

        /**
         * Invoked to update form fields when the popup closes.
         *
         * @param {jQuery}  $toggle
         * @param {boolean} check_only
         * @param {boolean} [halted]
         *
         * @returns {boolean|undefined}
         *
         * @see onHideModalHook
         */
        function onLookupComplete($toggle, check_only, halted) {
            _debug('LOOKUP COMPLETE for $toggle', $toggle);
            if (check_only || halted) { return }
            _error('TODO: bibliographic lookup'); // TODO: bibliographic lookup
        }
    }

    /**
     * initLookup
     *
     * @param {Selector} row
     */
    function initLookup(row) {
        //_debug('initLookup: row =', row);
        const $row = dataRow(row);
        if (!getLookup($row)) {
            newLookup($row);
        }
    }

    /**
     * Initialize bibliographic lookup for each grid row.
     *
     * @param {Selector} [target]
     */
    function setupLookup(target) {
        _debug('setupLookup: target =', target);
        if (target) {
            dataRows(target).each((_, row) => initLookup(row));
        } else {
            LookupModal.initializeAll();
        }
    }

    // ========================================================================
    // Functions - row - uploader
    // ========================================================================

    /**
     * ManifestItemData
     *
     * @see ManifestItem
     *
     * @typedef {{
     *      id?:            number,
     *      manifest_id?:   string,
     *      row?:           number,
     *      delta?:         number,
     *      editing?:       boolean,
     *      deleting?:      boolean,
     *      last_saved?:    string,
     *      last_lookup?:   string,
     *      last_submit?:   string,
     *      created_at?:    string,
     *      updated_at?:    string,
     *      data_status?:   string,
     *      file_status?:   string,
     *      ready_status?:  string,
     *      repository?:    string,
     *      backup?:        object,
     * } & EmmaData} ManifestItemData
     */

    /**
     * @typedef { ManifestItemData | { error: string } } ManifestItemDataOrError
     */

    /**
     * Flag controlling overall console debug output.
     *
     * @readonly
     * @type {boolean|undefined}
     */
    const DEBUGGING = true;

    /**
     * Name of the data() entry for a row's uploader instance.
     *
     * @type {string}
     */
    const UPLOADER_DATA = 'uploader';

    /**
     * Base name (singular of the related database table).
     *
     * @readonly
     * @type {string}
     */
    const ROW_MODEL = 'manifest_item';

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
        const func     = 'newUploader'; //_debug(`${func}: row =`, row);
        // noinspection JSUnusedGlobalSymbols
        const cbs      = { onSelect, onStart, onError, onSuccess };
        const $row     = $(row);
        const instance = new MultiUploader($row, ROW_MODEL, FEATURES, cbs);
        let name_shown;
        if (instance.isUppyInitialized()) {
            instance.$root.find(MultiUploader.FILE_SELECT).remove();
            instance.$root.find(MultiUploader.DISPLAY).empty();
        }
        // noinspection JSValidateTypes
        return instance.initialize();

        /**
         * Callback invoked when the file select button is pressed.
         *
         * @param {jQuery.Event} [event]    Ignored.
         */
        function onSelect(event) {
            clearFlash();
            if (!manifestId()) {
                _debug(`${func}: triggering manifest creation`);
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
            clearFlash();
            name_shown = instance.isFilenameDisplayed();
            if (name_shown) { instance.hideFilename() }
            return compact({
                id:          databaseId($row),
                row:         dbRowValue($row),
                delta:       dbRowDelta($row),
                manifest_id: manifestId(),
            });
        }

        /**
         * This event occurs when the response from POST /manifest_item/upload
         * is received with a failure status (4xx).
         *
         * @param {Uppy.UppyFile}                  file
         * @param {Error}                          error
         * @param {{status: number, body: string}} [response]
         */
        function onError(file, error, response) {
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
         * @param {Uppy.UppyFile}       file
         * @param {UppyResponseMessage} response
         *
         * @see "Shrine::UploadEndpointExt#make_response"
         */
        function onSuccess(file, response) {

            const body = response.body  || {};
            let error  = undefined;

            // Extract uploaded EMMA metadata.
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
    }

    /**
     * Create a new uploader instance if not already present for the row.
     *
     * @param {Selector} row
     */
    function initUploader(row) {
        //_debug('initUploader: row =', row);
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
        dataRows(target).each((_, row) => initUploader(row));
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
        const $row  = dataRow(target, true);
        const value = Number(setting) || 0;
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
    function initDbRowValue(target) {
        const $row = dataRow(target, true);
        const attr = $row.attr(DB_ROW_ATTR);
        if (attr) {
            $row.removeAttr(DB_ROW_ATTR);
            return setDbRowValue($row, attr);
        } else {
            return dbRowValue($row);
        }
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
        const $row  = dataRow(target, true);
        const value = Number(setting) || 0;
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
    function initDbRowDelta(target) {
        const $row = dataRow(target, true);
        const attr = $row.attr(DB_DELTA_ATTR);
        if (attr) {
            $row.removeAttr(DB_DELTA_ATTR);
            return setDbRowDelta($row, attr);
        } else {
            return dbRowDelta($row);
        }
    }

    /**
     * Replace item row/delta values.
     *
     * @param {ManifestItemTable} table
     *
     * @see "ManifestController#row_table"
     */
    function updateDbRowValues(table) {
        const func = 'updateDbRowValues';
        _debug(`${func}: table =`, table);
        allDataRows().each((_, row) => {
            const $row  = $(row);
            const db_id = databaseId($row);
            const entry = db_id && table[db_id];
            if (isMissing(db_id)) {
                _debug(`${func}: no db_id for $row =`, $row);
            } else if (isEmpty(entry)) {
                _debug(`${func}: no response data for db_id ${db_id}`);
            } else if (typeof entry === 'number') {
                setDbRowValue($row, entry);
                setDbRowDelta($row, 0);
            } else {
                setDbRowValue($row, entry.row);
                setDbRowDelta($row, entry.delta);
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
     * @param {object|undefined} data
     *
     * @returns {object}
     */
    function statusData(data) {
        if (isEmpty(data)) { return {} }
        const pairs = STATUS_TYPES.map(type => [type, presence(data[type])]);
        return compact(Object.fromEntries(pairs));
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
     * All indicator value elements for the row.
     *
     * @param {Selector} target
     *
     * @returns {jQuery}
     */
    function rowIndicators(target) {
        const $row = dataRow(target);
        return $row.find(`${CONTROLS_CELL} ${INDICATORS} ${INDICATOR}`);
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
            if (field && data.hasOwnProperty(field)) {
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
    // Functions - row - validity state
    // ========================================================================

    /**
     * Name of the data() entry indicating whether the data row is invalid.
     *
     * @type {string}
     */
    const ROW_VALID_DATA = 'valid';

    /**
     * Indicate whether all of the cells of the related data row are valid.
     *
     * An undefined result means that the row hasn't been evaluated.
     *
     * @param {Selector} target
     *
     * @returns {boolean|undefined}
     */
    function rowValid(target) {
        return dataRow(target).data(ROW_VALID_DATA);
    }

    /**
     * Set the related data row's valid state.
     *
     * @param {Selector} target
     * @param {boolean}  [setting]    If *false*, make invalid.
     *
     * @returns {boolean}
     */
    function setRowValid(target, setting) {
        //_debug(`setRowValid: "${setting}"; target =`, target);
        const $row  = dataRow(target)
        const valid = (setting !== false);
        $row.data(ROW_VALID_DATA, valid);
        return valid;
    }

    /**
     * Change the related data row's validity status.
     *
     * @param {Selector} target
     * @param {boolean}  setting
     *
     * @returns {boolean}
     */
    function updateRowValid(target, setting) {
        _debug(`updateRowValid: "${setting}"; target =`, target);
        const $row  = dataRow(target)
        const valid = setRowValid($row, setting);
        $row.toggleClass(ERROR_MARKER, !valid);
        return valid;
    }

    // ========================================================================
    // Functions - row - validation
    // ========================================================================

    /**
     * Update validity information and display for the associated data row and
     * all of its data cells.
     *
     * @param {Selector} target
     *
     * @returns {boolean}
     */
    function validateDataRow(target) {
        _debug('validateDataRow: target =', target);
        const $row     = dataRow(target);
        const validate = (valid, cell) => validateDataCell(cell) && valid;
        const valid    = dataCells($row).toArray().reduce(validate, true);
        return updateRowValid($row, (valid || false));
    }

    /**
     * Consult row .data() to determine if the row is valid and only attempt to
     * re-evaluate if that result is false.
     *
     * (No changes are made to element attributes or data.)
     *
     * @param {Selector} target
     *
     * @returns {boolean}
     */
    function checkRowValidation(target) {
        //_debug('checkRowValidation: target =', target);
        const $row  = dataRow(target);
        const valid = rowValid($row);
        if (isDefined(valid)) {
            return valid;
        } else {
            const check = (valid, cell) => valid && checkCellValidation(cell);
            return dataCells($row).toArray().reduce(check, true);
        }
    }

    // noinspection JSUnusedLocalSymbols
    /**
     * Evaluate whether all of a row's data cells are valid.
     *
     * (No changes are made to element attributes or data.)
     *
     * @param {Selector} target
     *
     * @returns {boolean}
     */
    function performRowValidation(target) {
        _debug('performRowValidation: target =', target);
        const $row     = dataRow(target);
        const validate = (valid, cell) => valid && performCellValidation(cell);
        return dataCells($row).toArray().reduce(validate, true);
    }

    // ========================================================================
    // Functions - row - creation
    // ========================================================================

    /**
     * CSS classes for the data cell which indicate the status of the data.
     *
     * @type {string[]}
     */
    const STATUS_MARKERS = [EDITING_MARKER, CHANGED_MARKER, ERROR_MARKER];

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
     * The {@link DB_ID_ATTR} attribute is removed so that editing logic knows
     * this is a row unrelated to any ManifestItem record.
     *
     * @param {Selector} [original]   Source data row.
     *
     * @returns {jQuery}
     */
    function emptyDataRow(original) {
        _debug('emptyDataRow: original =', original);
        const $copy = cloneDataRow(original);
        $copy.removeClass(STATUS_MARKERS);
        removeDatabaseId($copy);
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

        //_debugWantNoDataValues($copy, '$copy'); // TODO: remove - debugging

        // If the row is being inserted after an inserted row look to the
        // original row for information.
        const row   = dbRowValue($row) || 0;
        const delta = nextDeltaCounter(row);
        setDbRowValue($copy, row);
        setDbRowDelta($copy, delta);

        // Make numbered attributes unique for the row element itself and all
        // of the elements within it.
        uniqAttrs($copy, delta);
        $copy.find('*').each((_, element) => uniqAttrs(element, delta));
        $copy.removeClass(HIDDEN_MARKER);

        // Hook up event handlers.
        setupRowEventHandlers($copy);

        return $copy;
    }

    /**
     * HTML attributes which should be made unique.
     *
     * @see https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input [input]
     * @see https://developer.mozilla.org/en-US/docs/Web/HTML/Element/label [label]
     * @see https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA/Attributes#relationship_attributes [aria]
     *
     * @type {string[]}
     */
    const ID_ATTRIBUTES = [
        'aria-activedescendant',
        'aria-controls',
        'aria-describedby',
        'aria-details',
        'aria-errormessage',
        'aria-flowto',
        'aria-labelledby',
        'aria-owns',
        'for',                      // @see [label]#attr-for
        'form',                     // @see [input]#form
        'id',                       // @see [input]#id
        'list',                     // @see [input]#list
      //'name',                     // @note Must *not* be included.
    ];

    /**
     * Make numbered attributes unique within an element.
     *
     * @param {Selector}      element
     * @param {string|number} unique
     * @param {string[]}      attrs
     */
    function uniqAttrs(element, unique, attrs = ID_ATTRIBUTES) {
        const $element = $(element);
        attrs.forEach(name => {
            const old_attr = $element.attr(name);
            const new_attr = old_attr && uniqAttr(old_attr, unique);
            if (new_attr) { $element.attr(name, new_attr) }
        });
    }

    /**
     * Make a numbered attribute value unique.
     *
     * @param {string}        old_attr
     * @param {string|number} unique
     *
     * @returns {string}
     */
    function uniqAttr(old_attr, unique) {
        if (/-0$/.test(old_attr)) { // An attribute from $template_row.
            return old_attr.replace(/-0$/, `-${unique}`);
        } else if (/-\d+-\d+$/.test(old_attr)) {
            return old_attr.replace(/-\d+$/, `-${unique}`);
        } else {
            return `${old_attr}-${unique}`;
        }
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
     * Get the database ManifestItem table column associated with the target.
     * *
     * @param {Selector} target
     * *
     * @returns {string}
     */
    function cellDbColumn(target) {
        return dataCell(target).attr(FIELD_ATTR);
    }

    /**
     * Get the properties of the field associated with the target.
     * *
     * @param {Selector} target
     * *
     * @returns {Properties}
     */
    function cellProperties(target) {
        const field  = cellDbColumn(target);
        const result = fieldProperty()[field];
        if (!result) {
            _error(`cellProperties: no entry for "${field}"`);
        }
        return result || {};
    }

    /**
     * Use received data to update cell(s) associated with data values.
     *
     * @param {Selector} target
     * @param {Value}    value
     * @param {boolean}  [change]   Default: check {@link cellOriginalValue}
     *
     * @returns {boolean}           Result of {@link validateDataCell}.
     */
    function updateDataCell(target, value, change) {
        _debug('updateDataCell: value =', value, target);
        const $cell = dataCell(target);
        setCellCurrentValue($cell, value);
        setCellDisplayValue($cell, value);
        let changed = change;
        if (notDefined(changed)) {
            changed = value.differsFrom(cellOriginalValue($cell));
        }
        updateCellChanged($cell, changed);
        return validateDataCell($cell);
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
     * @param {Selector} target
     *
     * @returns {jQuery}
     */
    function initializeDataCell(target) {
        //_debug('initializeDataCell: target =', target);
        const $cell = dataCell(target).removeClass(STATUS_MARKERS);
        if ($cell.is(MultiUploader.UPLOADER)) {
            $cell.find(MultiUploader.FILE_NAME).empty();
        } else {
            clearCellDisplay($cell);
            clearCellEdit($cell);
        }
        updateCellDisplayValue($cell);
        validateDataCell($cell);
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
     * @param {Selector} target
     *
     * @returns {boolean|undefined}
     */
    function cellChanged(target) {
        return dataCell(target).data(VALUE_CHANGED_DATA);
    }

    /**
     * Set the related data cell's changed state.
     *
     * @param {Selector} target
     * @param {boolean}  [setting]    Default: *true*.
     *
     * @returns {boolean}
     */
    function setCellChanged(target, setting) {
        _debug(`setCellChanged: "${setting}"; target =`, target);
        const $cell   = dataCell(target);
        const changed = (setting !== false);
        $cell.data(VALUE_CHANGED_DATA, changed);
        return changed;
    }

    /**
     * Set the related data cell's changed state to 'undefined'.
     *
     * @param {Selector} target
     */
    function clearCellChanged(target) {
        _debug('clearCellChanged: target =', target);
        dataCell(target).removeData(VALUE_CHANGED_DATA);
    }

    /**
     * Change the related data cell's changed status.
     *
     * @param {Selector} target
     * @param {boolean}  setting
     *
     * @returns {boolean}
     */
    function updateCellChanged(target, setting) {
        _debug(`updateCellChanged: "${setting}"; target =`, target);
        const $cell   = dataCell(target);
        const changed = setCellChanged($cell, setting);
        $cell.toggleClass(CHANGED_MARKER, changed);
        return changed;
    }

    // ========================================================================
    // Functions - cell - invalid state
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
     * An undefined result means that the row hasn't been evaluated.
     *
     * @param {Selector} target
     *
     * @returns {boolean|undefined}
     */
    function cellValid(target) {
        return dataCell(target).data(CELL_VALID_DATA);
    }

    /**
     * Set the related data cell's valid state.
     *
     * @param {Selector} target
     * @param {boolean}  [setting]    If *false*, make invalid.
     *
     * @returns {boolean}
     */
    function setCellValid(target, setting) {
        //_debug(`setCellValid: "${setting}"; target =`, target);
        const $cell = dataCell(target);
        const valid = (setting !== false);
        $cell.data(CELL_VALID_DATA, valid);
        return valid;
    }

    /**
     * Change the related data cell's validity status.
     *
     * @param {Selector} target
     * @param {boolean}  setting
     *
     * @returns {boolean}
     */
    function updateCellValid(target, setting) {
        //_debug(`updateCellValid: "${setting}"; target =`, target);
        const $cell = dataCell(target);
        const valid = setCellValid($cell, setting);
        $cell.toggleClass(ERROR_MARKER, !valid);
        return valid;
    }

    // ========================================================================
    // Functions - cell - validation
    // ========================================================================

    /**
     * Update data cell validity information and display.
     *
     * @param {Selector} target
     *
     * @returns {boolean}
     */
    function validateDataCell(target) {
        //_debug('validateDataCell: target =', target);
        const $cell = dataCell(target);
        const valid = performCellValidation($cell);
        return updateCellValid($cell, valid);
    }

    /**
     * Consult cell .data() to determine if the cell is valid and only attempt
     * to re-evaluate if that result is false.
     *
     * (No changes are made to element attributes or data.)
     *
     * @param {Selector} target
     *
     * @returns {boolean}
     */
    function checkCellValidation(target) {
        //_debug('checkCellValidation: target =', target);
        const $cell = dataCell(target);
        const valid = cellValid($cell);
        return isDefined(valid) ? valid : performCellValidation($cell);
    }

    /**
     * Evaluate the current value of the associated data cell to determine
     * whether it is acceptable.
     *
     * (No changes are made to element attributes or data.)
     *
     * @param {Selector} target
     * @param {Value}    [current]    Default: {@link cellCurrentValue}.
     *
     * @returns {boolean}
     */
    function performCellValidation(target, current) {
        //_debug('performCellValidation: target =', target);
        const $cell = dataCell(target);
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
     * @param {Selector} target
     * *
     * @returns {Value|undefined}
     */
    function cellOriginalValue(target) {
        return dataCell(target).data(ORIGINAL_VALUE_DATA);
    }

    /**
     * Assign the original value for the associated cell.
     *
     * @param {Selector} target
     * @param {Value|*}  new_value
     *
     * @returns {Value}
     */
    function setCellOriginalValue(target, new_value) {
        //_debug('setCellOriginalValue: new_value =', new_value, target);
        const $cell = dataCell(target);
        const value = $cell.makeValue(new_value);
        $cell.data(ORIGINAL_VALUE_DATA, value);
        return value;
    }

    /**
     * Initialize the original value for the associated cell.
     *
     * @param {Selector} target
     * @param {Value}    value
     *
     * @returns {Value}
     */
    function initCellOriginalValue(target, value) {
        //_debug('initCellOriginalValue: value =', value, target);
        const $cell = dataCell(target);
        return cellOriginalValue($cell) || setCellOriginalValue($cell, value);
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
     * @param {Selector} target
     * *
     * @returns {Value|undefined}
     */
    function cellCurrentValue(target) {
        return dataCell(target).data(CURRENT_VALUE_DATA);
    }

    /**
     * Assign the current value for the associated cell.
     *
     * @param {Selector} target
     * @param {Value|*}  new_value
     *
     * @returns {Value}
     */
    function setCellCurrentValue(target, new_value) {
        //_debug('setCellCurrentValue: new_value =', new_value, target);
        const $cell = dataCell(target);
        const value = $cell.makeValue(new_value);
        $cell.data(CURRENT_VALUE_DATA, value);
        return value;
    }

    /**
     * Initialize the current value for the associated cell.
     *
     * @param {Selector} target
     * @param {Value}    value
     *
     * @returns {Value}
     */
    function initCellCurrentValue(target, value) {
        //_debug('initCellCurrentValue: value =', value, target);
        const $cell = dataCell(target);
        return cellCurrentValue($cell) || setCellCurrentValue($cell, value);
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
        cellDisplay(target).empty();
    }

    // ========================================================================
    // Functions - cell - display - value
    // ========================================================================

    /**
     * Get the displayed value for a data cell.
     *
     * @param {Selector} target
     * *
     * @returns {Value}
     */
    function cellDisplayValue(target) {
        const $cell = dataCell(target);
        const text  = cellDisplay($cell).text();
        const value = $cell.makeValue(text);
        initCellOriginalValue($cell, value);
        initCellCurrentValue($cell, value);
        return value;
    }

    /**
     * Set the displayed value for a data cell.
     *
     * @param {Selector} target
     * @param {Value}    new_value
     */
    function setCellDisplayValue(target, new_value) {
        //_debug('setCellDisplayValue: new_value =', new_value, target);
        const $cell  = dataCell(target);
        const $value = cellDisplay($cell);
        if (notDefined(new_value)) {
            $value.text('');
        } else {
            const value = $cell.makeValue(new_value);
            const list  = $cell.is('.textbox');
            $value.html(list ? value.toHtml() : value.forDisplay(true));
        }
    }

    /**
     * Refresh the cell display according to the data type.
     *
     * @param {Selector} target
     * @param {Value}    [new_value]    Default: from {@link cellDisplay}.
     */
    function updateCellDisplayValue(target, new_value) {
        //_debug('updateCellDisplayValue: new_value =', new_value, target);
        const $cell = dataCell(target);
        let value;
        if (isDefined(new_value)) {
            value = $cell.makeValue(new_value);
        } else {
            value = cellDisplayValue($cell);
        }
        setCellDisplayValue($cell, value);
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
     * @param {Selector} target
     */
    function clearCellEdit(target) {
        //_debug('clearCellEdit: target =', target);
        const $edit = cellEdit(target);
        editClear($edit);
    }

    /**
     * Get the input value for a data cell.
     *
     * @param {Selector} target
     * *
     * @returns {Value}
     */
    function cellEditValue(target) {
        const $edit = cellEdit(target);
        const value = editGet($edit);
        return $edit.makeValue(value);
    }

    /**
     * Set the input value for a data cell.
     *
     * @param {Selector} target
     * @param {Value}    [new_value]  Default from displayed value.
     */
    function setCellEditValue(target, new_value) {
        //_debug('setCellEditValue: new_value =', new_value, target);
        const $cell = dataCell(target);
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
     * Respond to click within a data cell value.
     *
     * @param {jQuery.Event|UIEvent} event
     */
    function onStartValueEdit(event) {
        _debug('onStartValueEdit: event =', event);
        const target = event.currentTarget || event.target;
        const $cell  = dataCell(target);
        startValueEdit($cell);
        cellEdit($cell).focus();
        // TODO: move the caret to the perceived location of the mouse click
    }

    /**
     * Begin editing a cell.
     *
     * @param {Selector} target
     */
    function startValueEdit(target) {
        const func  = 'startValueEdit';
        const $cell = dataCell(target);
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
     * @param {Selector} target
     *
     * @see "ManifestItemController#start_edit"
     */
    function postStartEdit(target) {
        const func = 'postStartEdit';
        if (!manifestId()) {
            _debug(`${func}: triggering manifest creation`);
            createManifest();
            return;
        }

        const $cell = dataCell(target);
        const $row  = dataRow($cell);
        const db_id = databaseId($row);
        if (!db_id) {
            _debug(`${func}: no db_id for $row =`, $row);
            return;
        }

        _debug(`${func}: $row = `, $row);
        const row   = dbRowValue($row);
        const delta = dbRowDelta($row);
        serverSend(`start_edit/${db_id}`, {
            params:     { row: row, delta: delta },
            onError:    () => finishValueEdit($cell),
            caller:     func,
        });
    }

    /**
     * End editing a cell.
     *
     * @param {Selector} target
     */
    function finishValueEdit(target) {
        const func  = 'finishValueEdit';
        const $cell = dataCell(target);
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
     * @param {Selector} target
     * @param {Value}    [new_value]  Default from displayed value.
     */
    function cellEditBegin(target, new_value) {
        _debug('cellEditBegin: new_value =', new_value, target);
        const $cell = dataCell(target);
        setCellEditValue($cell, new_value);
        registerActiveCell($cell);
    }

    /**
     * Transition a data cell out of edit mode.
     *
     * @param {Selector} target
     *
     * @returns {Value|undefined}
     */
    function cellEditEnd(target) {
        _debug('cellEditEnd: target =', target);
        const $cell     = dataCell(target);
        const old_value = cellCurrentValue($cell); // || cellOriginalValue($cell);
        const new_value = cellEditValue($cell);
        if (new_value.differsFrom(old_value)) {
            const row_validity  = rowValid($cell);
            const cell_validity = updateDataCell($cell, new_value);
            if (cell_validity !== row_validity) {
                validateDataRow($cell);
                updateFormValid();
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
     * @param {Selector}        target
     * @param {Value|undefined} new_value
     *
     * @see "ManifestItemController#start_edit"
     */
    function postFinishEdit(target, new_value) {
        const func     = 'postFinishEdit';
        const $cell    = dataCell(target);
        const $row     = dataRow($cell);
        const db_id    = databaseId($row);
        const manifest = manifestId();

        if (!manifest) {
            _error(`${func}: no manifest ID`);
            return;
        }

        /** @type {SendOptions} */
        const options  = {};
        let action, params;
        if (isDefined(new_value)) {
            const field = cellDbColumn($cell);
            const row   = dbRowValue($row);
            const delta = dbRowDelta($row);
            params = { row: row, delta: delta, [field]: new_value.toString() };
            params = { manifest_item: params };
        }
        _debug(`${func}: params =`, params);
        if (db_id) {
            action = `finish_edit/${db_id}`;
            options.onSuccess = (body => parseFinishEditResponse($cell, body));
        } else if (params) {
            action = `create/${manifest}`;
            options.onSuccess = (body => parseCreateResponse($cell, body));
        }
        if (action) {
            options.params = params || {};
            options.caller = func;
            serverSend(action, options);
        }
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
        const db_id  = databaseId($row);
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
            $.each(pending, (id, record) => {
                const $row = isPresent(record) && rowForDatabaseId(id, $rows);
                if ($row) { updateRowIndicators($row, record) }
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
            clr: ($e)    => checkboxes($e).removeProp('checked'),
            get: ($e)    => checkboxes($e, true).toArray().map(e => e.value),
            set: ($e, v) => {
                const cbs = checkboxes($e).toArray();
                const set = new Set(v.toArray());
                cbs.forEach(cb => $(cb).prop('checked', set.has(cb.value)));
            },
        },
        checkbox: {
            clr: ($e)    => $e.removeProp('checked'),
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
     * @param {Selector} target
     */
    function setActiveCell(target) {
        const func = 'setActiveCell';
        const cell = dataCell(target)[0];
        if (cell) {
            _debug(`${func}: target =`, target);
            $grid.data(ACTIVE_CELL_DATA, cell);
        } else {
            console.error(`${func}: empty target =`, target);
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
     * @param {Selector} target
     */
    function registerActiveCell(target) {
        _debug('registerActiveCell: target =', target);
        deregisterActiveCell();
        setActiveCell(target);
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
            const $cell = event?.target && dataCell(event.target);
            // If focus is going somewhere other than within the data cell
            // currently being edited then that editing instance is done.
            if ($cell && ($cell[0] === $active[0])) {
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
     * @param {Selector} target
     * @param {boolean}  [setting]    If *false*, unset edit mode.
     */
    function setCellEditMode(target, setting) {
        //_debug(`setCellEditMode: setting = "${setting}"; target =`, target);
        const editing = (setting !== false)
        dataCell(target).toggleClass(EDITING_MARKER, editing);
    }

    /**
     * inCellEditMode
     *
     * @param {Selector} target
     *
     * @returns {boolean}
     */
    function inCellEditMode(target) {
        return dataCell(target).is(EDITING);
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
    // Functions - display - data rows
    // ========================================================================

    // ========================================================================
    // Functions - database - Manifest
    // ========================================================================

    /**
     * Name of the attribute indicating the ID of the Manifest database record
     * associated with an element or its ancestor.
     *
     * @type {string}
     */
    const MANIFEST_ATTR = 'data-manifest';

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
     * Name of the attribute indicating the ID of the ManifestItem database
     * record associated with an element or its ancestor.
     *
     * @type {string}
     */
    const DB_ID_ATTR = 'data-item-id';

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
    function databaseId(target) {
        const value = attribute(target, DB_ID_ATTR);
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
    function setDatabaseId(target, value) {
        const func = 'setDatabaseId';
        _debug(`${func}: value = "${value}"; target =`, target);
        const db_id = Number(value);
        if (db_id) {
            dataRow(target).attr(DB_ID_ATTR, db_id);
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
    function removeDatabaseId(target) {
        const func = 'removeDatabaseId'; _debug(`${func}: target =`, target);
        selfOrParent(target, `[${DB_ID_ATTR}]`, func).removeAttr(DB_ID_ATTR);
    }

    /**
     * Return the row associated with the given database ID.
     *
     * @param {string|number} value
     * @param {Selector}      [rows]    Default: {@link allDataRows}.
     *
     * @returns {jQuery|undefined}
     */
    function rowForDatabaseId(value, rows) {
        const $rows = rows ? $(rows) : allDataRows();
        const $row  = $rows.filter(`[${DB_ID_ATTR}="${value}"]`);
        if (isPresent($row)) { return $row }
    }

    // ========================================================================
    // Functions - database - ManifestItem fields
    // ========================================================================

    /**
     * @typedef {Object.<string,Properties>} PropertiesTable
     */

    let field_property; //, field_map;

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
     * Extract the names of data fields from the header row.
     *
     * @returns {string[]}
     */
/*
    function fieldNames() {
        return Object.keys(fieldProperty());
    }
*/

    /**
     * Mapping of comparison name to actual field name.
     *
     * @returns {StringTable}
     */
/*
    function fieldMap() {
        return field_map ||= getFieldMap();
    }
*/

    /**
     * Mapping of allowable column names to the actual field name.
     *
     * @type {StringTable}
     */
/*
    const COLUMN_MAP = {
        'isbn': 'dc_identifier',
        'issn': 'dc_identifier',
        'doi':  'dc_identifier',
        'oclc': 'dc_identifier',
        'lccn': 'dc_identifier',
    };
*/

    /**
     * Make a mapping of comparison name to actual field name.
     *
     * @returns {StringTable}
     */
/*
    function getFieldMap() {
        _debug('getFieldMap');
        const pairs = fieldNames().map(f => [comparisonName(f), f]);
        let result  = Object.fromEntries(pairs);
        $.extend(result, COLUMN_MAP);
        _debug('getFieldMap ->', result);
        return result;
    }
*/

    /**
     * Transform the given name to a valid field name.
     *
     * @param {string} name
     *
     * @returns {string|undefined}
     */
/*
    function getFieldName(name) {
        //_debug(`getFieldName: name = ${name}`);
        const result = fieldMap()[comparisonName(name)];
        result || _debug(`getFieldName: invalid name "${name}"`);
        return result;
    }
*/

    /**
     * Transform into a normalized name for case-insensitive comparison.
     *
     * @param {string} field_name
     *
     * @returns {string}
     */
/*
    function comparisonName(field_name) {
        //_debug(`comparisonName: field_name = ${field_name}`);
        return field_name.trim().toLowerCase().replaceAll(/_/g, '');
    }
*/

    // ========================================================================
    // Functions - page
    // ========================================================================

    /**
     * Position the page so that the title, controls and grid are all visible.
     */
    function scrollToTop() {
        _debug('scrollToTop');
        $('#main')[0].scrollIntoView({block: 'start', inline: 'nearest'});
    }

    // ========================================================================
    // Functions - page - pagination values
    // ========================================================================

    let $page_items, $total_items;

    /**
     * The element(s) displaying the number of rows on this page.
     *
     * @returns {jQuery}
     */
    function pageItems() {
        return $page_items ||= $container.find('.search-count .page-items');
    }

    /**
     * The element(s) displaying the total number of rows.
     *
     * @returns {jQuery}
     */
    function totalItems() {
        return $total_items ||= $container.find('.search-count .total-items');
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
    function stepItemCount(increment) {
        //_debug('stepItemCount: increment =', increment);
        const page_count  = getPageItemCount();
        const total_count = getTotalItemCount();
        setPageItemCount(page_count + increment);
        setTotalItemCount(total_count + increment);
    }

    /**
     * Increase the number of rows displayed on the page.
     *
     * @param {number} [by]           Default: 1
     */
    function incrementItemCount(by) {
        _debug('incrementItemCount: by =', by);
        const step = by && Number(by) || 1;
        stepItemCount(step);
    }

    /**
     * Decrease the number of rows displayed on the page.
     *
     * @param {number} [by]           Default: 1
     */
    function decrementItemCount(by) {
        _debug('decrementItemCount: by =', by);
        const step = by && Number(by) || 1;
        stepItemCount((step > 0) ? -step : step);
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

    const MANIFEST_CONTROLLER = 'manifest';
    const ROW_CONTROLLER      = ROW_MODEL;

    let api_server;

    /**
     * The server controller for most operations.
     *
     * @returns {string}
     */
    function apiController() {
        return ROW_CONTROLLER;
    }

    /**
     * Interface to the server.
     *
     * @param {string}       [controller]   Default: {@link apiController}.
     * @param {XmitCallback} [callback]
     *
     * @returns {Api}
     */
    function server(controller, callback) {
        if (controller || callback) {
            const ctrlr   = controller || apiController();
            const options = callback ? { callback: callback } : {};
            return new Api(ctrlr, options);
        } else {
            return api_server ||= new Api(apiController());
        }
    }

    /**
     * SendOptions
     *
     * Option values for the {@link serverSend} function.
     *
     * @typedef {{
     *      _ignoreBody?:   boolean,
     *      method?:        string,
     *      controller?:    string,
     *      action?:        string,
     *      params?:        Object.<string,any>,
     *      headers?:       StringTable,
     *      caller?:        string,
     *      onSuccess?:     XmitCallback,
     *      onError?:       XmitCallback,
     *      onComplete?:    XmitCallback,
     * }} SendOptions
     */

    /**
     * Post to a server endpoint.
     *
     * @param {string|string[]|SendOptions} ctr_act
     * @param {SendOptions}                 [send_options]
     *
     * @overload serverSend(controller_action, send_options)
     *  Controller/action followed by options.
     *  @param {string[]}    ctr_act
     *  @param {SendOptions} [send_options]
     *
     * @overload serverSend(action, send_options)
     *  Action followed by options (optionally specifying controller).
     *  @param {string}      ctr_act
     *  @param {SendOptions} [send_options]
     *
     * @overload serverSend(send_options)
     *  Options which specify action (and optionally controller).
     *  @param {SendOptions} [send_options]
     */
    function serverSend(ctr_act, send_options) {
        const func = 'serverSend';
        let ctrlr, action, opt;
        if (Array.isArray(ctr_act))      { [ctrlr, action] = ctr_act } else
        if (typeof ctr_act === 'string') { action = ctr_act }          else
        if (typeof ctr_act === 'object') { opt    = ctr_act }
        opt    ||= send_options || {};
        action ||= opt.action;
        ctrlr  ||= opt.controller;

        const params   = opt.params  || {};
        const headers  = opt.headers || {};
        const options  = { headers: headers };
        const cb_ok    = opt.onSuccess;
        const cb_err   = opt.onError;
        const cb_done  = opt.onComplete;
        const caller   = compact([opt.caller, func]).join(': ');
        const callback = (result, warning, error, xhr) => {
            if (_debugging()) {
                _debug(`${caller}: result =`, result);
                warning && _debug(`${caller}: warning =`, warning);
                error   && _debug(`${caller}: error   =`, error);
                xhr     && _debug(`${caller}: xhr     =`, xhr);
            }
            let cbs = [cb_done];
            let [err, warn, offline] = [error, warning, !xhr.status];
            if (offline) {
                // Throw up a flash message only the first time triggered.
                err = warn = isOnline() && 'EMMA is offline'; // TODO: I18n
            } else if (error) {
                cbs = [cb_err, ...cbs];
            } else if (warning) {
                cbs = [cb_err, ...cbs];
            } else {
                cbs = [cb_ok, ...cbs];
            }
            if (err || warn) { err ? flashError(err) : flashMessage(warn) }
            cbs.forEach(cb => cb?.(result, warn, err, xhr));
            setOffline(offline);
        }
        if (_debugging()) {
            _debug(`${caller}: ctrlr   = "${ctrlr || apiController()}"`);
            _debug(`${caller}: action  = "${action}"`);
            _debug(`${caller}: params  =`, params);
            _debug(`${caller}: options =`, options);
        }
        if (action) {
            const method = opt.method?.toUpperCase() || 'POST';
            options._ignoreBody = opt._ignoreBody;
            server(ctrlr).xmit(method, action, params, options, callback);
        } else {
            _error(`${caller}: no action given`);
        }
    }

    /**
     * Post to a 'manifest' controller endpoint.
     *
     * @param {string|SendOptions} action
     * @param {SendOptions}        [send_options]
     */
    function serverManifestSend(action, send_options) {
        const func       = 'serverManifestSend';
        const controller = MANIFEST_CONTROLLER;
        const override   = send_options?.controller;
        if (typeof action !== 'string') {
            console.error(`${func}: invalid action`, action);
        } else if (override && (override !== controller)) {
            console.warn(`${func}: ignored controller override "${override}"`);
        }
        serverSend([controller, action], send_options);
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

    /**
     * Return the target if it matches or all descendents that match.
     *
     * @param {Selector} target
     * @param {Selector} match
     *
     * @returns {jQuery}
     */
    function selfOrDescendents(target, match) {
        //_debug(`selfOrDescendents: match = "${match}"; target =`, target);
        const $target = $(target);
        return $target.is(match) ? $target : $target.find(match);
    }

    /**
     * The attribute value which applies to the given target (either directly
     * or from a parent element).
     *
     * @param {Selector} target
     * @param {string}   name         Attribute name.
     *
     * @returns {string}
     */
    function attribute(target, name) {
        const func = 'attribute';
        //_debug(`${func}: name = ${name}; target =`, target);
        return selfOrParent(target, `[${name}]`, func).attr(name);
    }

    /**
     * Return the target if it matches or the first parent that matches.
     *
     * @param {Selector} target
     * @param {Selector} match
     * @param {string}   [caller]     Name of caller (for diagnostics).
     *
     * @returns {jQuery}
     */
    function selfOrParent(target, match, caller) {
        const func = caller || 'selfOrParent';
        const $t   = $(target);
        return $t.is(match) ? single($t, func) : $t.parents(match).first();
    }

    /**
     * Ensure that the target resolves to exactly one element.
     *
     * @param {Selector} target
     * @param {string}   [caller]     Name of caller (for diagnostics).
     *
     * @returns {jQuery}
     */
    function single(target, caller) {
        const $element = $(target);
        const count    = $element.length;
        if (count === 1) {
            return $element;
        } else {
            console.warn(`${caller}: ${count} results; 1 expected`);
            return $element.first();
        }
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
        return window.DEBUG.activeFor('Manifest', true);
    }

    /**
     * Emit a console message if debugging.
     *
     * @param {...*} args
     */
    function _debug(...args) {
        _debugging() && console.log(...args);
    }

    /**
     * Emit a console error and display as a flash error if debugging.
     *
     * @param {string} caller
     * @param {string} [message]
     */
    function _error(caller, message) {
        const msg = isDefined(message) ? `${caller}: ${message}` : caller;
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
        ROW_VALID_DATA,
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
    window.addEventListener('focus',     deregisterActiveCell, true);
    window.addEventListener('mousedown', deregisterActiveCell, true);
    onPageExit(deregisterActiveCell, _debugging());

    // ========================================================================
    // Actions
    // ========================================================================

    initialize();

});
