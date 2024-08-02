// app/assets/javascripts/controllers/manifest-edit.js


import { AppDebug }                        from "../application/debug";
import { appSetup }                        from "../application/setup";
import { handleClickAndKeypress }          from "../shared/accessibility";
import { arrayWrap }                       from "../shared/arrays";
import { Emma }                            from "../shared/assets";
import { pageAttributes }                  from "../shared/controller";
import { HIDDEN, selector, toggleHidden }  from "../shared/css";
import * as Field                          from "../shared/field";
import { turnOffAutocompleteIn }           from "../shared/form";
import { InlinePopup }                     from "../shared/inline-popup";
import { keyCombo }                        from "../shared/keyboard";
import { LookupModal }                     from "../shared/lookup-modal";
import { LookupRequest }                   from "../shared/lookup-request";
import { ModalHideHooks, ModalShowHooks }  from "../shared/modal-hooks";
import { randomizeName }                   from "../shared/random";
import { pluralize }                       from "../shared/strings";
import { timestamp }                       from "../shared/time";
import { asParams, cancelAction, makeUrl } from "../shared/url";
import {
    isDefined,
    isEmpty,
    isMissing,
    isPresent,
    notDefined,
    presence,
} from "../shared/definitions";
import {
    delayedBy,
    handleEvent,
    handleHoverAndFocus,
    isEvent,
    onPageExit,
    windowEvent,
} from "../shared/events";
import {
    addFlashError,
    clearFlash,
    flashError,
    flashMessage,
} from "../shared/flash";
import {
    initializeGridNavigation,
    updateGridNavigation,
} from "../shared/grids";
import {
    ID_ATTRIBUTES,
    htmlEncode,
    sameElements,
    selfOrDescendents,
    selfOrParent,
    single,
    uniqAttrsTree,
} from "../shared/html";
import {
    ITEM_ATTR,
    ITEM_MODEL,
    MANIFEST_ATTR,
    attribute,
    buttonFor,
    enableButton,
    initializeButtonSet,
    serverBulkSend,
    serverSend,
} from "../shared/manifests";
import {
    CONTROL_GROUP,
    CellControlGroup,
    CheckboxGroup,
    MenuGroup,
    NavGroup,
    SingletonGroup,
    TextInputGroup,
} from "../shared/nav-group";
import {
    compact,
    deepDup,
    hasKey,
    isObject,
    toObject,
} from "../shared/objects";
import {
    FILE_SELECT,
    UPLOADER,
    UPLOADED_NAME,
    MultiUploader,
} from "../shared/uploader";


const MODULE = "ManifestEdit";
const DEBUG  = true;

AppDebug.file("controllers/manifest-edit", MODULE, DEBUG);

// noinspection SpellCheckingInspection, FunctionTooLongJS
appSetup(MODULE, function() {

    /**
     * Manifest creation page.
     *
     * @type {jQuery}
     */
    const $body = $('body.manifest:not(.select)').filter('.new, .edit');

    // Only perform these actions on the appropriate pages.
    if (isMissing($body)) { return }

    /**
     * Console output functions for this module.
     */
    const OUT = AppDebug.consoleLogging(MODULE, DEBUG);

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
     * @property {object}  field_error
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
     * @property {object}       [field_error]
     */

    /**
     * @typedef {Object.<number,ManifestItem>} ManifestItemTable
     *
     * ManifestItem record values per record ID.
     */

    /**
     * @typedef {Object.<string,(string|string[])>} MessageTable
     *
     * One or more message strings per topic.
     */

    /**
     * @typedef {object} ManifestRecordItem
     *
     * @property {RecordMessageProperties} properties
     * @property {ManifestItem[]}          list
     */

    /**
     * JSON format of a response message containing a list of ManifestItems.
     *
     * @typedef {object} ManifestRecordMessage
     *
     * @property {ManifestRecordItem[]} items
     *
     * @see "ManifestItemController#bulk_update_response"
     */

    /**
     * JSON format of a response message containing a list of ManifestItems.
     *
     * @typedef {object} ManifestItemIdMessage
     *
     * @property {list: number[]} items
     */

    /**
     * @typedef {ManifestItem|{response: ManifestItem}} CreateResponse
     *
     * @see "ManifestItemConcern#create_record"
     */

    /**
     * @typedef {object} ItemResponse
     *
     * @property {ManifestItemTable|null} items
     * @property {ManifestItemTable|null} [pending]
     * @property {MessageTable|null}      [problems]
     *
     * @see "ManifestItemConcern#finish_editing"
     */

    /**
     * @typedef {ItemResponse|{response: ItemResponse}} UpdateResponse
     */

    /**
     * @typedef {UpdateResponse} FinishEditResponse
     */

    /**
     * @typedef {Manifest} ManifestMessage
     *
     * JSON format of a response from "/manifest/create" or "/manifest/update".
     */

    /**
     * JSON format of a response message from "/manifest/save".
     *
     * @typedef {object} ManifestSaveMessage
     *
     * @property {ManifestItemTable} items
     *
     * @see "ManifestController#save"
     */

    // ========================================================================
    // Constants
    // ========================================================================

    /**
     * Indicates whether expand/contract controls rotate (via CSS transition)
     * or whether their state is indicated by different icons (if **false**).
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
    const FIELD_ATTR = "data-field";

    const HEADING_CLASS         = "heading-bar";
    const TITLE_TEXT_CLASS      = "text.name";
    const TITLE_EDIT_CLASS      = "title-edit";
    const TITLE_EDITOR_CLASS    = "line-editor";
    const TITLE_UPDATE_CLASS    = "update";
    const TITLE_CANCEL_CLASS    = "cancel";

    const CONTAINER_CLASS       = "manifest-grid-container";
    const SUBMIT_CLASS          = "submit-button";
    const CANCEL_CLASS          = "cancel-button";
    const IMPORT_CLASS          = "import-button";
    const EXPORT_CLASS          = "export-button";
    const SUBMISSION_CLASS      = "submission-button";
    const COMM_STATUS_CLASS     = "comm-status";
    const GRID_CLASS            = "manifest_item-grid";
    const CTRL_EXPANDED_MARKER  = "controls-expanded";
    const HEAD_EXPANDED_MARKER  = "head-expanded";
    const TO_DELETE_MARKER      = "deleting";
    const ROW_CLASS             = "manifest_item-grid-item";
    const HEAD_CLASS            = "head";
    const COL_EXPANDER_CLASS    = "column-expander";
    const ROW_EXPANDER_CLASS    = "row-expander";
    const EXPANDED_MARKER       = "expanded";
    const CONTROLS_CELL_CLASS   = "controls-cell";
    const TRAY_CLASS            = "icon-tray";
    const ICON_CLASS            = "icon";
    const DETAILS_CLASS         = "details";
    const INDICATORS_CLASS      = "indicators";
    const INDICATOR_CLASS       = "indicator";
    const DATA_CELL_CLASS       = "cell";
    const EDITING_MARKER        = "editing";
    const CHANGED_MARKER        = "changed";
    const ERROR_MARKER          = "error";
  //const REQUIRED_MARKER       = "required";
    const ROW_FIELD_CLASS       = "value";
    const CELL_VALUE_CLASS      = ROW_FIELD_CLASS;
    const CELL_DISPLAY_CLASS    = CELL_VALUE_CLASS;
    const CELL_EDIT_CLASS       = "edit";

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
    const HEAD          = selector(HEAD_CLASS);
    const HEADER_ROW    = `${ROW}${HEAD}`;
    const DATA_ROW      = `${ROW}:not(${HEAD})`;
    const TEMPLATE_ROW  = `${DATA_ROW}${HIDDEN}`;
    const VISIBLE_ROW   = `${DATA_ROW}:not(${HIDDEN})`;
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
  //const CHANGED       = selector(CHANGED_MARKER);
    const ERROR         = selector(ERROR_MARKER);
  //const REQUIRED      = selector(REQUIRED_MARKER);
    const ROW_FIELD     = selector(`${ROW_FIELD_CLASS}[${FIELD_ATTR}]`);
  //const CELL_VALUE    = selector(CELL_VALUE_CLASS);
    const CELL_DISPLAY  = selector(CELL_DISPLAY_CLASS);
    const CELL_EDIT     = selector(CELL_EDIT_CLASS);

    const HEADER_ROLE   = '[role="columnheader"]';
    const CONTROLS_HEAD = `${CONTROLS_CELL}${HEADER_ROLE}`;
    const DATA_HEAD     = `${DATA_CELL}${HEADER_ROLE}`;
    const UPLOADER_CELL = `${DATA_CELL}${UPLOADER}`;

    /**
     * CSS classes for the data cell which indicate the status of the data.
     *
     * @type {string[]}
     */
    const STATUS_MARKERS     = [EDITING_MARKER, CHANGED_MARKER];
    const ALL_STATUS_MARKERS = [...STATUS_MARKERS, ERROR_MARKER];

    const PAGE_ATTRIBUTES = pageAttributes();
    const PAGE_PROPERTIES = PAGE_ATTRIBUTES.properties;

    const SUCCESS         = Emma.Messages.form.success;
    const NO_LOOKUP       = Emma.Messages.form.no_lookup;
    const NOT_CHANGEABLE  = Emma.Messages.form.unchangeable;

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

    const TITLE_DATA = "titleValue";

    /**
     * Enter title edit mode.
     *
     * @param {ElementEvt} event
     */
    function onStartTitleEdit(event) {
        OUT.debug("onStartTitleEdit: event =", event);
        beginTitleEdit();
    }

    /**
     * Enter title edit mode.
     */
    function beginTitleEdit() {
        //OUT.debug("beginTitleEdit");
        const old_name = $title_text.text()?.trim() || "";
        $title_heading.toggleClass(EDITING_MARKER, true);
        $title_heading.data(TITLE_DATA, old_name);
        $title_input.val(old_name);
        $title_input.trigger("focus");
    }

    /**
     * Update the name of the Manifest and leave title edit mode.
     *
     * @param {ElementEvt} event
     */
    function onUpdateTitleEdit(event) {
        OUT.debug("onUpdateTitleEdit: event =", event);
        const new_name = $title_input.val()?.trim() || "";
        const old_name = $title_heading.data(TITLE_DATA) || "";
        const update   = (new_name === old_name) ? undefined : new_name;
        endTitleEdit(update);
    }

    /**
     * Leave title edit mode without changing the Manifest title.
     *
     * @param {ElementEvt} event
     */
    function onCancelTitleEdit(event) {
        OUT.debug("onCancelTitleEdit: event =", event);
        endTitleEdit();
    }

    /**
     * Create or update the Manifest then leave title edit mode.
     *
     * @param {string} [new_name]    If present, update the Manifest record.
     */
    function endTitleEdit(new_name) {
        //OUT.debug(`endTitleEdit: new_name = "${new_name}"`);
        if (new_name) {
            setManifestName(new_name);
            $title_text.text(new_name);
        }
        $title_heading.toggleClass(EDITING_MARKER, false);
        $title_edit.trigger("focus");
    }

    /**
     * Allow **Enter** to work as "Change" and **Escape** to work as "Keep".
     *
     * @param {KeyboardEvt} event
     *
     * @returns {EventHandlerReturn}
     */
    function onTitleEditKeypress(event) {
        switch (keyCombo(event)) {
            case "Enter":  onUpdateTitleEdit(event); break;
            case "Escape": onCancelTitleEdit(event); break;
            default:       return undefined;
        }
        event.stopImmediatePropagation();
        return false;
    }

    // ========================================================================
    // Functions - form
    // ========================================================================

    /**
     * Initialize the grid and controls.
     */
    function initializeEditForm() {
        OUT.debug("initializeEditForm");
        setTimeout(scrollToTop, 0);
        initializeHeaderRow();
        initializeGridContent();
        initializeAllDataRows();
        initializeControlButtons();
        initializeGridNavigation($grid);
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
        const func = "initializeControlButtons"; //OUT.debug(func);
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
        //OUT.debug(`enableSave: setting = "${setting}"`);
        const enable = isDefined(setting) ? setting : checkFormChanged();
        return enableControlButton("submit", enable);
    }

    /**
     * Enable/disable the Export button.
     *
     * @param {boolean} [setting]     Def.: presence of {@link activeDataRows}.
     *
     * @returns {jQuery|undefined}
     */
    function enableExport(setting) {
        //OUT.debug(`enableExport: setting = "${setting}"`);
        const yes = isDefined(setting) ? setting : isPresent(activeDataRows());
        return enableControlButton("export", yes);
    }

    /**
     * Enable/disable the Submit button.
     *
     * @param {boolean} [setting]     Def.: presence of {@link activeDataRows}.
     *
     * @returns {jQuery|undefined}
     */
    function enableSubmission(setting) {
        //OUT.debug(`enableSubmission: setting = "${setting}"`);
        const yes = isDefined(setting) ? setting : isPresent(activeDataRows());
        return enableControlButton("submission", yes);
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
        const func = "enableControlButton";
        OUT.debug(`${func}: type = "${type}"; enable = "${enable}"`);
        const $button = buttonFor(type, CONTROL_BUTTONS, func);
        return enableButton($button, enable, type);
    }

    // ========================================================================
    // Functions - form - update
    // ========================================================================

    /**
     * Save updated row(s). <p/>
     *
     * If there is a cell being edited, that edit is abandoned since completing
     * it could change the validation state so that it's not longer safe to
     * save the updates that have been made so far.
     *
     * @param {ElementEvt} event
     *
     * @see "ManifestConcern#save_changes"
     */
    function saveUpdates(event) {
        const func     = "saveUpdates";
        const $button  = $(event.currentTarget || event.target);
        const manifest = manifestId();
        OUT.debug(`${func}: manifest = ${manifest}; event =`, event);

        cancelActiveCell();             // Abandon any active edit.
        finalizeDataRows("original");   // Update "original" cell values.

        // It should not be possible to get here unless the form is associated
        // with a real persisted Manifest record.
        if (!manifest) {
            OUT.error(`${func}: no manifest ID`);
            return;
        }

        // Inform the server to allow it to recalculate row/delta values and
        // update related ManifestItem records.
        serverManifestSend(`save/${manifest}`, {
            caller:    func,
            onSuccess: onSuccess,
        });

        /**
         * Process the response to replace the provisional row/delta values
         * with the real row numbers (and no deltas).
         *
         * @param {ManifestSaveMessage|ManifestItemTable|undefined} body
         *
         * @see "ManifestController#save"
         */
        function onSuccess(body) {
            OUT.debug(`${func}: body =`, body);
            // noinspection JSValidateTypes
            /** @type {ManifestItemTable} */
            const data = body?.items || body;
            if (isEmpty(body)) {
                OUT.error(`${func}: no response data`);
            } else if (isEmpty(data)) {
                OUT.error(`${func}: no items present in response data`);
            } else {
                flashMessage(SUCCESS, { refocus: $button });
                updateRowValues(data);
                refreshEditForm();
            }
        }
    }

    /**
     * Cancel all changes since the last save.
     *
     * @param {ElementEvt} event
     *
     * @see "ManifestConcern#cancel_changes"
     */
    function cancelUpdates(event) {
        const func     = "cancelUpdates";
        const manifest = manifestId();
        const finalize = () => cancelAction($cancel);
        OUT.debug(`${func}: manifest = ${manifest}; event =`, event);

        cancelActiveCell();             // Abandon any active edit.
        deleteRows(blankDataRows());    // Eliminate rows unseen by the server.
        finalizeDataRows("original");   // Restore original cell values.

        // The form never resulted in the creation of a Manifest record so
        // there is nothing to inform the server about.
        if (!manifest) {
            OUT.debug(`${func}: canceling un-persisted manifest`);
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
     * @param {ElementEvt} event
     */
    function importRows(event) {
        const func = "importRows"; OUT.debug(`${func}: event =`, event);
        let input, file;
        if (!(input = $import[0])) {
            OUT.error(`${func}: no $import element`);
        } else if (!(file = input.files[0])) {
            OUT.debug(`${func}: no file selected`);
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
        OUT.debug("importFile: file =", file);
        const reader = new FileReader();
        reader.readAsText(file);
        reader.onloadend = (evt) => importData(evt.target.result, file.name);
    }

    /**
     * Import manifest items from CSV row data.
     *
     * @param {string} data
     * @param {string} [filename]     For diagnostics only.
     */
    function importData(data, filename) {
        const func  = "importData";
        const type  = dataType(data);
        const opt   = { caller: func, type: type };
        const $last = allDataRows().last();
        if (getManifestItemId($last)) {
            opt.row   = dbRowValue($last);
            opt.delta = dbRowDelta($last);
        }
        OUT.debug(`${func}: from "${filename}": type "${type}"; data =`, data);
        sendCreateRecords(data, opt);
    }

    /**
     * Re-import manifest items from CSV row data.
     *
     * @note This is not currently used and is here to serve as a reminder that
     *  this use-case needs to be considered.
     *
     * @param {string} data
     * @param {string} [filename]     For diagnostics only.
     */
    function reImportData(data, filename) {
        const func = "reImportData";
        const type = dataType(data);
        const opt  = { caller: func, type: type };
        OUT.debug(`${func}: from "${filename}": type "${type}"; data =`, data);
        sendUpdateRecords(data, opt);
   }

    // ========================================================================
    // Functions - form - export
    // ========================================================================

    /**
     * Export manifest items to a CSV file.
     *
     * @param {ElementEvt} event
     */
    function exportRows(event) {
        OUT.debug("exportRows: event =", event);
        const $button  = $(event.currentTarget || event.target);
        const message  = "EXPORT - FUTURE ENHANCEMENT"; // TODO: exportRows
        flashMessage(message, { refocus: $button });
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
        OUT.debug(`updateFormChanged: setting = ${setting}`);
        const changed = isDefined(setting) ? setting : checkFormChanged();
        enableSave(changed);
        enableExport();
        enableSubmission();
        return changed;
    }

    /**
     * Check whether the form is in a state where a save is permitted.
     *
     * @param {Selector} [grid]       Default: {@link $grid}.
     *
     * @returns {boolean}             Changed status.
     */
    function checkFormChanged(grid) {
        //OUT.debug("checkFormChanged: grid =", grid);
        return checkGridChanged(grid);
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
        'fieldset.menu.multi', // TODO: keep?
        'ul[role="listbox"]',
        '.menu.single',
        '.input.multi',
        '.input.single',
    ].join(", ");

    /**
     * Initial adjustments for the grid display.
     *
     * @param {Selector} [grid]       Default: {@link $grid}.
     */
    function initializeGridContent(grid) {
        OUT.debug("initializeGridContent; grid =", grid);
        const $cells = dataCells(grid, true);
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
        //OUT.debug("initializeCellDisplays: cells =", cells);
        dataCells(cells).each((_, cell) => updateCellDisplayValue(cell));
    }

    /**
     * Ensure that required inputs have the proper ARIA attribute.
     *
     * @param {Selector} [cells]      Default: {@link allDataCells}
     */
    function initializeCellInputs(cells) {
        //OUT.debug("initializeCellInputs: cells =", cells);
        const property = fieldProperty();
        dataCells(cells).each((_, cell) => {
            /** @type {jQuery} */
            const $cell = $(cell);
            const field = $cell.attr(FIELD_ATTR);
            if (field === "file_data") {
                $cell.attr("aria-required", true);
            } else if (property[field]?.required) {
                $cell.attr("aria-required", true);
                $cell.find(INPUTS).attr("aria-required", true);
            }
        });
    }

    /**
     * Resize textareas for all cells so that their respective grid columns end
     * up having widths that can remain constant whenever any of the cells goes
     * into edit mode. <p/>
     *
     * The maximum number of characters of the placeholder and any data line is
     * treated as the desired *cols* attribute for that textarea.  The maximum
     * *cols* attribute (with a fudge factor for non-constant-width fonts) is
     * used to explicitly set the *cols* attribute on all included textareas.
     *
     * @see https://developer.mozilla.org/en-US/docs/Web/HTML/Element/textarea
     *
     * @param {Selector} [cells]      Default: {@link allDataCells}
     * @param {number}   [min_cols]   Minimum *cols* attribute value.
     * @param {number}   [scale]      Heuristic for variable width fonts.
     */
    function initializeTextareaColumns(cells, min_cols = 20, scale = 1.2) {
        //OUT.debug("initializeTextareaColumns: cells =", cells);
        const $textareas   = dataCells(cells).find('textarea');
        const column_width = (max_cols, textarea) => {
            const $area = $(textarea);
            const min   = $area.attr("placeholder")?.length || 0;
            const lines = getCellCurrentValue($area).lines.map(v => v.length);
            return Math.max(min, ...lines, max_cols);
        };
        for (const [field, prop] of Object.entries(fieldProperty())) {
            if (prop.type?.startsWith("text")) {
                const data_field = `[${FIELD_ATTR}="${field}"]`;
                const $column    = $textareas.filter(data_field);
                const textareas  = $column.toArray();
                const max_width  = textareas.reduce(column_width, min_cols);
                const max_cols   = Math.round(max_width * scale);
                textareas.forEach(ta => $(ta).attr("cols", max_cols));
            }
        }
    }

    /**
     * Records that have a non-empty file_data column when rendered on the
     * server have the contents of that field put into a *data-value* attribute
     * which needs to be processed here in order to associate the data with the
     * cell. <p/>
     *
     * The attribute is removed so there's one less thing to contend with when
     * duplicating rows.
     *
     * @see "ManifestItemDecorator#grid_data_cell_render_pair"
     *
     * @param {Selector} [cells]      Default: {@link allDataCells}
     */
    function initializeUploaderCells(cells) {
        //OUT.debug('initializeUploaderCells: cells =', cells);
        const attr      = 'data-value';
        const name      = attr.replace(/^data-/, '');
        const with_attr = `[${attr}]`;
        dataCells(cells).filter(UPLOADER_CELL).each((_, cell) => {
            const $cell  = $(cell);
            const $value = selfOrDescendents($cell, with_attr).first();
            const data   = $value.data(name) || {}; // Let jQuery do the work.
            $cell.removeData(name).removeAttr(attr);
            $cell.find(with_attr).removeData(name).removeAttr(attr);
            delete data.emma_data;
            dataCellUpdate(cell, data);
        });
    }

    /**
     * Refresh all grid rows.
     */
    function refreshGrid() {
        OUT.debug("refreshGrid");
        allDataRows().each((_, row) => refreshDataRow(row));
    }

    // ========================================================================
    // Functions - grid - controls
    // ========================================================================

    /**
     * Expand/contract the header row.
     *
     * @param {Selector} [button]
     * @param {boolean}  [expand]
     */
    function toggleHeaderRow(button, expand) {
        const func      = "toggleHeaderRow";
        OUT.debug(`${func}: expand = ${expand}; button =`, button);
        const $button   = button ? $(button) : headerRowToggle();
        const $target   = selfOrParent($button, HEADER_ROW, func);
        const expanding = isDefined(expand) ? !!expand : !$target.is(EXPANDED);
        const config    = Emma.Grid.Headers.row;
        const mode      = expanding ? config.closer : config.opener;

        $button.attr("aria-expanded", expanding);
        $button.attr("title", mode.tooltip);
        if (!CONTROLS_ROTATE) {
            $button.html(mode.label);
        }

        const $items = headerRow();
        $items.toggleClass(EXPANDED_MARKER, expanding);
        if (!expanding) {
            $items.find('details').removeAttr("open");
        }
        $grid.toggleClass(HEAD_EXPANDED_MARKER, expanding);
    }

    /**
     * Expand/contract the controls column.
     *
     * @param {Selector} [button]
     * @param {boolean}  [expand]
     */
    function toggleControlsColumn(button, expand) {
        const func      = "toggleControlsColumn";
        OUT.debug(`${func}: expand = ${expand}; button =`, button);
        const $button   = button ? $(button) : controlsColumnToggle();
        const $target   = selfOrParent($button, CONTROLS_CELL, func);
        const expanding = isDefined(expand) ? !!expand : !$target.is(EXPANDED);
        const config    = Emma.Grid.Headers.column;
        const mode      = expanding ? config.closer : config.opener;

        $button.attr("aria-expanded", expanding);
        $button.attr("title", mode.tooltip);
        if (!CONTROLS_ROTATE) {
            $button.html(mode.label);
        }

        const $items   = controlsColumn();
        const $details = $items.find('details');
        if (expanding) {
            $details.removeAttr("tabindex");
        } else {
            $details.removeAttr("open").attr("tabindex", -1);
        }
        $items.toggleClass(EXPANDED_MARKER, expanding);
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
    const DELTA_TABLE_DATA = "deltaTable";

    /**
     * Get the delta table, creating it if necessary.
     *
     * @returns {DeltaTable}
     */
    function getDeltaTable() {
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
        const table = getDeltaTable();
        const row   = (typeof r === "number") ? r : dbRowValue(r);
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
        const table = getDeltaTable();
        if (isPresent(table)) {
            arrayWrap(rows).forEach(r => {
                const row = (typeof r === "number") ? r : dbRowValue(r);
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
     * @param {Selector} [grid]       Default: {@link $grid}.
     *
     * @returns {boolean}             False if no changes.
     */
    function evaluateGridChanged(grid) {
        OUT.debug("evaluateGridChanged: grid =", grid);
        const evaluate_row = (change, row) => updateRowChanged(row) || change;
        return dataRows(grid).toArray().reduce(evaluate_row, false);
    }

    /**
     * Check row changed state to determine whether the grid has changed. <p/>
     *
     * (No stored data values are updated.)
     *
     * @param {Selector} [grid]       Default: {@link $grid}.
     *
     * @returns {boolean}             False if no changes.
     */
    function checkGridChanged(grid) {
        //OUT.debug("checkGridChanged: grid =", grid);
        const check_row = (change, row) => change || checkRowChanged(row);
        return dataRows(grid).toArray().reduce(check_row, false);
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
        return dataRows(undefined, hidden);
    }

    /**
     * All data rows for the grid.
     *
     * @param {Selector} [grid]       Default: {@link $grid}.
     * @param {boolean}  [hidden]     Include hidden rows.
     *
     * @returns {jQuery}
     */
    function dataRows(grid, hidden) {
        const tgt   = grid || $grid;
        const match = hidden ? DATA_ROW : VISIBLE_ROW;
        return selfOrDescendents(tgt, match);
    }

    /**
     * Get the single row container associated with the target.
     *
     * @param {Selector} target       Row or cell.
     *
     * @returns {jQuery}
     */
    function dataRow(target) {
        const func  = "dataRow"; //OUT.debug(`${func}: target =`, target);
        const match = DATA_ROW;
        return selfOrParent(target, match, func);
    }

    /**
     * Indicate whether the given row exists in the database (saved or not).
     *
     * @param {Selector} target       Row or cell.
     *
     * @returns {boolean}
     */
    function activeDataRow(target) {
        return !!getManifestItemId(target);
    }

    /**
     * All rows that are associated with database items.
     *
     * @param {Selector} [grid]       Default: {@link $grid}.
     *
     * @returns {jQuery}
     */
    function activeDataRows(grid) {
        return dataRows(grid).filter((_, row) => activeDataRow(row));
    }

    /**
     * Indicate whether the given row is an empty row which has never caused
     * the creation of a database item.
     *
     * @param {Selector} target       Row or cell.
     *
     * @returns {boolean}
     */
    function blankDataRow(target) {
        return !getManifestItemId(target);
    }

    /**
     * All rows that are not associated with database items.
     *
     * @param {Selector} [grid]       Default: {@link $grid}.
     *
     * @returns {jQuery}
     */
    function blankDataRows(grid) {
        return dataRows(grid).filter((_, row) => blankDataRow(row));
    }

    /**
     * Use received data to update cell(s) associated with data values. <p/>
     *
     * If the row doesn't have a *data-item-id* attribute it will be set here
     * if data has an *id* value.
     *
     * @param {Selector}     target   Row or cell.
     * @param {ManifestItem} data
     *
     * @returns {EmmaData}            Updated fields.
     */
    function updateDataRow(target, data) {
        const func = "updateDataRow";
        OUT.debug(`${func}: data =`, data, "target =", target);

        /** @type {EmmaData} */
        const updated = {};
        if (isEmpty(data)) {
            return updated;
        }
        const $row = dataRow(target);

        if (isPresent(data.id)) {
            const db_id = getManifestItemId($row);
            if (!db_id) {
                setManifestItemId($row, data.id);
            } else if (db_id !== data.id) {
                OUT.error(`${func}: row ID = ${db_id}; data.id = ${data.id}`);
                return updated;
            }
        }
        if (hasKey(data, "row")) {
            setDbRowValue($row, data.row);
        }
        if (hasKey(data, "delta")) {
            setDbRowDelta($row, data.delta);
        }
        if (data.deleting) {
            OUT.error(`${func}: received deleted item:`, data);
        }
        const error = { ...data.field_error };

        let changed;
        dataCells($row).each((_, cell) => {
            const $cell = $(cell);
            const field = cellDbColumn($cell);
            const [data_value, data_field] = getValueAndField(data, field);
            if (data_field) {
                // If this field is associated with one or more error values
                // then, even if data_value is present, it is either invalid or
                // contains one or more invalid values.
                const err = presence(error[data_field]);
                let value = data_value;
                if (err && !Array.isArray(value)) {
                    const errors = Object.keys(err);
                    value = (errors.length > 1) ? errors : errors[0];
                }
                const new_value = $cell.makeValue(value, err);
                const old_value = getCellCurrentValue($cell);
                if (!old_value || new_value.differsFrom(old_value)) {
                    dataCellUpdate($cell, new_value, true, new_value.valid);
                    updated[data_field] = new_value.value;
                    changed = true;
                } else if (new_value.valid) {
                    updateCellValid($cell, true);
                    changed = true;
                } else if (err) {
                    old_value.addErrorTable(err);
                    updateCellValid($cell);
                    changed = true;
                } else if (getCellChanged($cell)) {
                    updateCellValid($cell);
                    changed = true;
                }

                let tooltip = "";
                if (err) {
                    const tag = Emma.Messages.error.toUpperCase();
                    let parts;
                    if (isObject(err)) {
                        parts = Object.entries(err);
                        parts = parts.map(([k,v]) => `"${k}": ${v}`);
                    } else {
                        parts = arrayWrap(err);
                    }
                    tooltip = `${tag}: ` + parts.join("; ");
                }
                cellDisplay($cell).attr("title", tooltip);
            }
        });

        if (changed) { updateRowChanged($row, true) }
        if (changed) { updateFormChanged() }
        updateRowIndicators($row, data);
        updateRowDetailsItems($row, data);
        updateLookupCondition($row);
        return updated;
    }

    // ========================================================================
    // Functions - row - initialization
    // ========================================================================

    /**
     * Set up elements within the header row.
     */
    function initializeHeaderRow() {
        OUT.debug("initializeHeaderRow");
        headerColumns().each((_, column) => setupCellNavGroup(column));
    }

    /**
     * If there are rows present on the page at startup, they are initialized.
     * If not, an empty row is inserted.
     */
    function initializeAllDataRows() {
        OUT.debug("initializeAllDataRows");
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
        //OUT.debug("initializeDataRow: row =", row);
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
     * @param {jQuery} $row
     */
    function setupRowFunctionality($row) {
        OUT.debug("setupRowFunctionality: $row =", $row);
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
     * @param {string}   from         "current" or "original".
     * @param {Selector} [target]     Default: {@link allDataRows}.
     */
    function finalizeDataRows(from, target) {
        OUT.debug(`finalizeDataRows: from ${from}: target =`, target);
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
     */
    function refreshDataRow(row) {
        OUT.debug("refreshDataRow: row =", row);
        dataCells(row).each((_, cell) => resetDataCell(cell));
    }

    // ========================================================================
    // Functions - row - controls
    // ========================================================================

    /**
     * The name of the attribute indicating the action of a control button.
     *
     * @type {string}
     */
    const ACTION_ATTR = "data-action";

    /**
     * Attach handlers for row control icon buttons.
     *
     * @param {Selector} [$row]     Default: all {@link rowControls}.
     */
    function setupRowOperations($row) {
        OUT.debug("setupRowOperations: $row =", $row);
        const $cell = controlsColumn($row);
        setupCellNavGroup($cell);
        controlsColumnToggleAdd($cell);
    }

    /**
     * Perform an operation on a row item.
     *
     * @param {Selector|ElementEvt} arg
     */
    function rowOperation(arg) {
        const func     = "rowOperation"; OUT.debug(`${func}: arg =`, arg);
        const evt      = isEvent(arg);
        const $control = $(evt ? arg.target : arg);
        const $current = dataRow($control);
        const action   = $control.attr(ACTION_ATTR);
        let $row;
        switch (action) {
            case "lookup":
                lookupRow($current);
                break;
            case "insert":
                $row = insertRow($current);
                break;
            case "delete":
                const $next = presence($current.next()) || $current.prev();
                if (deleteRow($current)) {
                    $row = $next;
                }
                break;
            default:
                evt && OUT.error(`${func}: no function for "${action}"`);
                break;
        }
        $row?.children()?.first()?.trigger("focus");
    }

    /**
     * Per-item control icons.
     *
     * @param {Selector} [target]     Default: {@link controlsColumn}.
     *
     * @returns {jQuery}
     */
    function rowControls(target) {
        const $t    = target && $(target);
        const match = TRAY;
        /** @type {jQuery} */
        const $tray = $t?.is(match) ? $t : controlsColumn($t).find(match);
        return $tray.find(ICON);
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
     * Indicate whether the target is a row control button.
     *
     * @param {Selector} target
     *
     * @returns {boolean}
     */
    function isRowButton(target) {
        return $(target).is(`[${ACTION_ATTR}]`);
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
     * @param {boolean}  [enable]     If **false** then disable.
     * @param {boolean}  [forbid]     If **true** add ".forbidden" if disabled.
     *
     * @returns {jQuery}              The submit button.
     */
    function enableRowButton(row, action, enable, forbid) {
        OUT.debug(`enableRowButton: ${action}: row =`, row);
        return toggleRowButton(row, action, (enable !== false), forbid);
    }

    /**
     * Enable/disable operation button for the given row.
     *
     * @param {Selector} row
     * @param {string}   action
     * @param {boolean}  [enable]
     * @param {boolean}  [forbid]     If **true** add ".forbidden" if disabled.
     *
     * @returns {jQuery}              The submit button.
     */
    function toggleRowButton(row, action, enable, forbid) {
        /** @type {ActionProperties} */
        let config    = Emma.Grid.Icons[action];
        const func    = `toggleRowButton: ${action}`;
        const $button = rowButton(row, action);
        //OUT.debug(`${func}: row =`, row);
        if (!config) {
            OUT.error(`${func}: invalid action`);
            return $button;
        }

        const is_forbidden      = $button.hasClass("forbidden");
        const old_was_forbidden = $button.hasClass("was-forbidden");
        let now_disabled, now_forbidden, new_was_forbidden;
        if (enable === true) {
            config            = { ...config, ...config.if_enabled };
            now_disabled      = false;
            now_forbidden     = false;
            new_was_forbidden = is_forbidden || old_was_forbidden;
            if (forbid) { OUT.warn(`${func}: cannot enable and forbid`) }
        } else if (enable === false) {
            config            = { ...config, ...config.if_disabled };
            now_disabled      = true;
            now_forbidden     = forbid || false;
            new_was_forbidden = false;
        } else if ($button.hasClass("disabled")) { // Toggling to enabled state
            now_disabled      = false;
            now_forbidden     = false;
            new_was_forbidden = is_forbidden || old_was_forbidden;
        } else { // Toggling to disabled state
            now_disabled      = true;
            now_forbidden     = forbid || old_was_forbidden;
            new_was_forbidden = !old_was_forbidden;
        }

        const tooltip = (action === "lookup") && now_forbidden && NO_LOOKUP;
        $button.attr("title", (tooltip || config.tooltip || ""));

        $button.prop("disabled", now_disabled);
        $button.toggleClass("disabled",      now_disabled);
        $button.toggleClass("forbidden",     now_forbidden);
        $button.toggleClass("was-forbidden", new_was_forbidden);
        return $button;
    }

    // ========================================================================
    // Functions - row - insert
    // ========================================================================

    /**
     * Insert a new empty row after the row associated with the target.
     * If no target is provided a new empty row is inserted into `<tbody>`.<p/>
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
        OUT.debug("insertRow after", after);
        const with_data = isPresent(data);
        const $old_row  = after ? dataRow(after) : undefined;
        const $new_row  = emptyDataRow($old_row, with_data);
        if ($old_row) {
            $new_row.insertAfter($old_row);
        } else {
            $new_row.attr("id", "manifest_item-item-1");
            $grid.children('tbody').prepend($new_row);
        }
        if (with_data) {
            updateDataRow($new_row, data);
        }
        if (!intermediate) {
            updateGridRowCount(1);
            updateGridNavigation($grid);
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
        OUT.debug("appendRows: list =", list);
        /** @type {ManifestItem[]} */
        const items = arrayWrap(list);
        const $last = allDataRows().last();

        let $row; // When undefined, first insertRow starts with $template_row.
        if (getManifestItemId($last)) {
            $row = $last;   // Insert after last row.
        } else if (isPresent($last)) {
            $last.remove(); // Discard empty row.
        }
        let row   = $row ? dbRowValue($row) : 0;
        let delta = $row ? dbRowDelta($row) : 0;
        const mod = {};
        let $first_added;
        items.forEach(record => {
            let r, d;
            $row  = insertRow($row, record, true);
            row   = dbRowValue($row) || (r = setDbRowValue($row, row));
            delta = dbRowDelta($row) || (d = setDbRowDelta($row, ++delta));
            if (r || d) { mod[getManifestItemId($row)] = { row: r, delta: d } }
            setRowChanged($row, true);
            $first_added ||= $row;
        });
        if (!intermediate) {
            updateGridRowCount(items.length);
            updateGridNavigation($grid);
            $first_added?.children()?.first()?.trigger("focus");
        }
        if (isPresent(mod)) {
            sendUpdateRecords(mod);
        }
    }

    /**
     * Create multiple ManifestItem records.
     *
     * @param {object|string} items
     * @param {object}        [options]
     *
     * @see "ManifestItemController#bulk_create"
     */
    function sendCreateRecords(items, options) {
        const func = "sendCreateRecords";
        const opt  = { caller: func, ...options, create: true };
        sendUpsertRecords(items, opt);
    }

    /**
     * Update multiple ManifestItem records.
     *
     * @param {object|string} items
     * @param {object}        [options]
     *
     * @see "ManifestItemController#bulk_update"
     */
    function sendUpdateRecords(items, options) {
        const func = "sendUpdateRecords";
        const opt  = { caller: func, ...options, create: false };
        sendUpsertRecords(items, opt);
    }

    /**
     * Create/update multiple ManifestItem records.
     *
     * @param {object|string} items
     * @param {object}        [options]
     */
    function sendUpsertRecords(items, options) {
        const opt      = { ...options };
        const caller   = opt.caller;           delete opt.caller;
        const create   = opt.create;           delete opt.create;
        const headers  = { ...opt.headers };   delete opt.headers;
        const params   = { ...(opt.params || opt), data: items };

        const func     = caller || "sendUpsertRecords";
        const op       = create ? "create" : "update";
        const manifest = manifestId();
        OUT.debug(`${func}: (${op}) manifest = ${manifest}; items =`, items);

        if (!manifest) {
            OUT.error(`${func}: no manifest ID`);
            return;
        }

        headers["Accept"]       ||= "text/html";
        headers["Content-Type"] ||= "multipart/form-data";

        serverItemSend(`bulk/${op}/${manifest}`, {
            caller:     func,
            params:     params,
            headers:    headers,
            onSuccess:  processReceivedItems,
        });
    }

    /**
     * Append ManifestItems returned from the server.
     *
     * @param {ManifestRecordMessage|ManifestRecordItem} body
     *
     * @see "ManifestItemController#bulk_update_response"
     * @see "SerializationConcern#index_values"
     */
    function processReceivedItems(body) {
        const func = "processReceivedItems"; OUT.debug(`${func}: body =`,body);
        const data = body?.items || body || {};
        const list = data.list;
        if (isEmpty(data)) {
            OUT.error(`${func}: no response data`);
        } else if (isEmpty(list)) {
            OUT.error(`${func}: no items present in response data`);
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
        const func = "markRow"; //OUT.debug(`${func}: target =`, target);
        const $row = dataRow(target);
        if ($row.is(TO_DELETE)) {
            OUT.debug(`${func}: already marked ${TO_DELETE} -`, $row);
        } else {
            $row.addClass(TO_DELETE_MARKER);
        }
        return $row;
    }

    /**
     * Mark the indicated row for deletion. <p/>
     *
     * If it is a blank row (not yet associated with a ManifestItem) then it is
     * removed directly; otherwise request that the associated ManifestItem
     * record be marked for deletion.
     *
     * @param {Selector} target
     * @param {boolean}  [intermediate]     If more row changes coming.
     *
     * @returns {boolean}                   **false** if not deleted.
     */
    function deleteRow(target, intermediate) {
        const func = "deleteRow"; OUT.debug(`${func}: target =`, target);
        const $row = dataRow(target);

        // Avoid removing the final row of the grid.
        if (allDataRows().length <= 1) {
            OUT.debug(`${func}: cannot delete the final row`);
            if ($row.is(TO_DELETE)) {
                OUT.debug(`${func}: un-marking for deletion -`, $row);
                $row.removeClass(TO_DELETE_MARKER);
            }
            return false;
        }

        // Mark row for deletion then update the grid and/or database.
        markRow($row);
        const db_id = getManifestItemId($row);
        if (db_id) {
            sendDeleteRecords(db_id, intermediate);
        } else {
            OUT.debug(`${func}: removing blank row -`, $row);
            removeGridRow($row, intermediate);
        }
        return true;
    }

    /**
     * Mark the indicated rows for deletion. <p/>
     *
     * If all are blank rows (not yet associated with ManifestItems) then they
     * are removed directly; otherwise request that the associated ManifestItem
     * records be marked for deletion.
     *
     * @param {number|ManifestItem|jQuery|HTMLElement|array} list
     * @param {boolean} [preserve_last]     Default: **true**.
     * @param {boolean} [intermediate]      If more row changes coming.
     */
    function deleteRows(list, preserve_last, intermediate) {
        const func   = "deleteRows"; OUT.debug(`${func}: list =`, list);
        const $rows  = allDataRows();
        const blanks = [];
        const db_ids =
            arrayWrap(list).map(item => {
                let $row;
                switch (true) {
                    case (item instanceof jQuery):      $row = item;    break;
                    case (item instanceof HTMLElement): $row = $(item); break;
                    case isDefined(item?.id):           return item.id;
                    default:                            return item;
                }
                const db_id = getManifestItemId($row);
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
                OUT.debug(`${func}: no row for db_id ${db_id}`);
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
            OUT.debug(`${func}: cannot delete the final row`);
            OUT.debug(`${func}: un-marking for deletion -`, $row);
            $row?.removeClass(TO_DELETE_MARKER);
        }

        if (b_size) {
            OUT.debug(`${func}: removing blank rows -`, blanks);
            removeGridRows($(blanks), intermediate);
        }
        if (d_size) {
            sendDeleteRecords(db_ids, intermediate);
        }
        if (!b_size && !d_size) {
            OUT.debug(`${func}: nothing to do`);
        }
    }

    /**
     * Cause the server to delete the indicated ManifestItem records.
     *
     * @param {number|number[]} items
     * @param {boolean}         [intermediate]  If more row changes coming.
     */
    function sendDeleteRecords(items, intermediate) {
        const func     = "sendDeleteRecords";
        const manifest = manifestId();
        OUT.debug(`${func}: manifest = ${manifest}; items =`, items);

        if (!manifest) {
            OUT.error(`${func}: no manifest ID`);
            return;
        }

        const accept   = "application/json";
        const content  = "multipart/form-data";

        serverItemSend(`bulk/destroy/${manifest}`, {
            caller:     func,
            method:     "DELETE",
            params:     { ids: arrayWrap(items) },
            headers:    { "Content-Type": content, Accept: accept },
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
            OUT.debug(`${func}: body =`, body);
            const data = body?.items || body || {};
            const list = data.list || [];
            if (isEmpty(data)) {
                OUT.error(`${func}: no response data`);
            } else if (isEmpty(list)) {
                OUT.error(`${func}: no items present in response data`);
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
        const func   = "removeDeletedRows"; OUT.debug(`${func}: list =`, list);
        const $rows  = allDataRows();
        const to_del = $rows.filter(TO_DELETE).toArray();
        const marked = compact(to_del.map(e => getManifestItemId(e)));
        const db_ids = arrayWrap(list).map(r => isDefined(r?.id) ? r.id : r);

        // Mark rows for deletion if not already marked.
        db_ids.forEach(db_id => {
            const $row = rowForManifestItem(db_id, $rows);
            if (!$row) {
                OUT.debug(`${func}: no row for db_id ${db_id}`);
            } else if (!$row.is(TO_DELETE)) {
                OUT.debug(`${func}: ${db_id} not already marked ${TO_DELETE}`);
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
            OUT.warn(`${func}: not deleted:`, undeleted);
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
        OUT.debug("removeGridRows: rows =", rows);
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
        OUT.debug("removeGridRow: item =", target);
        const $row = dataRow(target);
        destroyGridRowElements($row, intermediate);
    }

    /**
     * Remove row element(s) from the grid. <p/>
     *
     * The elements are hidden first in order to allow the re-render to happen
     * all at once.
     *
     * @param {jQuery}  $rows
     * @param {boolean} [intermediate]      If more row changes coming.
     */
    function destroyGridRowElements($rows, intermediate) {
        //OUT.debug("destroyGridRowElements: $rows =", $rows);
        const row_count = $rows.length;
        toggleHidden($rows, true);
        $rows.each((_, row) => controlsColumnToggleRemove(row));
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
        return rowButton(row, "delete");
    }

    /**
     * Enable the delete button for the given row.
     *
     * @param {Selector} row
     * @param {boolean}  [enable]     If **false** run {@link disableDelete}.
     * @param {boolean}  [forbid]     If **true** add ".forbidden" if disabled.
     *
     * @returns {jQuery}              The submit button.
     */
    function enableDelete(row, enable, forbid) {
        return enableRowButton(row, "delete", enable, forbid);
    }

    /**
     * Disable operation button for the given row.
     *
     * @param {Selector} row
     * @param {boolean}  [forbid]     If **true** add ".forbidden".
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
        OUT.debug("updateDeleteButtons");
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
    const LOOKUP_DATA = "lookup";

    /**
     * Invoke bibliographic lookup for the row associated with the target.
     *
     * @param {Selector} target
     */
    function lookupRow(target) {
        const func  = "lookupRow"; OUT.debug(`${func}: target =`, target);
        const $row  = dataRow(target);
        const $ctrl = lookupButton($row);
        const modal = LookupModal.instanceFor($ctrl);
        if (modal) {
            modal.toggleModal($ctrl);
        } else {
            OUT.error(`${func}: no LookupModal for`, $ctrl, "in row", $row);
        }
    }

    /**
     * The lookup button for the given row.
     *
     * @param {Selector} row
     *
     * @returns {jQuery}
     */
    function lookupButton(row) {
        return rowButton(row, "lookup");
    }

    /**
     * Initialize bibliographic lookup for a data row.
     *
     * @param {jQuery} $row
     */
    function setupLookup($row) {
        OUT.debug("setupLookup: $row =", $row);

        const $button = lookupButton($row);

        updateLookupCondition($row);

        LookupModal.setupFor($button, onLookupStart, onLookupComplete);

        /**
         * Invoked to update search terms when the popup opens.
         *
         * @param {jQuery}  $activator
         * @param {boolean} check_only
         * @param {boolean} [halted]
         *
         * @returns {EventHandlerReturn}
         *
         * @see onShowModalHook
         */
        function onLookupStart($activator, check_only, halted) {
            OUT.debug("LOOKUP START | $activator =", $activator);
            if (check_only || halted) { return undefined }
            clearSearchResultsData($row);
            setSearchTermsData($row);
            setOriginalValues($row);
            clearFlash();
        }

        /**
         * Invoked to update form fields when the popup closes.
         *
         * @param {jQuery}  $activator
         * @param {boolean} check_only
         * @param {boolean} [halted]
         *
         * @returns {EventHandlerReturn}
         *
         * @see onHideModalHook
         */
        function onLookupComplete($activator, check_only, halted) {
            OUT.debug("LOOKUP COMPLETE | $activator =", $activator);
            if (check_only || halted) { return undefined }

            const func  = "onLookupComplete";
            let message = Emma.Messages.lookup.no_changes;
            const data  = getFieldResultsData($row);

            if (isPresent(data)) {
                const $cells  = dataCells($row);
                const updates = { Added: [], Changed: [], Removed: [] };
                for (const [field, value] of Object.entries(data)) {
                    const $field = dataField($cells, field, func);
                    if (isMissing($field)) {
                        // No addition to updates.
                    } else if (!value) {
                        updates.Removed.push(field);
                    } else if (getCellCurrentValue($field)?.nonBlank) {
                        updates.Changed.push(field);
                    } else {
                        updates.Added.push(field);
                    }
                }
                message = $.map(compact(updates), (fields, update_type) => {
                    const items = pluralize(Emma.Messages.item, fields.length);
                    const label = `${update_type} ${items}`;
                    const cells = dataFields($cells, fields).toArray();
                    const names = cells.map(cell =>
                        $(cell).find('.label .text').first().text()
                    ).sort().join(", ");
                    const type  = `<span class="type">${label}:</span>`;
                    const list  = `<span class="list">${names}.</span>`;
                    return `${type} ${list}`;
                }).join("\n");

                // NOTE: This is a hack due to the way that publication date is
                //  handled versus copyright year.
/*
            if (Object.keys(data).includes("emma_publicationDate")) {
                const $input = formField("emma_publicationDate", $row);
                const $label = $input.siblings(`[for="${$input.attr('id')}"]`);
                $input.attr("title", $label.attr("title"));
                $input.prop({ readonly: false, disabled: false });
                [$input, $label].forEach($e => {
                    $e.css("display","revert").toggleClass("disabled", false)
                });
            }
*/

                // Update the ManifestItem with the updated data.
                // noinspection JSCheckFunctionSignatures
                postRowUpdate($row, data);
            }

            flashMessage(message, { refocus: $button });
        }
    }

    /**
     * Enable bibliographic lookup.
     *
     * @param {Selector} row
     * @param {boolean}  [enable]     If **false** run {@link disableLookup}.
     * @param {boolean}  [forbid]     If **true** add ".forbidden" if disabled.
     *
     * @returns {jQuery}              The submit button.
     */
    function enableLookup(row, enable, forbid) {
        return enableRowButton(row, "lookup", enable, forbid);
    }

    /**
     * Disable bibliographic lookup.
     *
     * @param {Selector} row
     * @param {boolean}  [forbid]     If **true** add ".forbidden".
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
        OUT.debug("setLookupCondition: row =", row);
        const condition = value || evaluateLookupCondition(row);
        lookupButton(row).data(LOOKUP_CONDITION_DATA, condition);
        return condition;
    }

    /**
     * Set the field value(s) for bibliographic lookup to the initial state.
     *
     * @param {Selector} row
     */
    function clearLookupCondition(row) {
        OUT.debug("clearLookupCondition: row =", row);
        lookupButton(row).removeData(LOOKUP_CONDITION_DATA);
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
        OUT.debug("updateLookupCondition: row =", row);
        const $row    = dataRow(row);
        const $button = lookupButton($row);
        let forbid, enable = false;
        if (isDefined(permit)) {
            forbid = !permit;
        } else {
            forbid = partnerRepository(repositoryFor($row));
        }
        if (forbid) {
            clearLookupCondition($row);
        } else {
            const condition = setLookupCondition($row);
            enable ||= Object.values(condition.or).some(v => v);
            enable ||= Object.values(condition.and).every(v => v);
        }
        clearSearchTermsData($button);
        clearSearchResultsData($button);
        enableLookup($button, enable, forbid);
    }

    /**
     * Determine the readiness of a row for bibliographic lookup.
     *
     * @param {Selector} row
     *
     * @returns {LookupCondition}
     */
    function evaluateLookupCondition(row) {
        const func      = "evaluateLookupCondition";
        OUT.debug(`${func}: row =`, row);
        const $row      = dataRow(row);
        const $cells    = dataCells($row);
        OUT.debug(`${func}: $cells =`, $cells);
        const condition = LookupRequest.blankLookupCondition();
        for (const [logical_op, entry] of Object.entries(condition)) {
            for (const [field, _] of Object.entries(entry)) {
                const $field = dataField($cells, field, func);
                const valid  = isPresent($field) && getCellValid($field);
                const value  = valid && getCellCurrentValue($field);
                condition[logical_op][field] = value && value.nonBlank;
            }
        }
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
        const func = "setOriginalValues"; OUT.debug(`${func}: row =`, row);
        const $row = dataRow(row);
        let values;
        if (data) {
            values = deepDup(data);
        } else {
            const $cells = dataCells($row);
            values = toObject(LookupModal.DATA_COLUMNS, field => {
                const $field = dataField($cells, field, func);
                return $field && getCellCurrentValue($field)?.value;
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
        OUT.debug("setSearchTermsData:", row, (value || "-"));
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
        OUT.debug("clearSearchTermsData: row =", row);
        return lookupButton(row).removeData(LookupModal.SEARCH_TERMS_DATA);
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
        OUT.debug("updateSearchTermsData: event =", event);
        const $button = $(event.currentTarget || event.target);
        if ($button.prop("disabled")) { return }
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
        const func      = "generateLookupRequest"; OUT.debug(func, row, value);
        const request   = new LookupRequest();
        const $row      = dataRow(row);
        const $cells    = dataCells($row);
        const condition = value || getLookupCondition(row);
        for (const [_logical_op, entry] of Object.entries(condition)) {
            for (const [field, active] of Object.entries(entry)) {
                if (active) {
                    const $fld   = dataField($cells, field, func);
                    const values = $fld && getCellCurrentValue($fld)?.value;
                    if (isPresent(values)) {
                        const prefix = LookupRequest.LOOKUP_PREFIX[field];
                        if (prefix === "") {
                            request.add(values);
                        } else {
                            request.add(values, (prefix || "keyword"));
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

    /**
     * Clear the search terms from the button.
     *
     * @param {Selector} row
     *
     * @returns {jQuery}
     */
    function clearSearchResultsData(row) {
        OUT.debug("clearSearchResultsData: row =", row);
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
        const func  = "postRowUpdate";
        const $row  = dataRow(changed_row);
        const item  = getManifestItemId($row);

        if (!item) {
            OUT.error(`${func}: no record ID for $row =`, $row);
            return;
        }
        if (isEmpty(new_values)) {
            OUT.error(`${func}: no data field changes`);
            return;
        }

        const row   = dbRowValue($row);
        const delta = dbRowDelta($row);
        const data  = { row: row, delta: delta, ...new_values };

        serverItemSend(`row_update/${item}`, {
            caller:     func,
            params:     { manifest_item: data },
            onSuccess:  (body => parseRowUpdateResponse($row, body)),
        });
    }

    /**
     * Receive updated fields for the item, plus problem reports, plus invalid
     * fields for each item that would prevent a save from occurring.
     *
     * @param {Selector}       row
     * @param {UpdateResponse} body
     *
     * @see "ManifestItemConcern#finish_editing"
     * @see "Manifest::ItemMethods#pending_items_hash"
     * @see "ActiveModel::Errors"
     */
    function parseRowUpdateResponse(row, body) {
        OUT.debug("parseRowUpdateResponse: body =", body);
        parseUpdateResponse(row, body);
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
        const func  = "repositoryFor";
        const field = ["repository", "emma_repository"];
        const $cell = dataField(row, field, func);
        return $cell && getCellCurrentValue($cell)?.value;
    }

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
    const UPLOADER_DATA = "uploader";

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
        //OUT.debug("setUploader: row =", row);
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
        //OUT.debug("newUploader: row =", row);
        // noinspection JSUnusedGlobalSymbols
        const cbs      = { onSelect, onStart, onError, onSuccess };
        const $row     = dataRow(row);
        const features = { debugging: DEBUG };
        const instance = new MultiUploader($row, ITEM_MODEL, features, cbs);
        const func     = "uploader";
        let name_shown;

        // Clear display elements of an existing uploader.
        if (instance.isUppyInitialized()) {
            instance.$root.find(FILE_SELECT).remove();
            instance.$root.find(MultiUploader.DISPLAY).empty();
        }

        // Ensure that the uploader is fully initialized and set up handlers
        // for added input controls.
        instance.initialize({ added: initializeAddedControls });

        return instance;

        /**
         * Callback invoked when the file select button is pressed.
         *
         * @param {ElementEvt} [event]    Ignored.
         */
        function onSelect(event) {
            const cb_func = `${func}: onSelect`;
            OUT.debug(`${cb_func}: event =`, event);
            clearFlash();
            const ensure_item_record = () => {
                if (!getManifestItemId($row)) {
                    OUT.debug(`${cb_func}: triggering manifest item creation`);
                    createManifestItem($row);
                }
            };
            if (!manifestId()) {
                OUT.debug(`${cb_func}: triggering manifest creation`);
                createManifest(undefined, ensure_item_record);
            } else {
                ensure_item_record();
            }
        }

        /**
         * This event occurs between the "file-added" and "upload-started"
         * events. <p/>
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
            OUT.debug(`${func}: onStart: data =`, data);
            clearFlash();
            name_shown = instance.isFilenameDisplayed();
            instance.hideFilename(); // Make room for .uploader-feedback
            return compact({
                id:          getManifestItemId($row),
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
         * @param {{status: number, body: string}} [_response]
         */
        function onError(file, error, _response) {
            OUT.debug(`${func}: onError: file =`, file);
            flashError(error?.message || error);
            if (name_shown) { instance.hideFilename(false) }
        }

        /**
         * This event occurs when the response from POST /manifest_item/upload
         * is received with success status (200).  At this point, the file has
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
            OUT.debug(`${func}: onSuccess: file =`, file);

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
                const updated = updateDataRow($row, emma_data);
                if (isPresent(updated)) {
                    postRowUpdate($row, updated);
                }
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
            OUT.debug(`${func}: initializeAddedControls:`, container);

            /** @type {jQuery} */
            const $cell = $row.find(UPLOADER_CELL),
                  $name = $cell.find(UPLOADED_NAME),
                  $from = $name.children();
            const HOVER = "data-hover";
            const attrs = [...ID_ATTRIBUTES, "data-id"];

            $(container).each((_, element) => {
                const $elem   = uniqAttrsTree(element, undefined, attrs);
                const type    = $elem.attr("data-type");
                const $type   = $from.filter(`.from-${type}`);

                const popup   = new InlinePopup($elem);
                const $toggle = popup.modalControl;
                const $panel  = popup.modalPanel;
                const $input  = $panel.find('input');
                const $submit = $panel.find('button.input-submit');
                const $cancel = $panel.find('button.input-cancel');

                // handleEvent($input, "keyup", onInput); // See function def.
                handleClickAndKeypress($submit, onSubmit);
                handleClickAndKeypress($cancel, onCancel);

                handleHoverAndFocus($toggle, hoverToggle, unhoverToggle);
                ModalShowHooks.set($toggle, onShow);
                ModalHideHooks.set($toggle, onHide);


                /**
                 * Make the **Enter** key a proxy for {@link onSubmit}.
                 *
                 * @note This is not currently compatible with shared/grids.js.
                 *
                 * @param {KeyboardEvt} event
                 *
                 * @returns {EventHandlerReturn}
                 */
/*
                function onInput(event) {
                    OUT.debug("onInput: event =", event);
                    const key = keyCombo(event);
                    if (key === "Enter") {
                        event.stopImmediatePropagation();
                        $submit.trigger("click");
                        return false;
                    }
                }
*/

                /**
                 * If a value was given update the displayed file value and
                 * send the new file_data value to the server.
                 *
                 * @param {ElementEvt} event
                 */
                function onSubmit(event) {
                    OUT.debug("onSubmit: event =", event);
                    const value = $input.val()?.trim();
                    if (value) {
                        setUploaderDisplayValue($cell, value, type);
                        const file_data = { [type]: value };
                        atomicEdit($cell, file_data);
                    }
                    popup.close();
                }

                /**
                 * Just close the modal.
                 *
                 * @param {ElementEvt} event
                 */
                function onCancel(event) {
                    OUT.debug("onCancel: event =", event);
                    popup.close();
                }

                /**
                 * Add an attribute to the cell element indicating the button
                 * being hovered, allowing for CSS rules relative to the cell.
                 *
                 * @param {ElementEvt} _event
                 */
                function hoverToggle(_event) {
                    //OUT.debug("hoverToggle: event =", _event);
                    $cell.attr(HOVER, type);
                }

                /**
                 * Remove the attribute unless it has been changed by something
                 * else.
                 *
                 * @param {ElementEvt} _event
                 */
                function unhoverToggle(_event) {
                    //OUT.debug("unhoverToggle: event =", _event);
                    if ($cell.attr(HOVER) === type) {
                        $cell.removeAttr(HOVER);
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
                    OUT.debug("onShow:", $target, check_only, halted);
                    if (check_only || halted) { return }
                    const value = $type.text()?.trim();
                    if (value) {
                        $input.val(value);
                    }
                    delayedBy(50, adjustGridHeight)();
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
                    OUT.debug("onHide:", $target, check_only, halted);
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
                        grid_height = $grid.prop("style").height;
                        grid_resize = true;
                        const old_ht    = grid_box.height;
                        const scrollbar = old_ht - $grid[0].clientHeight;
                        $grid.css("height", (old_ht + obscured + scrollbar));
                    }
                }

                /**
                 * If the grid was temporarily resized, restore the element by
                 * removing the fixed height value set above.
                 */
                function restoreGridHeight() {
                    if (grid_resize) {
                        $grid.prop("style").height = grid_height;
                        grid_resize = grid_height = undefined;
                    }
                }
            });

            const $upload = instance.fileSelectButton();
            const type    = "uploader";
            handleHoverAndFocus($upload, hoverUpload, unhoverUpload);

            /**
             * Add an attribute to the cell element indicating the button
             * being hovered, allowing for CSS rules relative to the cell.
             *
             * @param {ElementEvt} _event
             */
            function hoverUpload(_event) {
                //OUT.debug("hoverUpload: event =", _event);
                $cell.attr(HOVER, type);
            }

            /**
             * Remove the attribute unless it has been changed by something
             * else.
             *
             * @param {ElementEvt} _event
             */
            function unhoverUpload(_event) {
                //OUT.debug("unhoverUpload: event =", _event);
                if ($cell.attr(HOVER) === type) {
                    $cell.removeAttr(HOVER);
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
        //OUT.debug("initializeUploader: row =", row);
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
        OUT.debug('setupUploader: target =', target);
        dataRows(target, true).each((_, row) => initializeUploader(row));
    }

    // ========================================================================
    // Functions - row - grid row index
    // ========================================================================

    /**
     * Name of the row attribute specifying the relative position of the row
     * within a "virtual grid" which spans pagination. <p/>
     *
     * Header row(s) always have the same index value (starting with 1)
     * regardless of the page; data rows have index values within a range that
     * increases with the page number.
     *
     * @type {string}
     */
    const GRID_ROW_INDEX_ATTR = "aria-rowindex";

    /**
     * The start of CSS class names related to the ordering of grid-spanning
     * elements within the grid container.  The range of values is the same
     * regardless of the page.
     *
     * @type {string}
     */
    const ROW_CLASS_PREFIX = "row-";

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
     * The number portion of the CSS "row-N" class.
     *
     * @param {Selector} target
     * @param {string}   [prefix]
     *
     * @returns {number|undefined}
     */
    function gridRowClassNumber(target, prefix = ROW_CLASS_PREFIX) {
        const cls = getClass(target, prefix);
        return cls && Number(cls.replace(prefix, "")) || undefined;
    }

    /**
     * Renumber grid row indexes and rewrite delta values so that ordering
     * database records on [row, delta] will yield the same order as what
     * appears on the screen. <p/>
     *
     * This mitigates the case where a row is inserted within a range of
     * inserted rows (rather than at the end of the range where it's highest
     * delta number would appropriately reflect its ordinal position).
     */
    function updateGridRowIndexes() {
        OUT.debug("updateGridRowIndexes");
        const $rows   = allDataRows();
        const first_c = `${ROW_CLASS_PREFIX}first`; // E.g. "row-first"
        const last_c  = `${ROW_CLASS_PREFIX}last`;  // E.g. "row-last"
        const start_i = gridRowIndex($rows.first());
        const start_c = gridRowClassNumber($rows.first());
        let row_index = start_i || gridRowIndex(headerRow())       || 1;
        let row_class = start_c || gridRowClassNumber(headerRow()) || 1;
        let last_row_value, last_row_delta;

        $rows.each((_, row) => {
            const $row = $(row);
            $row.removeClass([first_c, last_c]);
            replaceClass($row, "row-", row_class++);
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
     * Respond to the given increase (or decrease) in the number of displayed
     * grid rows.
     *
     * @param {number} by
     */
    function updateGridRowCount(by) {
        OUT.debug("updateGridRowCount: by", by);
        changeItemCounts(by);
        updateDeleteButtons();
        updateGridRowIndexes();
    }

    // ========================================================================
    // Functions - row - database row/delta
    // ========================================================================

    const DB_ROW_ATTR   = "data-item-row";
    const DB_DELTA_ATTR = "data-item-delta";

    const DB_ROW_DATA   = "itemRow";
    const DB_DELTA_DATA = "itemDelta";

    /**
     * ManifestItem "row" column value for the row. <p/>
     *
     * Inserted rows will have the same value for this as the template row from
     * which they were created.
     *
     * @param {Selector} target       Row or cell.
     *
     * @returns {number}
     */
    function dbRowValue(target) {
        const $row  = dataRow(target);
        const value = $row.data(DB_ROW_DATA);
        return value || 0;
    }

    /**
     * Set the ManifestItem "row" column value for the row.
     *
     * @param {Selector}                target      Row or cell.
     * @param {string|number|undefined} setting
     *
     * @returns {number}
     */
    function setDbRowValue(target, setting) {
        //OUT.debug(`setDbRowValue: setting = "${setting}"; target =`, target);
        const $row   = dataRow(target);
        const number = Number(setting);
        const value  = number || 0;
        if (number) { $row.removeAttr(DB_ROW_ATTR) }
        $row.data(DB_ROW_DATA, value);
        return value;
    }

    /**
     * ManifestItem "row" column value for the row. <p/>
     *
     * Inserted rows will have the same value for this as the template row from
     * which they were created.
     *
     * @param {jQuery} $row
     *
     * @returns {number}
     */
    function initializeDbRowValue($row) {
        const attr = $row.attr(DB_ROW_ATTR);
        return attr ? setDbRowValue($row, attr) : dbRowValue($row);
    }

    /**
     * ManifestItem "delta" column value for the row. <p/>
     *
     * A value of 1 or greater indicates that the row has been inserted but has
     * not yet been finalized via Save.
     *
     * @param {Selector} target       Row or cell.
     *
     * @returns {number}
     */
    function dbRowDelta(target) {
        const $row  = dataRow(target);
        const value = $row.data(DB_DELTA_DATA);
        return value || 0;
    }

    /**
     * Set (or clear) the ManifestItem "delta" column value for the row. <p/>
     *
     * Clearing (setting to 0) declares the row to represent a real (persisted)
     * ManifestItem record.
     *
     * @param {Selector}                     target     Row or cell.
     * @param {string|number|null|undefined} setting
     *
     * @returns {number}
     */
    function setDbRowDelta(target, setting) {
        //OUT.debug(`setDbRowDelta: setting = "${setting}"; target =`, target);
        const $row   = dataRow(target);
        const number = Number(setting);
        const value  = number || 0;
        if (number) { $row.removeAttr(DB_DELTA_ATTR) }
        $row.data(DB_DELTA_DATA, value);
        return value;
    }

    /**
     * ManifestItem "delta" column value for the row. <p/>
     *
     * A value of 1 or greater indicates that the row has been inserted but has
     * not yet been finalized via Save.
     *
     * @param {jQuery} $row
     *
     * @returns {number}
     */
    function initializeDbRowDelta($row) {
        const attr = $row.attr(DB_DELTA_ATTR);
        return attr ? setDbRowDelta($row, attr) : dbRowDelta($row);
    }

    /**
     * Replace item row/delta values.
     *
     * @param {Selector}            target
     * @param {ManifestItem|number} data
     *
     * @see "ManifestController#save"
     */
    function updateDbRowDelta(target, data) {
        const func = "updateDbRowDelta";
        const $row = $(target);
        OUT.debug(`${func}: target = `, target, "data =", data);
        if (isEmpty(data)) {
            OUT.debug(`${func}: no data supplied`);
        } else if (typeof data === "number") {
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
     * @see "ManifestController#save"
     */
    function updateRowValues(table) {
        const func = "updateRowValues"; OUT.debug(`${func}: table =`, table);
        allDataRows().each((_, row) => {
            const $row  = $(row);
            const db_id = getManifestItemId($row);
            const entry = db_id && table[db_id];
            if (isMissing(db_id)) {
                OUT.debug(`${func}: no db_id for $row =`, $row);
            } else if (isEmpty(entry)) {
                OUT.debug(`${func}: no response data for db_id ${db_id}`);
            } else {
                updateDbRowDelta($row, entry);
                // noinspection JSCheckFunctionSignatures
                updateDataRow($row, entry);
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
    const STATUS_DEFAULT = "missing";

    /**
     * Indicate whether the item record is in its initial state.
     *
     * @param {ManifestItem|undefined} data
     *
     * @returns {boolean}
     *
     * @see "ManifestItem::StatusMethods#initial?"
     */
    function isInitialData(data) {
        const updated_at = timestamp(data?.updated_at);
        const created_at = timestamp(data?.created_at);
        return (updated_at === created_at);
    }

    /**
     * Indicate whether the item represents unsaved data.
     *
     * @param {ManifestItem|undefined} data
     *
     * @returns {boolean}
     *
     * @see "ManifestItem::StatusMethods#unsaved?"
     */
    function isUnsavedData(data) {
        if (isInitialData(data)) {
            return false;
        } else {
            const last_saved = timestamp(data?.last_saved);
            const updated_at = timestamp(data?.updated_at);
            return !last_saved || (last_saved < updated_at);
        }
    }

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
        if (isUnsavedData(data)) {
            data.ready_status = "unsaved";
        } else if (!hasKey(data, "ready_status") && !isInitialData(data)) {
            data.ready_status = "ready";
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
     * @param {Selector} target       Row or cell.
     *
     * @returns {jQuery}
     */
    function rowIndicatorPanel(target) {
        return dataRow(target).find(`${CONTROLS_CELL} ${INDICATORS}`);
    }

    /**
     * All indicator value elements for the row.
     *
     * @param {Selector} target       Row or cell.
     *
     * @returns {jQuery}
     */
    function rowIndicators(target) {
        return rowIndicatorPanel(target).find(INDICATOR);
    }

    /**
     * Reset the given indicator to the starting state.
     *
     * @param {Selector} target       Row or cell.
     * @param {string}   type
     *
     * @see "ManifestItem::Config::STATUS"
     */
    function clearRowIndicator(target, type) {
        OUT.debug(`clearRowIndicator: ${type}; target =`, target);
        updateRowIndicator(target, type, STATUS_DEFAULT);
    }

    /**
     * Modify the given indicator's CSS and displayed text.
     *
     * @param {Selector} target       Row or cell.
     * @param {string}   type
     * @param {string}   [status]
     * @param {string}   [text]
     *
     * @see "ManifestItem::Config::STATUS"
     */
    function updateRowIndicator(target, type, status, text) {
        const func       = "updateRowIndicator";
        const value      = status || STATUS_DEFAULT;
        const $indicator = rowIndicators(target).filter(`.${type}`);
        OUT.debug(`${func}: ${type}: status = "${status}"`);

        // Update status text description.
        const label = isDefined(text) ? text : statusLabel(type, value);
        const l_id  = $indicator.attr("aria-describedby");
        let $label;
        if (isPresent(l_id)) {
            $label  = $(`#${l_id}`);
        } else {
            $label  = $indicator.next('.label');
            OUT.warn(`${func}: no id for`, $indicator);
        }
        $label.text(label);
        $indicator.attr("title", label);

        // Update indicator CSS.
        replaceClass($indicator, "value-", value);
    }

    /**
     * Modify status indicators for a row based on the status values given by
     * *data*.
     *
     * @param {Selector}                          target    Row or cell.
     * @param {ManifestItemData|object|undefined} data
     */
    function updateRowIndicators(target, data) {
        //OUT.debug("updateRowIndicators: target =", target);
        const $row   = dataRow(target);
        const status = statusData(data);
        for (const [type, value] of Object.entries(status)) {
            updateRowIndicator($row, type, value);
        }
    }

    /**
     * Clear all status indicators for a row.
     *
     * @param {Selector} target       Row or cell.
     */
    function resetRowIndicators(target) {
        //OUT.debug("resetRowIndicators: target =", target);
        const $row = dataRow(target);
        STATUS_TYPES.forEach(type => clearRowIndicator($row, type));
    }

    /**
     * Ensure that indicators have the appropriate tooltip from the start.
     *
     * @param {jQuery} $row
     */
    function initializeRowIndicators($row) {
        //OUT.debug("initializeRowIndicators: $row =", $row);
        const $panel = rowIndicatorPanel($row);
        $panel.find(INDICATOR).each((_, indicator) => {
            const $indicator = $(indicator);
            const tooltip    = $indicator.attr("title");
            const label_id   = $indicator.attr("aria-describedby");
            if (label_id && !tooltip) {
                const $label = $panel.find(`#${label_id}`);
                $indicator.attr("title", $label.text());
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
    function getRowDetailsItems(target) {
        const $row = dataRow(target);
        return $row.find(`${CONTROLS_CELL} ${DETAILS} ${ROW_FIELD}`);
    }

    /**
     * Update row details entries from supplied field values.
     *
     * @param {Selector}                          target
     * @param {ManifestItemData|object|undefined} data
     *
     * @see "ManifestItemDecorator#row_details"
     * @see "ManifestItemDecorator#row_field_error_details"
     */
    function updateRowDetailsItems(target, data) {
        //OUT.debug("updateRowDetailsItems: target =", target);
        if (isEmpty(data)) { return }
        const html_encode = (s) => htmlEncode(s);
        getRowDetailsItems(target).each((_, item) => {
            const $item = $(item);
            const field = $item.attr(FIELD_ATTR);
            if (hasKey(data, field)) {
                $item.empty();
                const value = presence(data[field]) || BLANK_DETAIL_VALUE;
                if (isObject(value)) {
                    const $list = $('<dl>').appendTo($item);
                    for (const [fld, errs] of Object.entries(value)) {
                        let parts;
                        if (isObject(errs)) {
                            // noinspection JSCheckFunctionSignatures
                            parts = Object.entries(errs).map(kv => {
                                const [k, v] = kv.map(html_encode);
                                const key = `<span class="quoted">${k}</span>`;
                                const val = `<span>${v}</span>`;
                                return `<div>${key}: ${val}</div>`;
                            });
                        } else {
                            parts = arrayWrap(errs).map(html_encode);
                        }
                        $list.append($('<dt>').text(fld));
                        $list.append($('<dd>').html(parts.join("\n")));
                    }
                    $item.append($list);
                } else if (Array.isArray(value)) {
                    $item.html(value.map(html_encode).join("<br/>\n"));
                } else {
                    $item.text(value || BLANK_DETAIL_VALUE);
                }
            }
        });
    }

    /**
     * Set all row details entries to {@link BLANK_DETAIL_VALUE}.
     *
     * @param {Selector} target
     */
    function resetRowDetailsItems(target) {
        //OUT.debug("resetRowDetailsItems: target =", target);
        const $items = getRowDetailsItems(target);
        $items.each((_, item) => $(item).empty().text(BLANK_DETAIL_VALUE));
    }

    // ========================================================================
    // Functions - row - changed state
    // ========================================================================

    /**
     * Name of the data() entry indicating whether the data row has changed.
     *
     * @type {string}
     */
    const ROW_CHANGED_DATA = "changed";

    /**
     * Indicate whether any of the cells of the related data row have changed.
     * <p/>
     *
     * An undefined result means that the row hasn't been evaluated.
     *
     * @param {Selector} row
     *
     * @returns {boolean|undefined}
     */
    function getRowChanged(row) {
        return dataRow(row).data(ROW_CHANGED_DATA);
    }

    /**
     * Set the related data row's changed state.
     *
     * @param {Selector} row
     * @param {boolean}  [setting]    If **false**, set as unchanged.
     *
     * @returns {boolean}
     */
    function setRowChanged(row, setting) {
        //OUT.debug(`setRowChanged: "${setting}"; row =`, row);
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
        OUT.debug(`updateRowChanged: "${setting}"; row =`, row);
        const $row   = dataRow(row)
        const change = isDefined(setting) ? setting : evaluateRowChanged($row);
        setRowChanged($row, change);
        $row.toggleClass(CHANGED_MARKER, change);
        return change;
    }

    /**
     * Evaluate whether any of a row's data cells have changed. <p/>
     *
     * (No changes are made to element attributes or data.)
     *
     * @param {Selector} row          Row or cell.
     *
     * @returns {boolean}
     */
    function evaluateRowChanged(row) {
        OUT.debug("evaluateRowChanged: row =", row);
        const $row    = dataRow(row);
        const changed = (change, cell) => evaluateCellChanged(cell) || change;
        return dataCells($row).toArray().reduce(changed, false);
    }

    /**
     * Consult row .data() to determine if the row has changed and only attempt
     * to re-evaluate if that result is missing. <p/>
     *
     * (No changes are made to element attributes or data.)
     *
     * @param {Selector} row          Row or cell.
     *
     * @returns {boolean}
     */
    function checkRowChanged(row) {
        //OUT.debug("checkRowChanged: row =", row);
        const $row  = dataRow(row);
        let changed = getRowChanged($row);
        if (notDefined(changed)) {
            const check = (change, cell) => change || getCellChanged(cell);
            changed = dataCells($row).toArray().reduce(check, false) || false;
        }
        return changed;
    }

    /**
     * Remove the original value data item for the associated cell.
     *
     * @param {Selector} row          Row or cell.
     */
    function clearRowChanged(row) {
        //OUT.debug("clearRowChanged: row =", row);
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
    const $template_row = $grid.find(TEMPLATE_ROW);

    /**
     * Create an empty unattached data row based on a previous data row. <p/>
     *
     * The {@link ITEM_ATTR} attribute is removed so that editing logic knows
     * this is a row unrelated to any ManifestItem record.
     *
     * @param {Selector} [original]         Source data row.
     * @param {boolean}  [clear_errors]     If **true**, remove error status.
     *
     * @returns {jQuery}
     */
    function emptyDataRow(original, clear_errors) {
        OUT.debug("emptyDataRow: original =", original);
        const $copy = cloneDataRow(original);
        clearManifestItemId($copy);
        initializeDataCells($copy, clear_errors);
        resetRowIndicators($copy);
        resetRowDetailsItems($copy);
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
        //OUT.debug("cloneDataRow: original =", original);
        const $row  = original ? dataRow(original) : $template_row;
        const $copy = $row.clone();

        //_debugWantNoDataValues($copy, "$copy");

        // If the row is being inserted after an inserted row, look to the
        // original row for information.
        const row   = dbRowValue($row);
        const delta = nextDeltaCounter(row);
        setDbRowValue($copy, row);
        setDbRowDelta($copy, delta);

        // Make numbered attributes unique for the row element itself and all
        // of the elements within it.
        uniqAttrsTree($copy, delta);
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
        return dataCells(undefined, hidden);
    }

    /**
     * All grid data cells for the given target.
     *
     * @param {Selector} [target]     Default: {@link allDataRows}.
     * @param {boolean}  [hidden]     Include hidden rows.
     *
     * @returns {jQuery}
     */
    function dataCells(target, hidden) {
        const $t    = target && $(target);
        const match = DATA_CELL;
        if ($t?.is(match)) { return $t }
        const $row  = $t?.is(DATA_ROW) ? $t : dataRows($t, hidden);
        return $row.children(match);
    }

    /**
     * Get the single grid data cell associated with the target.
     *
     * @param {Selector} cell         A cell or element inside a cell.
     *
     * @returns {jQuery}
     */
    function dataCell(cell) {
        const func = "dataCell"; //OUT.debug(`${func}: cell =`, cell);
        return selfOrParent(cell, DATA_CELL, func);
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
        return dataCells(target).filter(selectors.join(", "));
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
        const func = caller || "dataField";
        OUT.warn(`${func}: no dataCell with ${match} in target =`, target);
    }

    /**
     * Get the database ManifestItem table column associated with the target.
     *
     * @param {Selector} cell         A cell or element inside a cell.
     *
     * @returns {string}
     */
    function cellDbColumn(cell) {
        return dataCell(cell).attr(FIELD_ATTR);
    }

    /**
     * Get the properties of the field associated with the target.
     *
     * @param {Selector} cell         A cell or element inside a cell.
     *
     * @returns {Properties}
     */
    function cellProperties(cell) {
        const func   = "cellProperties";
        const field  = cellDbColumn(cell);
        const result = field && fieldProperty()[field];
        if (!field) {
            OUT.error(`${func}: no ${FIELD_ATTR} for`, cell);
        } else if (!result) {
            OUT.error(`${func}: no entry for "${field}"`);
        }
        return result || {};
    }

    /**
     * Use received data to update cell(s) associated with data values.
     *
     * @param {Selector} cell         A cell or element inside a cell.
     * @param {*}        data         Converted to {@link Field.Value}
     * @param {boolean}  [changed]    Def.: check {@link getCellOriginalValue}
     * @param {boolean}  [valid]
     *
     * @returns {boolean}             Whether the cell value changed.
     */
    function dataCellUpdate(cell, data, changed, valid) {
        OUT.debug("dataCellUpdate: data =", data, cell);
        const $cell     = dataCell(cell);
        const value     = $cell.makeValue(data);
        const original  = getCellOriginalValue($cell);
        let was_changed = changed;
        if (notDefined(original)) {
            setCellOriginalValue($cell, value);
        } else if (notDefined(was_changed)) {
            was_changed = value.differsFrom(original);
        }
        setCellCurrentValue($cell, value);
        setCellDisplayValue($cell, value);
        updateCellValid($cell, valid);
        return was_changed;
    }

    // ========================================================================
    // Functions - cell - initialization
    // ========================================================================

    /**
     * Prepare all of the data cells within the target data row.
     *
     * @param {Selector} target
     * @param {boolean}  [clear_errors]     If **true**, remove error status.
     */
    function initializeDataCells(target, clear_errors) {
        OUT.debug("initializeDataCells: target =", target);
        const $cells = dataCells(target);
        $cells.each((_, cell) => initializeDataCell(cell, clear_errors));
    }

    /**
     * Prepare the single data cell associated with the target.
     *
     * @param {Selector} cell               A cell or element inside a cell.
     * @param {boolean}  [clear_errors]     If **true**, remove error status.
     *
     * @returns {jQuery}
     */
    function initializeDataCell(cell, clear_errors) {
        //OUT.debug("initializeDataCell: cell =", cell);
        const $cell = dataCell(cell);
        turnOffAutocompleteIn($cell);
        cellEditClear($cell);
        cellDisplayClear($cell, clear_errors);
        refreshDataCell($cell, clear_errors);
        return $cell;
    }

    /**
     * Reset cell stored data values and refresh cell display.
     *
     * @param {Selector} cell               A cell or element inside a cell.
     * @param {boolean}  [reset_uploader]   Also reset uploader cell.
     *
     * @returns {jQuery}
     */
    function resetDataCell(cell, reset_uploader) {
        //OUT.debug("resetDataCell: cell =", cell);
        const $cell = dataCell(cell);
        if (reset_uploader || !$cell.is(UPLOADER_CELL)) {
            clearCellOriginalValue($cell);
            clearCellCurrentValue($cell);
            clearCellChanged($cell);
            refreshDataCell($cell);
        }
        return $cell;
    }

    /**
     * Refresh cell display.
     *
     * @param {Selector} cell               A cell or element inside a cell.
     * @param {boolean}  [clear_errors]     If **true**, remove error status.
     *
     * @returns {jQuery}
     */
    function refreshDataCell(cell, clear_errors) {
        //OUT.debug("refreshDataCell: cell =", cell);
        const $cell = dataCell(cell);
        if (clear_errors) {
            $cell.removeClass(ALL_STATUS_MARKERS);
        } else {
            $cell.removeClass(STATUS_MARKERS);
            updateCellDisplayValue($cell);
        }
        return $cell;
    }

    /**
     * Attach handlers for editing in all of the data cells associated with
     * the row.
     *
     * @param {jQuery} $row
     */
    function setupDataCellEditing($row) {
        OUT.debug("setupDataCellEditing: $row =", $row);
        dataCells($row, true).each((_, cell) => setupCellNavGroup(cell));
    }

    /**
     * Create the appropriate NavGroup subclass for handling activation and
     * navigation within a grid cell.
     *
     * @param {Selector} cell
     */
    function setupCellNavGroup(cell) {
        const func  = "setupCellNavGroup"; OUT.debug(`${func}:`, cell);
        const $cell = $(cell);

        let group   = NavGroup.instanceFor($cell);
        if (group) {
            OUT.debug(`${func}: ${group.CLASS_NAME} EXISTS FOR`, $cell);
        } else if ($cell.is(`${DATA_HEAD}[data-readonly]`)) {
            OUT.debug(`${func}: HIDDEN DATA_HEAD - $cell =`, $cell);
            return; // @see BaseDecorator::Grid::grid_head_cell
        } else if ($cell.is('.array.enum.multi')) {
            group   = CheckboxGroup.setupFor($cell);
        } else if ($cell.is('.array.enum')) {
            group   = MenuGroup.setupFor($cell);
        } else if ($cell.is('.array.multi')) {
            group   = SingletonGroup.setupFor($cell);
        } else if ($cell.is('.array')) {
            group   = TextInputGroup.setupFor($cell);
        } else {
            group   = SingletonGroup.setupFor($cell, true);
            group ||= CellControlGroup.setupFor($cell);
        }

        if (!group) {
            OUT.error(`${func}: NO NAV GROUP FOR $cell =`, $cell);

        } else if ($cell.is(CONTROLS_HEAD)) {
            OUT.debug(`${func}: CONTROLS_HEAD - $cell =`, $cell);
            group.addCallback("activate", onNavGroupGridControls);

        } else if ($cell.is(DATA_HEAD)) {
            OUT.debug(`${func}: DATA_HEAD - $cell =`, $cell);
            // No callback currently defined for this case.

        } else if ($cell.is(CONTROLS_CELL)) {
            OUT.debug(`${func}: CONTROLS_CELL - $cell =`, $cell);
            group.addCallback("activate", onNavGroupRowControls);

        } else if ($cell.is(UPLOADER_CELL)) {
            OUT.debug(`${func}: UPLOADER_CELL - $cell =`, $cell);
            group.addCallback('activate', onNavGroupUploadControls);

        } else if ($cell.is(DATA_CELL)) {
            OUT.debug(`${func}: DATA_CELL - $cell =`, $cell);
            group.addCallback("activate",   onNavGroupStartValueEdit);
            group.addCallback("deactivate", onNavGroupFinishValueEdit);

        } else {
            OUT.warn(`${func}: unexpected $cell =`, $cell);
        }
    }

    /**
     * Respond to activation of header row expand/contract control.
     *
     * @param {NavGroupCallbackOptions} arg
     *
     * @returns {boolean}
     */
    function onNavGroupGridControls(arg) {
        const func  = "onNavGroupGridControls";
        const $ctrl = arg.control && $(arg.control);
        if (!$ctrl) {
            OUT.debug(`${func}: group activated`);
            return true;

        } else if (sameElements($ctrl, headerRowToggle())) {
            OUT.debug(`${func}: header control activated`, $ctrl);
            toggleHeaderRow($ctrl);
            return true;

        } else if (sameElements($ctrl, controlsColumnToggle())) {
            OUT.debug(`${func}: column control activated`, $ctrl);
            toggleControlsColumn($ctrl);
            return true;

        } else {
            OUT.warn(`${func}: unexpected: arg =`, arg);
            return false;
        }
    }

    /**
     * Respond to activation of a per-row control.
     *
     * @param {NavGroupCallbackOptions} arg
     *
     * @returns {boolean}
     */
    function onNavGroupRowControls(arg) {
        const func  = "onNavGroupRowControls";
        const $ctrl = arg.control && $(arg.control);
        if (!$ctrl) {
            OUT.debug(`${func}: group activated`);
            return true;

        } else if (isRowButton($ctrl)) {
            OUT.debug(`${func}: row control activated`, $ctrl);
            rowOperation($ctrl);
            return true;

        } else {
            OUT.warn(`${func}: unexpected: arg =`, arg);
            return false;
        }
    }

    /**
     * Respond to activation of uploader control.
     *
     * @param {NavGroupCallbackOptions} arg
     *
     * @returns {boolean}
     */
    function onNavGroupUploadControls(arg) {
        const func  = "onNavGroupUploadControls";
        const $ctrl = arg.control && $(arg.control);
        let modal;
        if (!$ctrl) {
            OUT.debug(`${func}: group activated`);
            return true;

        } else if ($ctrl.is(MultiUploader.FILE_TYPE)) {
            OUT.debug(`${func}: upload control activated`, $ctrl);
            return false;

        } else if ((modal = InlinePopup.instanceFor($ctrl))) {
            OUT.debug(`${func}: popup control activated`, $ctrl);
            modal.toggleModal();
            return true;

        } else {
            OUT.warn(`${func}: unexpected: arg =`, arg);
            return false;
        }
    }

    /**
     * Called when the edit control is focused in the group.
     *
     * @param {NavGroupCallbackOptions} arg
     *
     * @returns {boolean}
     */
    function onNavGroupStartValueEdit(arg) {
        const func  = "onNavGroupStartValueEdit";
        const $cell = dataCell(arg.container);
        const $ctrl = arg.control && $(arg.control);
        if ($ctrl) {
            OUT.debug(`${func}: unused: $ctrl =`, $ctrl, "arg =", arg);
        } else {
            OUT.debug(`${func}: arg =`, arg);
        }
        startValueEdit($cell) && cellEdit($cell).trigger("focus");
        // TODO: move the caret to the perceived location of the mouse click
        return true;
    }

    /**
     * Called when the edit control loses focus in the group.
     *
     * @param {NavGroupCallbackOptions} arg
     *
     * @returns {boolean}
     */
    function onNavGroupFinishValueEdit(arg) {
        const func  = "onNavGroupFinishValueEdit";
        const $cell = dataCell(arg.container);
        const $ctrl = arg.control && $(arg.control);
        if ($ctrl) {
            OUT.debug(`${func}: unused: $ctrl =`, $ctrl, "arg =", arg);
        } else {
            OUT.debug(`${func}: arg =`, arg);
        }
        finishValueEdit($cell);
        return true;
    }

    // ========================================================================
    // Functions - cell - finalization
    // ========================================================================

    /**
     * Finalize data cells prior to page exit.
     *
     * @param {string}   from         "current" or "original".
     * @param {Selector} [target]     Default: {@link allDataRows}.
     */
    function finalizeDataCells(from, target) {
        OUT.debug(`finalizeDataCells: from ${from}: target =`, target);

        let v;
        const curr      = $c => getCellCurrentValue($c);
        const orig      = $c => getCellOriginalValue($c);
        const from_curr = $c => (v = curr($c)) && setCellOriginalValue($c, v);
        const from_orig = $c => (v = orig($c)) && setCellCurrentValue($c, v);
        const from_disp = $c => getCellDisplayValue($c);
        const current   = notDefined(from) || (from === "current");

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
    const VALUE_CHANGED_DATA = "valueChanged";

    /**
     * Indicate whether the related cell's data has changed. <p/>
     *
     * An undefined result means that the cell hasn't been evaluated.
     *
     * @param {Selector} cell         A cell or element inside a cell.
     *
     * @returns {boolean|undefined}
     */
    function getCellChanged(cell) {
        return dataCell(cell).data(VALUE_CHANGED_DATA);
    }

    /**
     * Set the related data cell's changed state.
     *
     * @param {Selector} cell         A cell or element inside a cell.
     * @param {boolean}  [setting]    Default: **true**.
     *
     * @returns {boolean}
     */
    function setCellChanged(cell, setting) {
        OUT.debug(`setCellChanged: "${setting}"; cell =`, cell);
        const $cell   = dataCell(cell);
        const changed = (setting !== false);
        $cell.data(VALUE_CHANGED_DATA, changed);
        return changed;
    }

    /**
     * Set the related data cell's changed state to "undefined".
     *
     * @param {Selector} cell         A cell or element inside a cell.
     */
    function clearCellChanged(cell) {
        //OUT.debug("clearCellChanged: cell =", cell);
        dataCell(cell).removeData(VALUE_CHANGED_DATA);
    }

    /**
     * Change the related data cell's changed status.
     *
     * @param {Selector} cell         A cell or element inside a cell.
     * @param {boolean}  setting
     *
     * @returns {boolean}
     */
    function updateCellChanged(cell, setting) {
        OUT.debug(`updateCellChanged: "${setting}"; cell =`, cell);
        const $cell   = dataCell(cell);
        const changed = setCellChanged($cell, setting);
        $cell.toggleClass(CHANGED_MARKER, changed);
        return changed;
    }

    /**
     * Refresh the related data cell's changed status.
     *
     * @param {Selector} cell         A cell or element inside a cell.
     *
     * @returns {boolean}
     */
    function evaluateCellChanged(cell) {
        OUT.debug("evaluateCellChanged: cell =", cell);
        const $cell = dataCell(cell);
        let changed = getCellChanged($cell);
        if (notDefined(changed)) {
            const original = getCellOriginalValue($cell);
            const current  = getCellCurrentValue($cell);
            if (isDefined(original) && isDefined(current)) {
                changed = current.differsFrom(original);
            } else {
                changed = false;
            }
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
    const CELL_VALID_DATA = "valid";

    /**
     * Indicate whether the related cell's data is currently valid.
     *
     * @param {Selector} cell         A cell or element inside a cell.
     *
     * @returns {boolean}
     */
    function getCellValid(cell) {
        const $cell = dataCell(cell);
        const valid = $cell.data(CELL_VALID_DATA);
        return isDefined(valid) ? valid : updateCellValid($cell);
    }

    /**
     * Set the related data cell's valid state.
     *
     * @param {Selector} cell         A cell or element inside a cell.
     * @param {boolean}  [setting]    If **false**, make invalid.
     *
     * @returns {boolean}             **true** if set to valid.
     */
    function setCellValid(cell, setting) {
        //OUT.debug(`setCellValid: "${setting}"; cell =`, cell);
        const $cell  = dataCell(cell);
        const field  = $cell.attr(FIELD_ATTR);
        const $input = $cell.find(`[name="${field}"]`);
        const valid  = (setting !== false);
        if (!valid) {
            $input.attr("aria-invalid", true);
        } else if ($input.attr("aria-required") === "true") {
            $input.attr("aria-invalid", false);
        } else {
            $input.removeAttr("aria-invalid");
        }
        $cell.toggleClass(ERROR_MARKER, !valid);
        $cell.data(CELL_VALID_DATA, valid);
        return valid;
    }

    /**
     * Change the related data cell's validity status.
     *
     * @param {Selector} cell         A cell or element inside a cell.
     * @param {boolean}  [setting]    Default: {@link evaluateCellValid}
     *
     * @returns {boolean}             True if valid.
     */
    function updateCellValid(cell, setting) {
        //OUT.debug(`updateCellValid: "${setting}"; cell =`, cell);
        const $cell = dataCell(cell);
        const valid = isDefined(setting) ? setting : evaluateCellValid($cell);
        return setCellValid($cell, valid);
    }

    /**
     * Evaluate the current value of the associated data cell to determine
     * whether it is acceptable. <p/>
     *
     * (No changes are made to element attributes or data.)
     *
     * @param {Selector}    cell        A cell or element inside a cell.
     * @param {Field.Value} [current]   Default: {@link getCellCurrentValue}.
     *
     * @returns {boolean}
     */
    function evaluateCellValid(cell, current) {
        //OUT.debug("evaluateCellValid: cell =", cell);
        /** @type {Field.Value|undefined} */
        let value;
        const $cell = dataCell(cell);
        if ($cell.is(ERROR)) {
            return false;
        }
        if (isDefined(current)) {
            value = $cell.makeValue(current);
        } else {
            value = getCellCurrentValue($cell);
        }
        if (cellProperties($cell).required) {
            return !!value && value.nonBlank;
        } else {
            return !value || value.valid;
        }
    }

    // ========================================================================
    // Functions - cell - original value
    // ========================================================================

    /**
     * Name of the data() entry holding the original value of a cell.
     *
     * @type {string}
     */
    const ORIGINAL_VALUE_DATA = "originalValue";

    /**
     * The original value of the associated cell.
     *
     * @param {Selector} cell         A cell or element inside a cell.
     *
     * @returns {Field.Value|undefined}
     */
    function getCellOriginalValue(cell) {
        return dataCell(cell).data(ORIGINAL_VALUE_DATA);
    }

    /**
     * Assign the original value for the associated cell.
     *
     * @param {Selector}      cell          A cell or element inside a cell.
     * @param {Field.Value|*} new_value
     *
     * @returns {Field.Value}
     */
    function setCellOriginalValue(cell, new_value) {
        //OUT.debug("setCellOriginalValue: new_value =", new_value, cell);
        const $cell = dataCell(cell);
        const value = $cell.makeValue(new_value);
        $cell.data(ORIGINAL_VALUE_DATA, value);
        return value;
    }

    /**
     * Remove the original value data item for the associated cell.
     *
     * @param {Selector} cell         A cell or element inside a cell.
     */
    function clearCellOriginalValue(cell) {
        //OUT.debug("clearCellOriginalValue: cell =", cell);
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
    const CURRENT_VALUE_DATA = "currentValue";

    /**
     * The current value of the associated cell.
     *
     * @param {Selector} cell         A cell or element inside a cell.
     *
     * @returns {Field.Value|undefined}
     */
    function getCellCurrentValue(cell) {
        return dataCell(cell).data(CURRENT_VALUE_DATA);
    }

    /**
     * Assign the current value for the associated cell.
     *
     * @param {Selector}      cell          A cell or element inside a cell.
     * @param {Field.Value|*} new_value
     *
     * @returns {Field.Value}
     */
    function setCellCurrentValue(cell, new_value) {
        //OUT.debug("setCellCurrentValue: new_value =", new_value, cell);
        const $cell = dataCell(cell);
        const value = $cell.makeValue(new_value);
        $cell.data(CURRENT_VALUE_DATA, value);
        return value;
    }

    /**
     * Remove the current value data item for the associated cell.
     *
     * @param {Selector} cell         A cell or element inside a cell.
     */
    function clearCellCurrentValue(cell) {
        //OUT.debug("clearCellCurrentValue: cell =", cell);
        dataCell(cell).removeData(CURRENT_VALUE_DATA);
    }

    // ========================================================================
    // Functions - cell - display
    // ========================================================================

    /**
     * The display element for a single grid data cell.
     *
     * @param {Selector} cell         A cell or element inside a cell.
     *
     * @returns {jQuery}
     */
    function cellDisplay(cell) {
        const match   = CELL_DISPLAY;
        const $target = $(cell);
        return $target.is(match) ? $target : dataCell($target).children(match);
    }

    /**
     * Remove content from a data cell display element.
     *
     * @param {Selector} cell               A cell or element inside a cell.
     * @param {boolean}  [skip_uploader]    If **true**, remove error status.
     */
    function cellDisplayClear(cell, skip_uploader) {
        //OUT.debug('cellDisplayClear: cell =', cell);
        const $cell = dataCell(cell);
        if (!$cell.is(UPLOADER_CELL)) {
            cellDisplay($cell).empty();
        } else if (!skip_uploader) {
            setUploaderDisplayValue($cell);
        }
    }

    // ========================================================================
    // Functions - cell - display - value
    // ========================================================================

    /**
     * Get the displayed value for a data cell.
     *
     * @param {Selector} cell         A cell or element inside a cell.
     *
     * @returns {Field.Value}
     */
    function getCellDisplayValue(cell) {
        const $cell = dataCell(cell);
        const value = cellDisplay($cell).text();
        const curr  = getCellCurrentValue($cell);
        if (curr && !getCellOriginalValue($cell)) {
            setCellOriginalValue($cell, curr);
        }
        return setCellCurrentValue($cell, value);
    }

    /**
     * Set the displayed value for a data cell.
     *
     * @param {Selector}    cell        A cell or element inside a cell.
     * @param {Field.Value} new_value
     */
    function setCellDisplayValue(cell, new_value) {
        //OUT.debug("setCellDisplayValue: new_value =", new_value, cell);
        const $cell = dataCell(cell);
        if ($cell.is(UPLOADER_CELL)) {
            setUploaderDisplayValue(cell, new_value);
        } else {
            const $value = cellDisplay($cell);
            if (notDefined(new_value)) {
                $value.text("");
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
     * @param {Selector}    cell            A cell or element inside a cell.
     * @param {Field.Value} [new_value]     Default: from {@link cellDisplay}.
     */
    function updateCellDisplayValue(cell, new_value) {
        //OUT.debug("updateCellDisplayValue: new_value =", new_value, cell);
        const $cell = dataCell(cell);
        let value;
        if (isDefined(new_value)) {
            value = $cell.makeValue(new_value);
        } else {
            value = getCellDisplayValue($cell);
        }
        setCellDisplayValue($cell, value);
        updateCellValid($cell);
    }

    // ========================================================================
    // Functions - cell - display - file_data
    // ========================================================================

    function setUploaderDisplayValue(cell, new_value, data_type) {
        const $cell = dataCell(cell);
        const $name = $cell.find(UPLOADED_NAME);
        const $from = $name.children();

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
        $from.each((_, line) => {
            /** @type {jQuery} */
            const $line  = $(line);
            const active = $line.is(from_type);
            $line.text(active && file || '');
            $line.attr('aria-hidden', !active);
            $line.toggleClass('active', active);
            show_name ||= active;
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
     *
     * @returns {jQuery}
     */
    function cellEdit(target) {
        const match  = CONTROL_GROUP;
        const $tgt   = $(target);
        const $group = $tgt.is(match) ? $tgt : dataCell($tgt).children(match);
        // noinspection JSCheckFunctionSignatures
        return $group.find(CELL_EDIT);
    }

    /**
     * Remove content from a data cell edit element.
     *
     * @param {Selector} cell         A cell or element inside a cell.
     */
    function cellEditClear(cell) {
        //OUT.debug("cellEditClear:", cell);
        const $edit = cellEdit(cell);
        editValueClear($edit);
    }

    /**
     * Get the input value for a data cell.
     *
     * @param {Selector} cell         A cell or element inside a cell.
     *
     * @returns {Field.Value}
     */
    function getCellEditValue(cell) {
        const $edit = cellEdit(cell);
        const value = editValueGet($edit);
        return $edit.makeValue(value);
    }

    /**
     * Set the input value for a data cell.
     *
     * @param {Selector}    cell            A cell or element inside a cell.
     * @param {Field.Value} [new_value]     Default from displayed value.
     */
    function setCellEditValue(cell, new_value) {
        //OUT.debug("setCellEditValue: new_value =", new_value, cell);
        const $cell = dataCell(cell);
        const $edit = cellEdit($cell);
        let value   = new_value && $cell.makeValue(new_value);
            value ||= getCellCurrentValue($cell);
            value ||= getCellDisplayValue($cell);
        editValueSet($edit, value);
    }

    // ========================================================================
    // Functions - cell - editing
    // ========================================================================

    /**
     * Combine {@link startValueEdit} and {@link finishValueEdit}.
     *
     * @param {Selector} cell         A cell or element inside a cell.
     * @param {object}   new_value
     */
    function atomicEdit(cell, new_value) {
        const func  = "atomicEdit"; OUT.debug(`${func}: cell =`, cell);
        const $cell = dataCell(cell);
        if (startValueEdit($cell)) {
            delayedBy(250, () => finishValueEdit($cell, new_value))();
        }
    }

    /**
     * Begin editing a cell.
     *
     * @param {Selector} cell         A cell or element inside a cell.
     *
     * @return {boolean}              **false** if already editing.
     */
    function startValueEdit(cell) {
        const func  = "startValueEdit";
        const $cell = dataCell(cell);

        if (getCellEditMode($cell)) {
            OUT.debug(`--- ${func}: already editing $cell =`, $cell);
            return false;
        }

        OUT.debug(`>>> ${func}: $cell =`, $cell);
        setCellEditMode($cell, true);
        cellEditBegin($cell);
        postStartEdit($cell);
        return true;
    }

    /**
     * Inform the server that a row associated with a ManifestItem record is
     * being edited.
     *
     * @param {Selector} cell         A cell or element inside a cell.
     *
     * @see "ManifestItemController#start_edit"
     */
    function postStartEdit(cell) {
        const func  = "postStartEdit"; OUT.debug(`${func}: cell =`, cell);

        if (!manifestId()) {
            OUT.debug(`${func}: triggering manifest creation`);
            createManifest();
            return;
        }

        const $cell = dataCell(cell);
        const $row  = dataRow($cell);
        const item  = getManifestItemId($row);

        if (!item) {
            OUT.error(`${func}: no record ID for $row =`, $row);
            return;
        }

        const row   = dbRowValue($row);
        const delta = dbRowDelta($row);

        serverItemSend(`start_edit/${item}`, {
            caller:     func,
            params:     { row: row, delta: delta },
            onError:    () => finishValueEdit($cell),
        });
    }

    /**
     * End editing a cell.
     *
     * @param {Selector} cell         A cell or element inside a cell.
     * @param {*}        [new_value]  If **false** don't update value.
     *
     * @return {boolean}              **false** if not currently editing.
     */
    function finishValueEdit(cell, new_value) {
        const func  = "finishValueEdit";
        const $cell = dataCell(cell);

        if (!getCellEditMode($cell)) {
            OUT.debug(`--- ${func}: not editing $cell =`, $cell);
            return false;
        }

        let value;
        if (new_value instanceof Field.Value) {
            value = new_value;
        } else if (new_value) {
            value = $cell.makeValue(new_value);
        } else if (new_value !== false) {
            value = cellEditEnd($cell);
        }

        if (value) {
            OUT.debug(`<<< ${func}: value =`, value, "$cell =", $cell);
            postFinishEdit($cell, value);
        } else {
            OUT.debug(`<<< ${func}: $cell =`, $cell);
        }
        setCellEditMode($cell, false);
        return true;
    }

    /**
     * Transition a data cell into edit mode.
     *
     * @param {Selector}    cell            A cell or element inside a cell.
     * @param {Field.Value} [new_value]     Default from displayed value.
     */
    function cellEditBegin(cell, new_value) {
        OUT.debug("cellEditBegin: new_value =", new_value, cell);
        const $cell = dataCell(cell);
        setCellEditValue($cell, new_value);
        registerActiveCell($cell);
    }

    /**
     * Transition a data cell out of edit mode.
     *
     * @param {Selector} cell         A cell or element inside a cell.
     *
     * @returns {Field.Value}
     */
    function cellEditEnd(cell) {
        OUT.debug("cellEditEnd:", cell);
        const $cell     = dataCell(cell);
        const old_value = getCellCurrentValue($cell);
        const new_value = getCellEditValue($cell);
        if (new_value.differsFrom(old_value)) {
            const $row        = dataRow($cell);
            const row_change  = getRowChanged($row);
            const cell_change = dataCellUpdate($cell, new_value);
            if (cell_change !== row_change) {
                updateRowChanged($row);
                updateFormChanged();
            }
        }
        return new_value;
    }

    /**
     * Inform the server that a row associated with a ManifestItem record is no
     * longer being edited. <p/>
     *
     * If a value is supplied, the associated record field is updated (or used
     * to create a new record).
     *
     * @param {Selector}    cell            A cell or element inside a cell.
     * @param {Field.Value} [new_value]
     *
     * @see "ManifestItemController#start_edit"
     */
    function postFinishEdit(cell, new_value) {
        const func     = "postFinishEdit";
        const $cell    = dataCell(cell);
        const $row     = dataRow($cell);
        const item     = getManifestItemId($row);
        const manifest = manifestId();

        if (!manifest) {
            OUT.error(`${func}: no manifest ID`);
            return;
        }

        let data, action, params, response;
        if (new_value) {
            const field = cellDbColumn($cell);
            const row   = dbRowValue($row);
            const delta = dbRowDelta($row);
            data = { row: row, delta: delta, [field]: new_value.toString() };
        }
        if (item) {
            action   = `finish_edit/${item}`;
            params   = data ? { manifest_item: data } : {};
            response = parseFinishEditResponse;
        } else if (data) {
            action   = `create/${manifest}`;
            params   = { manifest_item: data };
            response = parseCreateResponse;
        } else {
            OUT.debug(`${func}: nothing to transmit`);
            return;
        }

        serverItemSend(action, {
            caller:     func,
            params:     params,
            onSuccess:  body => response($cell, body),
        });
    }

    /**
     * Receive updated fields for the item.
     *
     * @param {jQuery}         $cell
     * @param {CreateResponse} body
     *
     * @see "ManifestItemConcern#create_record"
     */
    function parseCreateResponse($cell, body) {
        OUT.debug("parseCreateResponse: body =", body);
        // noinspection JSValidateTypes
        /** @type {ManifestItem} */
        const data = body?.response || body;
        if (isPresent(data)) {
            updateDataRow($cell, data);
        }
    }

    /**
     * Receive updated fields for the item, plus problem reports, plus invalid
     * fields for each item that would prevent a save from occurring.
     *
     * @param {jQuery}         $cell
     * @param {UpdateResponse} body
     *
     * @see "ManifestItemConcern#finish_editing"
     * @see "Manifest::ItemMethods#pending_items_hash"
     * @see "ActiveModel::Errors"
     */
    function parseUpdateResponse($cell, body) {
        OUT.debug("parseUpdateResponse: body =", body);
        const data     = body?.response || body || {};
        const items    = presence(data.items);
        const pending  = presence(data.pending);
        const problems = presence(data.problems);

        // Update fields(s) echoed back from the server.  This may also include
        // "file_status" and/or "data_status"
        // @see "ManifestItemConcern#finish_editing"
        const $row   = dataRow($cell);
        const db_id  = getManifestItemId($row);
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
            for (const [id, item] of Object.entries(pending)) {
                const $row = isPresent(item) && rowForManifestItem(id, $rows);
                if ($row) { updateRowIndicators($row, item) }
            }
        }

        // Error message(s) to display.
        // @see "ActiveModel::Errors"
        if (problems) {
            let count = 0;
            for (const [type, lines] of Object.entries(problems)) {
                const message =
                    (!Array.isArray(lines) && `${type}: ${lines}`)    ||
                    ((lines.length === 1)  && `${type}: ${lines[0]}`) ||
                    (                         [type, ...lines]);
                if (count++) {
                    addFlashError(message);
                } else {
                    flashError(message);
                }
            }
        }
    }

    /**
     * Receive updated fields for the item, plus problem reports, plus invalid
     * fields for each item that would prevent a save from occurring.
     *
     * @param {jQuery}             $cell
     * @param {FinishEditResponse} body
     *
     * @see "ManifestItemConcern#finish_editing"
     * @see "Manifest::ItemMethods#pending_items_hash"
     * @see "ActiveModel::Errors"
     */
    function parseFinishEditResponse($cell, body) {
        OUT.debug("parseFinishEditResponse: body =", body);
        parseUpdateResponse($cell, body);
    }

    // ========================================================================
    // Functions - cell - editing - operations
    // ========================================================================

    /**
     * @typedef {object} EditElementOperations
     *
     * @property {function(jQuery)        : void}                      [clr]
     * @property {function(jQuery)        : string[]|string|undefined} [get]
     * @property {function(jQuery, Value) : void}                      [set]
     */

    /**
     * Element operations that are different the default ones.
     *
     * @type {Object.<string, EditElementOperations>}
     */
    const EDIT = {
        multi_select: {
            clr: ($e)    => checkboxes($e).prop('checked', false),
            get: ($e)    => checkboxes($e, true).toArray().map(cb => cb.value),
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
     * @param {Value}  [value]        Only for "set".
     */
    function editValueOperation($edit, op, edit_type, value) {
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
    function editValueGet($edit, edit_type) {
        return editValueOperation($edit, 'get', edit_type);
    }

    /**
     * Set the value of the edit element.
     *
     * @param {jQuery} $edit
     * @param {Value}  value
     * @param {string} [edit_type]    Default: {@link editType}
     */
    function editValueSet($edit, value, edit_type) {
        editValueOperation($edit, 'set', edit_type, value);
    }

    /**
     * Reset the value of the edit element.
     *
     * @param {jQuery} $edit
     * @param {string} [edit_type]    Default: {@link editType}
     */
    function editValueClear($edit, edit_type) {
        editValueOperation($edit, 'clr', edit_type);
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
    const ACTIVE_CELL_DATA = "activeCell";

    /**
     * The data cell which is currently being edited.
     *
     * @returns {HTMLElement|undefined}
     */
    function getActiveCell() {
        return $grid.data(ACTIVE_CELL_DATA);
    }

    /**
     * Remember the active cell.
     *
     * @param {Selector} cell         A cell or element inside a cell.
     */
    function setActiveCell(cell) {
        const func   = "setActiveCell";
        const active = dataCell(cell)[0];
        if (active) {
            OUT.debug(`${func}:`, active);
            $grid.data(ACTIVE_CELL_DATA, active);
        } else {
            OUT.error(`${func}: empty cell:`, cell);
            clearActiveCell();
        }
    }

    /**
     * Forget the active cell.
     */
    function clearActiveCell() {
        //OUT.debug(`clearActiveCell: $grid.removeData(${ACTIVE_CELL_DATA})`);
        $grid.removeData(ACTIVE_CELL_DATA);
    }

    /**
     * Indicate that the related data cell is being edited.
     *
     * @param {Selector} cell         A cell or element inside a cell.
     */
    function registerActiveCell(cell) {
        OUT.debug("registerActiveCell: cell =", cell);
        deregisterActiveCell();
        setActiveCell(cell);
    }

    /**
     * Resolve the currently active data cell edit by capturing the "focus"
     * event to see whether it is going somewhere outside the active cell.
     * If so then editing of the active cell is ended.
     *
     * @param {ElementEvt} [event]
     *
     * @note "focus" does not bubble; this should be triggered during capture.
     *
     * @see https://javascript.info/bubbling-and-capturing
     */
    function deregisterActiveCell(event) {
        const active = getActiveCell();
        if (active) {
            const $active = $(active);
            const $cell   = event  && presence(dataCell(event.target));
            const outside = $cell  && !sameElements($active, $cell);
            const finish  = !$cell || outside;

            if (OUT.debugging) {
                const msg = [];
                $cell   && msg.push(outside ? "outside" : "inside");
                finish  && msg.push("finishing");
                $active && msg.push("$active =", $active);
                event   && msg.push("event =", event);
                OUT.debug("deregisterActiveCell:", ...msg);
            }

            if (finish) { finishValueEdit($active, false) }
            clearActiveCell();
        }
    }

    /**
     * Abandon editing of the currently active data cell.
     *
     *  @returns {undefined}
     */
    function cancelActiveCell() {
        const func = "cancelActiveCell";
        if (getActiveCell()) {
            OUT.debug(func);
            deregisterActiveCell();
        } else {
            OUT.debug(`${func}: ignored - no active cell`);
        }
    }

    /**
     * Set whether the data cell is being edited.
     *
     * @param {Selector} cell         A cell or element inside a cell.
     * @param {boolean}  [setting]    If **false**, unset edit mode.
     */
    function setCellEditMode(cell, setting) {
        //OUT.debug(`setCellEditMode: setting = "${setting}"; cell =`, cell);
        const editing = (setting !== false);
        dataCell(cell).toggleClass(EDITING_MARKER, editing);
    }

    /**
     * Get whether the data cell is being edited.
     *
     * @param {Selector} cell         A cell or element inside a cell.
     *
     * @returns {boolean}
     */
    function getCellEditMode(cell) {
        return dataCell(cell).is(EDITING);
    }

    // ========================================================================
    // Functions - display - header rows
    // ========================================================================

    let $header_row, $header_columns;
    let $header_row_toggle, $controls_column_toggle;

    /**
     * Grid header row(s). <p/>
     *
     * The bottom row is the one that holds field properties and is used as a
     * reference point for grid data rows.
     *
     * @note Currently there is only one header row.
     *
     * @returns {jQuery}
     */
    function headerRow() {
        return $header_row ||= $grid.find(HEADER_ROW).last();
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
        return $header_row_toggle ||= headerRowToggleCreate();
    }

    /**
     * Finalize the control for expanding/contracting the header row(s).
     *
     * @param {Selector} [target]
     * @param {string}   [id_base]    For {@link toggleControlsCreate}
     *
     * @returns {jQuery}
     */
    function headerRowToggleCreate(target, id_base = "col") {
        //OUT.debug("headerRowToggleCreate: target =", target);
        const $toggle  = target ? $(target) : headerRow().find(ROW_EXPANDER);
        const $columns = headerColumns().filter(DATA_CELL);
        toggleControlsCreate($toggle, id_base);
        toggleControlsAdd($toggle, $columns);
        return $toggle;
    }

    /**
     * Control to expand/contract the controls column.
     *
     * @returns {jQuery}
     */
    function controlsColumnToggle() {
        return $controls_column_toggle ||= controlsColumnToggleCreate();
    }

    /**
     * Finalize the control for expanding/contracting the controls column.
     *
     * ({@link setupRowOperations} is relied upon to update *aria-controls*
     * initially and for rows added subsequently.)
     *
     * @param {Selector} [target]
     * @param {string}   [id_base]    For {@link toggleControlsCreate}
     *
     * @returns {jQuery}
     */
    function controlsColumnToggleCreate(target, id_base = "row") {
        //OUT.debug("controlsColumnToggleCreate: target =", target);
        const $toggle = target ? $(target) : headerRow().find(COL_EXPANDER);
        return toggleControlsCreate($toggle, id_base);
    }

    /**
     * Include the controls column for a new row into the set of elements
     * controlled by the column toggle.
     *
     * @param {Selector} target
     */
    function controlsColumnToggleAdd(target) {
        //OUT.debug("controlsColumnToggleAdd: target =", target);
        const $toggle = controlsColumnToggle();
        const $cell   = controlsColumn(target);
        toggleControlsAdd($toggle, $cell);
    }

    /**
     * Remove row(s) from the set of elements controlled by the column toggle.
     *
     * @param {Selector} target
     */
    function controlsColumnToggleRemove(target) {
        //OUT.debug("controlsColumnToggleRemove: target =", target);
        const $toggle = controlsColumnToggle();
        const $cell   = controlsColumn(target);
        toggleControlsRemove($toggle, $cell);
    }

    const CONTROLS_IDS_DATA  = "controlsIds";
    const CONTROLS_BASE_DATA = "controlsBase";

    /**
     * Finalize a control for expanding/contracting a set of elements.
     *
     * @param {jQuery} $toggle
     * @param {string} base_name
     *
     * @returns {jQuery}
     */
    function toggleControlsCreate($toggle, base_name) {
        //OUT.debug(`toggleControlsCreate: ${base_name}: $toggle =`, $toggle);
        const list = $toggle.attr("aria-controls");
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
    function toggleControlsAdd($toggle, elements) {
        //OUT.debug("toggleControlsAdd:", $toggle, elements);
        const base  = $toggle.data(CONTROLS_BASE_DATA);
        const ids   = $toggle.data(CONTROLS_IDS_DATA) || [];
        const start = ids.length;
        let index   = start;
        $(elements).each((_, element) => {
            const $element = $(element);
            let element_id = $element.attr("id");
            if (isMissing(element_id)) {
                element_id = `${base}-${++index}`;
                $element.attr("id", element_id);
            }
            if (!ids.includes(element_id)) {
                ids.push(element_id);
            }
        });
        if (ids.length > start) {
            $toggle.data(CONTROLS_IDS_DATA, ids);
            $toggle.attr("aria-controls", ids.join(" "));
        }
    }

    /**
     * Remove one or more elements from the set of activation toggle controls.
     *
     * @param {jQuery}   $toggle
     * @param {Selector} elements
     */
    function toggleControlsRemove($toggle, elements) {
        //OUT.debug("toggleControlsRemove:", $toggle, elements);
        // noinspection JSCheckFunctionSignatures
        const ids       = $(elements).toArray().map(el => $(el).attr("id"));
        const id_set    = new Set(compact(ids));
        const start_ids = $toggle.data(CONTROLS_IDS_DATA) || [];
        const final_ids = start_ids.filter(id => !id_set.has(id));
        if (final_ids.length < start_ids.length) {
            $toggle.data(CONTROLS_IDS_DATA, final_ids);
            $toggle.attr("aria-controls", final_ids.join(" "));
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
        const func = "manifestFor"; //OUT.debug(`${func}: target =`, target);
        let id;
        if (target) {
            (id = attribute(target, MANIFEST_ATTR)) ||
                OUT.error(`${func}: no ${MANIFEST_ATTR} for`, target);
        } else {
            (id = $grid.attr(MANIFEST_ATTR)) ||
                OUT.debug(`${func}: no manifest ID`);
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
        const data = { name: new_name };
        if (manifestId()) {
            updateManifest(data, callback);
        } else {
            createManifest(data, callback);
        }
    }

    /**
     * Post "/manifest/create" to create a new Manifest record.
     *
     * @param {Manifest}     [data]
     * @param {XmitCallback} [callback]
     */
    function createManifest(data, callback) {
        const func   = "createManifest";
        const params = { ...data };
        const method = params.method || "POST"; delete params.method;
        OUT.debug(`${func}: manifest = ${params.id || "-"}`);

        params.name ||= $title_text.text();

        serverManifestSend("create", {
            caller:     func,
            method:     method,
            params:     params,
            onSuccess:  processManifestData,
            onComplete: callback,
        });
    }

    /**
     * Post "/manifest/update" to modify an existing Manifest record.
     *
     * @param {Manifest}     data
     * @param {XmitCallback} [callback]
     */
    function updateManifest(data, callback) {
        const func     = "updateManifest";
        const params   = { ...data };
        const method   = params.method || "PUT";    delete params.method;
        const manifest = params.id || manifestId(); delete params.id;
        OUT.debug(`${func}: manifest = ${manifest}`);

        if (isMissing(manifest)) {
            const error = "no manifest ID";
            OUT.error(`${func}: ${error}`);
            callback?.(undefined, undefined, error, new XMLHttpRequest());
            return;
        }

        serverManifestSend(`update/${manifest}`, {
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
        const func = "processManifestData";
        OUT.debug(`${func}: data =`, data);
        if (isEmpty(data)) {
            return;
        }
        if (data.id) {
            const current = manifestId();
            if (!current) {
                $grid.attr(MANIFEST_ATTR, data.id);
                manifestIdChanged(data.id);
            } else if (data.id !== current) {
                OUT.error(`${func}: id ${data.id} !== current ${current}`);
                return;
            }
        }
        if (data.name) {
            $title_text.text(data.name);
        }
    }

    /**
     * Update the Submit button URL.
     *
     * @param {string} [id]           Default: {@link manifestId}.
     * @param {string} [action]       Base server controller endpoint name.
     */
    function manifestIdChanged(id, action = "remit") {
        const new_id  = id || manifestId();
        const current = $submission.attr("href") || "";
        const [path, ...params] = current.split("?");

        const parts   = path.split("/");
        if ([`${action}_select`, "SELECT"].includes(parts.at(-1))) {
            parts.pop();
        }
        if (parts.at(-1) !== action) {
            parts.push(action);
        }
        parts.push(new_id);
        const new_path = parts.join("/");

        const new_params = asParams(params.join("?"));
        delete new_params.selected;
        delete new_params.id;

        const new_url = makeUrl(new_path, new_params);
        $submission.attr("href", new_url);
    }

    // ========================================================================
    // Functions - database - ManifestItem
    // ========================================================================

    /**
     * The database ID for the ManifestItem associated with the target. <p/>
     *
     * The only rows for which this value should be undefined are blank rows
     * which have never had any activity which would have lead to the creation
     * of a ManifestItem to be associated with the row.
     *
     * @param {Selector} target       Row or cell.
     *
     * @returns {number|undefined}
     */
    function getManifestItemId(target) {
        const value = attribute(target, ITEM_ATTR);
        return Number(value) || undefined;
    }

    /**
     * Set the database ID for the ManifestItem associated with the target.
     *
     * @param {Selector}      target  Row or cell.
     * @param {number|string} value
     *
     * @returns {number|undefined}
     */
    function setManifestItemId(target, value) {
        const func = "setManifestItemId";
        OUT.debug(`${func}: value = "${value}"; target =`, target);
        const db_id = Number(value);
        if (db_id) {
            dataRow(target).attr(ITEM_ATTR, db_id);
        } else {
            OUT.error(`${func}: invalid value:`, value);
        }
        return db_id || undefined;
    }

    /**
     * Remove the database ID for the ManifestItem associated with the target.
     *
     * @param {Selector} target       Row or cell.
     */
    function clearManifestItemId(target) {
        const func = "clearManifestItemId";
        OUT.debug(`${func}: target =`, target);
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

    /**
     * Post "/manifest_item/create" to create a new ManifestItem record.
     *
     * @param {Selector}     grid_row
     * @param {Manifest}     [data]
     * @param {XmitCallback} [callback]
     */
    function createManifestItem(grid_row, data, callback) {
        const func     = "createManifestItem";
        const $row     = dataRow(grid_row);
        const row      = dbRowValue($row);
        const delta    = dbRowDelta($row);
        const params   = { row: row, delta: delta, ...data };
        const manifest = manifestId();
        OUT.debug(`${func}: manifest =`, manifest);

        if (!manifest) {
            OUT.error(`${func}: no manifest ID`);
            return;
        }

        serverItemSend(`create/${manifest}`, {
            caller:     func,
            params:     params,
            onSuccess:  body => parseCreateResponse($row, body),
            onComplete: callback,
        });
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
        return field_property ||= findFieldProperties();
    }

    /**
     * Find all field names and properties
     *
     * @returns {PropertiesTable}
     */
    function findFieldProperties() {
        const func   = "findFieldProperties";
        const result = {};
        headerColumns().each((_, column) => {
            selfOrDescendents(column, `[${FIELD_ATTR}]`).each((_, element) => {
                const prop    = new Field.Properties(element);
                const field   = prop.field || $(element).attr(FIELD_ATTR);
                result[field] = prop;
            });
        });
        if (isEmpty(result)) {
            OUT.error(`${func}: no field names could be extracted from grid`);
        } else {
            OUT.debug(`${func} ->`, result);
        }
        return result;
    }

    /**
     * Mapping of database field to related EMMA data field.
     *
     * @type {Object.<string,string>}
     */
    const FIELD_MAP = {
        repository: "emma_repository",
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
    function getValueAndField(data, field) {
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
     * <p/>
     *
     * If the URL has a hash, the indicated target item will be scrolled to the
     * center first before aligning the title to the top of the viewport.
     */
    function scrollToTop() {
        OUT.debug("scrollToTop");
        const anchor = window.location.hash;
        if (anchor) { scrollToCenter(anchor) }
        $('#main')[0].scrollIntoView({ block: "start", inline: "nearest" });
    }

    /**
     * Position the page so that indicated item is scrolled to the center of
     * the viewport. <p/>
     *
     * If target has an equals sign it's assumed to be an attribute/value pair
     * which is used to find the indicated item (e.g. "#data-item-id=18" will
     * result in the selector *[data-item-id="18"]*.
     *
     * @params {string} target
     */
    function scrollToCenter(target) {
        const func   = "scrollToCenter";
        const anchor = target.trim().replace(/^#/, "");
        const parts  = anchor.split("=");
        OUT.debug(`${func}: target =`, target);
        let $target;
        if ((parts.length > 1) && !anchor.match(/^\[(.*)]$/)) {
            const attr  = parts.shift();
            const val   = parts.join("=").trim();
            const value = val.match(/^(["'])(.*)\1$/)?.at(2) || val;
            $target     = $(`[${attr}="${value}"]`);
        } else {
            $target     = $(`#${anchor}`);
        }
        if (isPresent($target)) {
            const $rows = allDataRows();
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
            $target[0].scrollIntoView({ block: "center", inline: "start" });
        } else {
            OUT.debug(`${func}: missing target =`, target);
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
        OUT.debug("getPageItemCount:", count);
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
        OUT.debug("setPageItemCount: value =", value);
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
        OUT.debug("getTotalItemCount:", count);
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
        OUT.debug("setTotalItemCount: value =", value);
        const count = Number(value) || 0;
        totalItems().text(count);
        return count;
    }

    /**
     * Change the number of rows displayed on the page.
     *
     * @param {number} increment
     */
    function changeItemCounts(increment) {
        const func  = "changeItemCounts";
        //OUT.debug(`${func}: increment =`, increment);
        let count  = getPageItemCount();
        let total  = getTotalItemCount();
        const step = Number(increment);
        if (step) {
            setPageItemCount( count += step);
            setTotalItemCount(total += step);
        } else {
            OUT.error(`${func}: invalid:`, increment);
        }
        const single = !(total > count);
        itemCounts().toggleClass("multi-page", !single);
        itemCounts().toggleClass("single-page", single);
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
    const OFFLINE_DATA = "offline";

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
     * @param {boolean} [setting]     If **false**, indicate not offline.
     */
    function setOffline(setting) {
        const offline    = (setting !== false);
        const is_offline = isOffline();
        OUT.debug(`setOffline: ${is_offline} (setting = "${setting}")`);
        if (offline !== is_offline) {
            const $rows  = allDataRows();
            const note   = `\n${NOT_CHANGEABLE}`;
            const attrs  = ["disabled", "readonly"];
            const inputs = 'button, input, textarea, select';
            let change_tip, change_attr;
            if (is_offline) {
                change_tip  = ($e, t) => $e.attr("title", t.replace(note, ""));
                change_attr = ($e, a) => $e.removeAttr(a);
            } else {
                change_tip  = ($e, t) => $e.attr("title", `${t}${note}`);
                change_attr = ($e, a) => $e.attr(a, true);
            }
            $rows.find('[title]').each((_, element) => {
                const $element = $(element);
                change_tip($element, $element.attr("title"));
            });
            $rows.find(inputs).each((_, element) => {
                const $input = $(element);
                attrs.forEach(a => change_attr($input, a));
            });
        }
        const marker = "offline";
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
        const func = "serverItemSend";
        const opt  = { ...send_options };
        opt.caller       ||= func;
        opt.onCommStatus ||= onCommStatus;
        serverSend(ctr_act, opt);
    }

    /**
     * Post to a Manifest controller endpoint.
     *
     * @param {string}      action
     * @param {SendOptions} [send_options]
     *
     * @see serverBulkSend
     */
    function serverManifestSend(action, send_options) {
        const func = "serverManifestSend";
        const opt  = { ...send_options };
        opt.caller       ||= func;
        opt.onCommStatus ||= onCommStatus;
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
        const error   = offline && isOnline() && Emma.Messages.status.offline;
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
        //OUT.debug(`getClass: ${base} for target =`, target);
        const func    = caller || "getClass";
        const $target = single(target, func);
        if (isMissing($target)) {
            OUT.error(`${func}: no target element`);
        } else {
            const classes = Array.from($target[0].classList);
            let matches;
            if (base instanceof RegExp) {
                matches = classes.filter(cls => base.test(cls));
            } else {
                matches = classes.filter(cls => cls.startsWith(base));
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
        //OUT.debug(`replaceClass: ${base}${value} for target =`, target);
        const func    = caller || "replaceClass";
        const $target = single(target, func);
        if (isMissing($target)) {
            OUT.error(`${func}: no target element`);
        } else {
            const classes      = Array.from($target[0].classList);
            const base_classes = classes.filter(cls => cls.startsWith(base));
            $target.removeClass(base_classes).addClass(`${base}${value}`);
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
        //OUT.debug(`checkboxes: checked = "${checked}"; target =`, target);
        const $checkboxes = CheckboxGroup.controls(target);
        switch (checked) {
            case true:  return $checkboxes.filter((_, cb) => cb.checked);
            case false: return $checkboxes.not((_, cb) => cb.checked);
            default:    return $checkboxes;
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
            case isEmpty(data):         return "text";
            case /^\s*[{[]/.test(data): return "json";
            case /^\s*</.test(data):    return "xml";
            default:                    return "csv";
        }
    }

    /**
     * Create a new Value in the context of the jQuery object.
     *
     * @param {*}                                 value
     * @param {Object.<string,(string|string[])>} [errs]
     *
     * @returns {Value}
     */
    jQuery.fn.makeValue = function(value, errs) {
        const prop = cellProperties(this);
        return new Field.Value(value, prop, errs);
    };

    // ========================================================================
    // Functions - diagnostics
    // ========================================================================

    // noinspection JSUnusedLocalSymbols
    /**
     * This is a convenience function that can be added to check all data()
     * values for an element and its descendents.
     *
     * @note Not conditional on debugging() -- not for normal debug output.
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
        const tag = leader ? `${leader} ` : "";
        names.forEach(name => {
            const v = $root.data(name);
            if (isDefined(v)) {
                console.error(`${tag} | ${name} =`, v);
            }
        });
        $root.find('*').toArray().map(el => $(el)).forEach($el => {
            names.forEach(name => {
                const v = $el.data(name);
                if (isDefined(v)) {
                    console.error(`${tag} ${$el[0].className} | ${name} =`, v);
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
        tooltip.push(`ORIGINAL: "${getCellOriginalValue($display)}"`);
        tooltip.push(`CURRENT:  "${getCellCurrentValue($display)}"`);
        tooltip.push(`CHANGED:  "${getCellChanged($display)}"`);
        if (dataCell($display).attr("title")?.endsWith(NOT_CHANGEABLE)) {
            tooltip.push(NOT_CHANGEABLE);
        }
        $display.attr("title", tooltip.join("\n"));
    }

    // ========================================================================
    // Event handlers
    // ========================================================================

    // Title editing.
    handleClickAndKeypress($title_edit,   onStartTitleEdit);
    handleClickAndKeypress($title_update, onUpdateTitleEdit);
    handleClickAndKeypress($title_cancel, onCancelTitleEdit);
    handleEvent($title_input, "keydown",  onTitleEditKeypress);

    // Main control buttons.
    handleClickAndKeypress($save,   saveUpdates);
    handleClickAndKeypress($cancel, cancelUpdates);
    handleClickAndKeypress($export, exportRows);
    handleEvent($import, "change",  importRows);

    // Cell editing.
    windowEvent("focus",     deregisterActiveCell, true);
    windowEvent("mousedown", deregisterActiveCell, true);
    onPageExit(deregisterActiveCell, OUT.debugging());

    // ========================================================================
    // Actions
    // ========================================================================

    // Setup bibliographic lookup first so that linkages are in place before
    // setupLookup() executes.
    LookupModal.initializeAll();

    initializeEditForm();

});
