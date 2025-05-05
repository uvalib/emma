// app/assets/javascripts/tool/bibliographic-lookup.js
//
// Bibliographic Lookup
//
// noinspection JSUnusedLocalSymbols


import { AppDebug }                       from "../application/debug";
import { LookupChannel }                  from "../channels/lookup-channel";
import { arrayWrap, intersects }          from "../shared/arrays";
import { Emma }                           from "../shared/assets";
import { selector, toggleHidden }         from "../shared/css";
import { turnOffAutocomplete }            from "../shared/form";
import { HTML_BREAK }                     from "../shared/html";
import { renderJson }                     from "../shared/json";
import { LOOKUP_BUTTON, LookupModal }     from "../shared/lookup-modal";
import { LookupRequest }                  from "../shared/lookup-request";
import { PANEL }                          from "../shared/modal-base";
import { ModalDialog }                    from "../shared/modal-dialog";
import { ModalHideHooks, ModalShowHooks } from "../shared/modal-hooks";
import { dupObject, hasKey, toObject }    from "../shared/objects";
import { randomizeName }                  from "../shared/random";
import { camelCase, capitalize }          from "../shared/strings";
import {
    handleClickAndKeypress,
    toggleVisibility,
} from "../shared/accessibility";
import {
    isDefined,
    isEmpty,
    isMissing,
    isPresent,
    presence,
} from "../shared/definitions";
import {
    debounce,
    handleEvent,
    handleHoverAndFocus,
    isEvent,
} from "../shared/events";


const MODULE = "BibliographicLookup";
const DEBUG  = Emma.Debug.JS_DEBUG_BIB_LOOKUP;

AppDebug.file("tool/bibliographic-lookup", MODULE, DEBUG);

// ============================================================================
// Functions
// ============================================================================

// noinspection FunctionTooLongJS
/**
 * Set up a page with interactive bibliographic lookup.
 *
 * @param {Selector}               base
 * @param {CallbackChainFunctions} [show_hooks]
 * @param {CallbackChainFunctions} [hide_hooks]
 */
export async function setupFor(base, show_hooks, hide_hooks) {

    const $base = $(base);

    /** @type {jQuery|undefined} */
    const $popup_button = $base.is(LOOKUP_BUTTON) ? $base : undefined;

    /**
     * Whether the source implements manual input of search terms.
     *
     * @readonly
     * @type {boolean}
     */
    const manual = true;

    /**
     * Whether the source displays diagnostic output elements.
     *
     * @readonly
     * @type {boolean}
     */
    const output = true;

    /**
     * Console output functions for this module.
     */
    const OUT = AppDebug.consoleLogging(MODULE, DEBUG);

    const LOCK_LBL   = Emma.Terms.lookup.lock.label;
    const UNLOCK_LBL = Emma.Terms.lookup.unlock.label;

    const LOCK_TIP   = Emma.Terms.lookup.lock.tooltip;
    const UNLOCK_TIP = Emma.Terms.lookup.unlock.tooltip;

    // ========================================================================
    // Channel
    // ========================================================================

    const channel = await LookupChannel.newInstance();

    if (channel) {

        channel.disconnectOnPageExit(OUT.debugging());

        channel.setCallback(updateResultDisplay);
        channel.setErrorCallback(updateErrorDisplay);
        channel.setDiagnosticCallback(updateDiagnosticDisplay);

        channel.addCallback(updateStatusDisplay);

        if ($popup_button) {
            channel.addCallback(updateSearchResultsData);
            channel.addCallback(updateEntries);
        }
    }

    // ========================================================================
    // Variables
    // ========================================================================

    /**
     * The modal class instance.
     *
     * @type {ModalDialog|undefined}
     */
    const modal = $popup_button?.data(ModalDialog.INSTANCE_DATA);

    /**
     * Base element associated with the dialog.
     *
     * @type {jQuery}
     */
    const $root =
        modal?.modalPanel || $popup_button?.siblings(PANEL) || $('body');

    /** @type {jQuery} */
    let $container, $loading_overlay;

    /**
     * Operational status elements.
     *
     * @type {jQuery}
     */
    let $query_panel, $query_terms, $status_display, $notice, $services;

    /**
     * Result entry elements.
     *
     * @type {jQuery}
     */
    let $entries_display, $entries_list;

    /**
     * Result entry elements.
     *
     * @type {jQuery}
     */
    let $selected_entry, $field_values, $field_locks, $original_values;

    /**
     * The first selection radio button on the modal popup.
     *
     * @type {jQuery|undefined}
     */
    let $start_tabbable;

    /**
     * Raw communications display elements.
     *
     * @type {jQuery}
     */
    let $heading, $output, $results, $errors, $diagnostics;

    /**
     * Manual input elements.
     *
     * @type {jQuery}
     */
    let $prompt, $input, $submit, $separator;

    // ========================================================================
    // Actions
    // ========================================================================

    if (manual) {
        handleEvent(inputText(), "keyup", manualSubmission);
        handleClickAndKeypress(inputSubmit(), manualSubmission);
        turnOffAutocomplete(inputText());
        toggleHidden(queryPanel(), true);
    } else {
        toggleHidden(inputPrompt(), true);
    }

    if (output) {
        initializeDisplay(resultDisplay());
        initializeDisplay(errorDisplay());
        initializeDisplay(diagnosticDisplay());
    } else {
        toggleHidden(panelHeading(),  true);
        toggleHidden(outputDisplay(), true);
    }

    if (isModal()) {
        ModalShowHooks.set($popup_button, show_hooks, onShowModal);
        ModalHideHooks.set($popup_button, onHideModal, hide_hooks);
    } else {
        toggleHidden(entriesDisplay(), true);
    }

    // ========================================================================
    // Functions
    // ========================================================================

    /**
     * Indicate whether operations are occurring within a modal dialog.
     *
     * @returns {boolean}
     */
    function isModal() {
        return !!$popup_button;
    }

    /**
     * The element which holds data properties.  In the case of a modal dialog,
     * this is the element through which new user-specified field values are
     * communicated back to the originating page.
     *
     * @returns {jQuery}
     */
    function dataElement() {
        return $popup_button || $root;
    }

    /**
     * The element containing all of the lookup-specific functional elements.
     *
     * @returns {jQuery}
     */
    function container() {
        return $container ||= $root.find('main');
    }

    // ========================================================================
    // Functions
    // ========================================================================

    /**
     * Submit the query terms as a lookup request.
     *
     * @param {KeyboardEvt} event
     */
    function manualSubmission(event) {
        if (isEvent(event, KeyboardEvent) && (event.key !== "Enter")) {
            return;
        }
        OUT.debug("manualSubmission:", event);
        if (isModal()) {
            // Don't allow the manual submission to close the dialog.
            event.stopPropagation();
            event.preventDefault();
        } else {
            // Force regeneration of lookup request from input search terms.
            clearRequestData();
        }
        performRequest();
    }

    /**
     * Submit the query automatically when the popup is opened.
     *
     * @param {jQuery}  _$target      Unused.
     * @param {boolean} check_only
     * @param {boolean} [halted]
     *
     * @returns {EventHandlerReturn}
     *
     * @see onShowModalHook
     */
    function onShowModal(_$target, check_only, halted) {
        OUT.debug("onShowModal:", _$target, check_only, halted);
        if (check_only || halted) { return undefined }
        resetSearchResultsData();
        clearFieldResultsData();
        updateSearchTerms();
        disableCommit();
        resetEntries();
        performRequest();
        showLoadingOverlay();
    }

    /**
     * Commit when leaving the popup from the Update button.
     *
     * @param {jQuery}  $target       Checked for `.is(LookupModal.COMMIT)`.
     * @param {boolean} check_only
     * @param {boolean} [halted]
     *
     * @returns {EventHandlerReturn}
     *
     * @see onHideModalHook
     */
    function onHideModal($target, check_only, halted) {
        OUT.debug("onHideModal:", $target, check_only, halted);
        if (check_only || halted) { return undefined }
        if ($target.is(LookupModal.COMMIT)) {
            commitFieldValuesEntry();
        } else {
            clearFieldResultsData();
        }
    }

    /**
     * Perform the lookup request.
     */
    function performRequest() {
        OUT.debug("performRequest");
        initializeStatusDisplay();
        if (output) {
            clearResultDisplay();
            clearErrorDisplay();
        }
        channel?.request(getRequestData());
    }

    // ========================================================================
    // Functions - request data
    // ========================================================================

    /**
     * Get the current lookup request.
     *
     * @returns {LookupRequest}
     */
    function getRequestData() {
        const request = dataElement().data(LookupModal.REQUEST_DATA);
        return request || setRequestData(getSearchTerms());
    }

    /**
     * Set the current lookup request.
     *
     * @param {string|string[]|LookupRequest|LookupRequestPayload} data
     *
     * @returns {LookupRequest}       The current request object.
     */
    function setRequestData(data) {
        OUT.debug("setRequestData:", data);
        let request;
        if (data instanceof LookupRequest) {
            request = data;
            setSeparators(request.separators);
        } else {
            request = new LookupRequest(data, getSeparators());
        }
        dataElement().data(LookupModal.REQUEST_DATA, request);
        return request;
    }

    /**
     * Clear the current lookup request.
     */
    function clearRequestData() {
        OUT.debug("clearRequestData");
        dataElement().removeData(LookupModal.REQUEST_DATA);
    }

    // ========================================================================
    // Functions - response data
    // ========================================================================

    /**
     * Lookup results are stored as a table of job identifiers mapped on to
     * their associated responses.
     *
     * @typedef {{[job_id: string]: LookupResponsePayload}} LookupResults
     */

    /**
     * Get response data stored on the data object.
     *
     * @returns {LookupResults|undefined}
     */
    function getSearchResultsData() {
        return dataElement().data(LookupModal.SEARCH_RESULT_DATA);
    }

    /**
     * Set response data on the data object.
     *
     * @param {LookupResults|undefined} value
     *
     * @returns {LookupResults}
     */
    function setSearchResultsData(value) {
        OUT.debug("setSearchResultsData:", value);
        const new_value = value || blankSearchResultsData();
        dataElement().data(LookupModal.SEARCH_RESULT_DATA, new_value);
        return new_value;
    }

    /**
     * Empty response data from the data object.
     *
     * @returns {LookupResults}
     */
    function resetSearchResultsData() {
        OUT.debug("resetSearchResultsData");
        return setSearchResultsData(blankSearchResultsData());
    }

    /**
     * Update the data object with the response data.
     *
     * @param {LookupResponse} message
     */
    function updateSearchResultsData(message) {
        OUT.debug("updateSearchResultsData:", message);
        const key = message.job_id || randomizeName("response");
        const obj = getSearchResultsData() || resetSearchResultsData();
        obj[key]  = message.toObject();
    }

    /**
     * Generate an empty response data object.
     *
     * @returns {LookupResults}
     */
    function blankSearchResultsData() {
        return {};
    }

    // ========================================================================
    // Functions - original field values data
    // ========================================================================

    /**
     * Get the original field values supplied via the lookup button.
     *
     * @returns {EmmaData}
     */
    function originalFieldValues() {
        return dataElement().data(LookupModal.ENTRY_ITEM_DATA) || {};
    }

    /**
     * Get the original field values supplied via the lookup button.
     *
     * @param {string} [caller]       For log messages.
     *
     * @returns {EmmaData}
     */
    function getOriginalFieldValues(caller) {
        const data = originalFieldValues();
        if (isMissing(data)) {
            const func = caller || "getOriginalFieldValues";
            const name = LookupModal.ENTRY_ITEM_DATA;
            OUT.warn(`${func}: toggle missing .data(${name})`);
        }
        return data;
    }

    // ========================================================================
    // Functions - new field values data
    // ========================================================================

    /**
     * Get user-selected field values stored on the data object.
     *
     * @returns {LookupResponseItem|undefined}
     */
    function getFieldResultsData() {
        return dataElement().data(LookupModal.FIELD_RESULTS_DATA);
    }

    /**
     * Store the user-selected field values on the data object.
     *
     * @param {LookupResponseItem|undefined} value
     */
    function setFieldResultsData(value) {
        OUT.debug("setFieldResultsData:", value);
        const new_value = value || {};
        dataElement().data(LookupModal.FIELD_RESULTS_DATA, new_value);
    }

    /**
     * Clear the user-selected field values from lookup.
     */
    function clearFieldResultsData() {
        OUT.debug("clearFieldResultsData");
        dataElement().removeData(LookupModal.FIELD_RESULTS_DATA);
    }

    // ========================================================================
    // Functions - lookup query display
    // ========================================================================

    /**
     * The element with the display of the query currently being performed.
     *
     * @returns {jQuery}
     */
    function queryPanel() {
        return $query_panel ||=
            presence(container().find(LookupModal.QUERY_PANEL));
    }

    /**
     * The element containing the query currently being performed.
     *
     * @returns {jQuery}
     */
    function queryTerms() {
        return $query_terms ||= queryPanel().find(LookupModal.QUERY_TERMS);
    }

    // ========================================================================
    // Functions - lookup status display
    // ========================================================================

    /**
     * The element displaying the state of the parallel requests.
     *
     * @returns {jQuery}
     */
    function statusDisplay() {
        return $status_display ||=
            presence(container().find(LookupModal.STATUS_DISPLAY)) ||
            makeStatusDisplay().insertAfter(inputPrompt());
    }

    /**
     * The element for displaying textual status information.
     *
     * @param {string} [value]
     * @param {string} [tooltip]
     *
     * @returns {jQuery}
     */
    function statusNotice(value, tooltip) {
        $notice ||= statusDisplay().find(LookupModal.NOTICE);
        if (isDefined(value)) {
            $notice.text(value);
            if (tooltip) {
                $notice.addClass("tooltip").attr("title", tooltip);
            } else {
                $notice.removeClass("tooltip").removeAttr("title");
            }
        }
        return $notice;
    }

    /**
     * The element containing the dynamic set of external services.
     *
     * @param {string|string[]} [services]
     *
     * @returns {jQuery}
     */
    function serviceStatuses(services) {
        $services ||= statusDisplay().find(LookupModal.SERVICES);
        if (isDefined(services)) {
            OUT.debug("serviceStatuses:", services);
            const lbl_css = "label";
            if (isMissing($services.children(selector(lbl_css)))) {
                const $lbl = $('<span>').addClass(lbl_css).text("Searching:");
                $lbl.prependTo($services);
            }
            let names = arrayWrap(services);
            let data  = $services.data("names");
            if (data) {
                names = names.filter(srv => !data.includes(srv));
            } else {
                $services.data("names", (data = []));
            }
            if (isPresent(names)) {
                const statuses = names.map(name => makeServiceStatus(name));
                $services.append(statuses);
                data.push(...names);
            }
            toggleVisibility($services, false);
        }
        return $services;
    }

    /**
     * Clear service status contents and data.
     */
    function clearServiceStatuses() {
        OUT.debug("clearServiceStatuses");
        serviceStatuses().removeData("names").find('.service').remove();
    }

    /**
     * Change status values based on received data.
     *
     * @param {LookupResponse} message
     */
    function updateStatusDisplay(message) {
        const func  = "updateStatusDisplay"; OUT.debug(`${func}:`, message);
        const state = message.status?.toUpperCase();
        const srv   = message.service;
        const data  = message.data;

        let finish, notice, n_tip, status;
        switch (state) {

            // Waiter states

            case "STARTING":
                notice = "Working";
                serviceStatuses(srv);
                break;
            case "TIMEOUT":
                notice = "Done";
                n_tip  = "Some searches took longer than expected";
                finish = true;
                break;
            case "PARTIAL":
                notice = "Done";
                n_tip  = "Partial results received";
                finish = true;
                break;
            case "COMPLETE":
                notice = "Done";
                finish = true;
                break;

            // Worker states

            case "WORKING":
                notice =`${statusNotice().text()}.`;
                break;
            case "LATE":
                status = "late";
                break;
            case "DONE":
                status = isEmpty(data?.items) ? ["done", "empty"] : "done";
                break;

            // Other

            default:
                OUT.warn(`${func}: ${message.status}: unexpected`);
                break;
        }
        if (notice) { statusNotice(notice, n_tip) }
        if (status) { serviceStatuses().find(`.${srv}`).addClass(status) }
        if (finish) { hideLoadingOverlay() }
    }

    // ========================================================================
    // Functions - lookup status display
    // ========================================================================

    /**
     * Put the status panel into the default state with any previous service
     * status elements removed.
     */
    function initializeStatusDisplay() {
        OUT.debug("initializeStatusDisplay");
        toggleVisibility(serviceStatuses(), false);
        clearServiceStatuses();
        statusNotice("Starting...");
    }

    /**
     * Generate the element displaying the state of the parallel requests.
     *
     * @returns {jQuery}
     */
    function makeStatusDisplay() {
        const css       = LookupModal.STATUS_DISPLAY_CLASS;
        const $panel    = $('<div>').addClass(css);
        const $services = makeServiceStatuses();
        const $notice   = makeStatusNotice();
        return $panel.append($services, $notice);
    }

    /**
     * Generate the element for displaying textual status information.
     *
     * @returns {jQuery}
     */
    function makeStatusNotice() {
        const css = LookupModal.NOTICE_CLASS;
        return $('<div>').addClass(css);
    }

    /**
     * Generate the element containing the dynamic set of external services.
     *
     * @returns {jQuery}
     */
    function makeServiceStatuses() {
        const css = LookupModal.SERVICES_CLASS;
        return $('<div>').addClass(css);
    }

    /**
     * Generate an element for displaying the status of an external service.
     *
     * @param {string} [name]         Service name; default: "unknown".
     *
     * @returns {jQuery}
     */
    function makeServiceStatus(name) {
        const css     = "service";
        const service = name || "unknown";
        const classes = `${css} ${service}`;
        const label   = camelCase(service);
        return $('<div>').addClass(classes).text(label);
    }

    // ========================================================================
    // Functions - commit
    // ========================================================================

    /**
     * The button(s) for updating
     * {@link LookupModal.FIELD_RESULTS_DATA FIELD_RESULTS_DATA} from the
     * current contents of {@link $field_values}.
     *
     * @returns {jQuery}
     */
    function commitButton() {
        return $root.find(LookupModal.COMMIT);
    }

    /**
     * Enable commit button(s).
     *
     * @param {boolean} [enable]      If *false*, disable.
     *
     * @returns {jQuery}              The commit button(s).
     */
    function enableCommit(enable) {
        OUT.debug("enableCommit:", enable);
        const $button = commitButton();
        const marker  = LookupModal.DISABLED_MARKER;
        const set     = (enable === false);
        return $button.toggleClass(marker, set).prop("disabled", set);
    }

    /**
     * Disable commit button(s).
     *
     * @param {boolean} [disable]     If *false*, enable.
     *
     * @returns {jQuery}              The commit button(s).
     */
    function disableCommit(disable) {
        OUT.debug("disableCommit:", disable);
        const $button = commitButton();
        const marker  = LookupModal.DISABLED_MARKER;
        const set     = (disable !== false);
        return $button.toggleClass(marker, set).prop("disabled", set);
    }

    // ========================================================================
    // Methods - values
    // ========================================================================

    /**
     * Get the value associated with an element.
     *
     * @param {Selector} element
     *
     * @returns {string}
     */
    function getValue(element) {
        const $elem = $(element);
        if ($elem.is('textarea')) {
            return $elem.val()?.trim() || "";
        } else {
            return getLatestFieldValue($elem) || $elem.text().trim();
        }
    }

    /**
     * Transform an input value into the expected form for a data value.
     *
     * @param {*} item
     *
     * @returns {string[]|string}
     */
    function toDataValue(item) {
        if (Array.isArray(item)) {
            return item.map(v => v?.trim ? v.trim() : v).filter(v => v);

        } else if (typeof item !== "string") {
            return item?.toString() || "";

        } else if (item.includes("\n")) {
            // noinspection TailRecursionJS
            return toDataValue(item.split("\n"));

        } else {
            return item.trim();
        }
    }

    /**
     * Transform a data value into an input value.
     *
     * @param {*} item
     *
     * @returns {string}
     */
    function toInputValue(item) {
        if (typeof item === "string") {
            return item.trim();

        } else if (Array.isArray(item)) {
            return toDataValue(item).join("\n");

        } else {
            return toDataValue(item);
        }
    }

    // ========================================================================
    // Functions - replacement field values
    // ========================================================================

    /**
     * Get the entry row element containing the field values that will be
     * reported back to the form.
     *
     * @returns {jQuery}
     */
    function getFieldValuesEntry() {
        return $field_values;
    }

    /**
     * Set the field values row element.
     *
     * @param {jQuery} $entry
     *
     * @returns {jQuery}
     */
    function setFieldValuesEntry($entry) {
        return $field_values = $entry;
    }

    /**
     * Fill the fields values row element from item data attached to the toggle
     * button and toggle the lock state of each associated column accordingly.
     *
     * @param {string} [caller]       For log messages.
     *
     * @returns {jQuery}
     */
    function refreshFieldValuesEntry(caller) {
        const func   = caller || "refreshFieldValuesEntry";
        const data   = getOriginalFieldValues(func);
        const $entry = getFieldValuesEntry();
        fillEntry($entry, data);
        $entry.find('textarea').each((_, column) => {
            const $column = $(column);
            const $lock   = lockFor($column);
            const field   = fieldFor($column);
            const locked  = !!getValue($column);
            $lock.prop("checked", locked);
            lockField(field, locked);
        });
        return $entry;
    }

    /**
     * Invoked when the user commits to the new field values.
     */
    function commitFieldValuesEntry() {
        const func     = "commitFieldValuesEntry"; OUT.debug(func);
        const original = getOriginalFieldValues(func);
        const current  = getColumnValues(getFieldValuesEntry());
        const result   = {};
        for (const [field, value] of Object.entries(current)) {
            let use_value = true;
            if (hasKey(original, field)) {
                const orig = toInputValue(original[field]);
                const curr = toInputValue(value);
                use_value  = (curr !== orig);
            }
            if (use_value) {
                result[field] = value;
            }
        }
        setFieldResultsData(result);
    }

    /**
     * Get the field value element.
     *
     * @param {string|jQuery|HTMLElement} field
     *
     * @returns {jQuery}
     */
    function fieldValueCell(field) {
        const func = "fieldValueCell";
        let $result;
        if (typeof field === "string") {
            $result = getFieldValuesEntry().find(`[data-field="${field}"]`);
        } else {
            $result = $(field);
        }
        if (!$result.is('textarea[data-field]')) {
            OUT.warn(`${func}: not a field value:`, field);
        }
        return $result;
    }

    /**
     * Get the data field associated with the given element (from either itself
     * or the nearest parent).
     *
     * @param {Selector} target
     *
     * @returns {string|undefined}
     */
    function fieldFor(target) {
        const df   = "data-field";
        const $tgt = $(target);
        return $tgt.attr(df) || $tgt.parents(`[${df}]`).first().attr(df);
    }

    /**
     * If a field value column is not already locked, lock it if its contents
     * have changed.
     *
     * @param {ElementEvt} event
     */
    function lockIfChanged(event) {
        OUT.debug("lockIfChanged:", event);
        const $textarea = $(event.target);
        const current   = getValue($textarea);
        const previous  = getLatestFieldValue($textarea);
        if (current !== previous) {
            setLatestFieldValue($textarea, current);
            if (!isLockedFieldValue($textarea)) {
                lockFor($textarea).trigger("click");
            }
        }
        const field    = $textarea.attr("data-field");
        const original = originalFieldValues()[field] || "";
        if (current !== original) {
            enableCommit();
        }
    }

    /**
     * Get the most-recently-saved value for a field value element.
     *
     * @param {jQuery} $textarea
     *
     * @returns {string}
     */
    function getLatestFieldValue($textarea) {
        const value_name = LookupModal.FIELD_LATEST_DATA;
        return $textarea.data(value_name)?.trim() || "";
    }

    /**
     * Set the most-recently-saved value for a field value element.
     *
     * @param {jQuery} $textarea
     * @param {string} [value]        Default: current value of $textarea.
     */
    function setLatestFieldValue($textarea, value) {
        const value_name = LookupModal.FIELD_LATEST_DATA;
        const new_value  = isDefined(value) ? value : getValue($textarea);
        $textarea.data(value_name, new_value);
    }

    // ========================================================================
    // Functions - field locks
    // ========================================================================

    /**
     * Get the entry row element containing the lock/unlock radio buttons
     * controlling the updatability of each associated field value.
     *
     * @returns {jQuery}
     */
    function getFieldLocksEntry() {
        return $field_locks;
    }

    /**
     * Set the field locks row element.
     *
     * @param {jQuery} $entry
     *
     * @returns {jQuery}
     */
    function setFieldLocksEntry($entry) {
        return $field_locks = $entry;
    }

    /**
     * Get the field lock associated with the given data field.
     *
     * @param {Selector} target
     *
     * @returns {jQuery}
     */
    function lockFor(target) {
        const fld  = fieldFor(target);
        /** @type {jQuery} */
        const $row = getFieldLocksEntry(),
              $col = $row.children(`[data-field="${fld}"]`);
        return $col.find(LookupModal.LOCK);
    }

    /**
     * Indicate whether the given field value is locked.
     *
     * @param {string|jQuery|HTMLElement} field
     *
     * @returns {boolean}
     */
    function isLockedFieldValue(field) {
        const flag_name = LookupModal.FIELD_LOCKED_DATA;
        return !!fieldValueCell(field).data(flag_name);
    }

    /**
     * Lock the associated field value from being updated by changing the
     * selected entry. <p/>
     *
     * (The field is not disabled, so it is still editable by the user.)
     *
     * @param {string|jQuery|HTMLElement} field
     * @param {boolean}                   [locking] If *false*, unlock instead.
     */
    function lockFieldValue(field, locking) {
        OUT.debug("lockFieldValue:", field, locking);
        const $cell   = fieldValueCell(field);
        const $lock   = lockFor($cell);
        const $input  = $lock;
        const $slider = $lock.parent().find('.slider');
        const $state  = $lock.parent().find('.state');
        const name    = $state.attr("data-name");
        const locked  = (locking !== false);
        const tip     = locked ? UNLOCK_TIP : LOCK_TIP;
        const label   = locked ? LOCK_LBL   : UNLOCK_LBL;
        const status  = locked ? "locked"   : "unlocked";
        $cell.data(LookupModal.FIELD_LOCKED_DATA, locked);
        $input.attr("title", tip);
        $slider.css("--label", `"${label}"`);
        $state.text(`${name} ${Emma.Terms.lookup.field_is} ${status}`);
    }

    /**
     * Lock/unlock a field.
     *
     * @param {string|jQuery|HTMLElement} field
     * @param {boolean}                   [locking] If *false*, unlock instead.
     */
    function lockField(field, locking) {
        OUT.debug("lockField:", field, locking);
        lockFieldValue(field, locking);
        columnLockout(field, locking);
    }

    /**
     * The lock/unlock control is toggled.
     *
     * @param {ElementEvt} event
     */
    function toggleFieldLock(event) {
        OUT.debug("toggleFieldLock:", event);
        const $target = $(event.target);
        const field   = fieldFor($target);
        const locked  = $target.is(':checked');
        lockField(field, locked);
    }

    /**
     * Toggle the appearance of a column of values based on the locked state of
     * the related field.
     *
     * @param {string}  field
     * @param {boolean} lock
     */
    function columnLockout(field, lock) {
        const HEAD    = LookupModal.HEADING_ROWS;
        const $rows   = entriesList().children('.row').not(HEAD);
        const $column = $rows.children(`[data-field="${field}"]`);
        $column.toggleClass("locked-out", lock);
    }

    /**
     * Add "locked-out" to every field of an entry row according to the locked
     * state of the related field.
     *
     * @param {Selector} entry
     */
    function fieldLockout(entry) {
        $(entry).children('[data-field]').each((_, column) => {
            const $field = $(column);
            const field  = $field.attr("data-field");
            const locked = isLockedFieldValue(field);
            $field.toggleClass("locked-out", locked);
        });
    }

    // ========================================================================
    // Methods - original values entry
    // ========================================================================

    /**
     * Get the entry row element containing the field values that were
     * originally supplied by to the form.
     *
     * @returns {jQuery}
     */
    function getOriginalValuesEntry() {
        return $original_values;
    }

    /**
     * Set the original values row element.
     *
     * @param {jQuery} $entry
     *
     * @returns {jQuery}
     */
    function setOriginalValuesEntry($entry) {
        return $original_values = $entry;
    }

    /**
     * Fill the original values row element from item data attached to the
     * toggle button.
     *
     * @param {string} [caller]       For log messages.
     *
     * @returns {jQuery}
     */
    function refreshOriginalValuesEntry(caller) {
        const func   = caller || "refreshOriginalValuesEntry";
        const data   = getOriginalFieldValues(func);
        const $entry = getOriginalValuesEntry();
        fillEntry($entry, data);
        $entry.data(LookupModal.ENTRY_ITEM_DATA, dupObject(data));
        return $entry;
    }

    // ========================================================================
    // Functions - entry selection
    // ========================================================================

    /**
     * Get the entry row element that has been selected by the user.
     *
     * @returns {jQuery}
     */
    function getSelectedEntry() {
        return $selected_entry ||=
            entrySelectButtons().filter(':checked').parents('.row').first();
    }

    /**
     * Set the entry row element that has been selected by the user.
     *
     * @param {jQuery} $entry
     *
     * @returns {jQuery}
     */
    function setSelectedEntry($entry) {
        return $selected_entry = $entry;
    }

    /**
     * Reset the selected entry to the "ORIGINAL" entry.
     */
    function resetSelectedEntry() {
        OUT.debug("resetSelectedEntry");
        $selected_entry = null;
        getOriginalValuesEntry().find('[type="radio"]').trigger("click");
    }

    /**
     * Use the entry row selected by the user to update unlocked field values.
     *
     * @param {Selector} [entry]      Default: {@link getSelectedEntry}
     */
    function useSelectedEntry(entry) {
        OUT.debug("useSelectedEntry:", entry);
        let $entry   = entry ? setSelectedEntry($(entry)) : getSelectedEntry();
        let values   = entryValues($entry);
        let $fields  = getFieldValuesEntry();
        let columns  = $fields.children('[data-field]').toArray();
        let unlocked = columns.filter(col => !isLockedFieldValue(col));
        let writable = unlocked.map(col => fieldFor(col));
        fillEntry($fields, values, writable);
    }

    /**
     * The user selects a lookup result entry as the basis for the new field
     * values for the originating submission entry. <p/>
     *
     * The event target is assumed to have an entry row as a parent.
     *
     * @param {ElementEvt} event
     */
    function selectEntry(event) {
        OUT.debug("selectEntry:", event);
        hideLoadingOverlay();
        /** @type {jQuery} */
        const $target = $(event.currentTarget || event.target),
              $entry  = $target.parents('.row').first();
        if ($target.attr("type") !== "radio") {
            $target.trigger("focus");
            $entry.find('[type="radio"]').trigger("click");
        } else if ($target.is(':checked')) {
            entrySelectButtons().not($target).prop("checked", false);
            useSelectedEntry($entry);
            if ($entry.is(LookupModal.RESULT)) {
                enableCommit();
            } else if (commitButton().is(LookupModal.DISABLED)) {
                // For the initial selection of the "ORIGINAL" row, lock all
                // the fields that already have data.
                $entry.children('[data-field]').each((_, column) => {
                    const $field = $(column);
                    if (isPresent($field.text())) {
                        lockFor($field).trigger("click");
                    }
                });
            }
        }
    }

    /**
     * Accentuate all of the elements of the related entry. <p/>
     *
     * The event target is assumed to have an entry row as a parent.
     *
     * @param {ElementEvt} event
     */
    function highlightEntry(event) {
        const $target = $(event.target);
        const $entry  = $target.parents('.row').first();
        $entry.children().toggleClass("highlight", true);
    }

    /**
     * De-accentuate all of the elements of the related entry. <p/>
     *
     * The event target is assumed to have an entry row as a parent.
     *
     * @param {ElementEvt} event
     */
    function unhighlightEntry(event) {
        const $target = $(event.target);
        const $entry  = $target.parents('.row').first();
        $entry.children().toggleClass("highlight", false);
    }

    // ========================================================================
    // Functions - entry values
    // ========================================================================

    /**
     * Get a copy of the given entry's field values.
     *
     * @param {Selector} entry
     *
     * @returns {LookupResponseItem}
     */
    function entryValues(entry) {
        const $entry = $(entry);
        const values = $entry.data(LookupModal.ENTRY_ITEM_DATA);
        return values ? dupObject(values) : getColumnValues($entry);
    }

    /**
     * Get the values of the entry from its data fields.
     *
     * @param {jQuery}   $entry
     * @param {string[]} [fields]
     *
     * @returns {LookupResponseItem}
     */
    function getColumnValues($entry, fields) {
        const columns = fields || LookupModal.DATA_COLUMNS;
        return toObject(columns, c => getColumnValue($entry, c));
    }

    /**
     * Get the value(s) of the entry's data field.
     *
     * @param {jQuery} $entry
     * @param {string} field
     *
     * @returns {string[]|string}
     */
    function getColumnValue($entry, field) {
        /** @type {jQuery} */
        const $column = $entry.children(`[data-field="${field}"]`);
        const value   = getValue($column);
        return toDataValue(value);
    }

    /**
     * Update the entry's data field displayed value(s).
     *
     * @param {jQuery} $entry
     * @param {string} field
     * @param {*}      field_value
     */
    function setColumnValue($entry, field, field_value) {
        /** @type {jQuery} */
        const $column = $entry.children(`[data-field="${field}"]`);
        let value     = toInputValue(field_value);
        setLatestFieldValue($column, value);

        if ($column.is('textarea')) {
            // Operating on a column of the $field_values entry.  In addition
            // to setting the value of the input field, store a copy for use
            // when checking for editing.
            $column.val(value);

        } else if (isPresent($column)) {
            // Operating on a column of a result entry.  Separate discrete
            // value parts visually with breaks.
            let $text = $column.children('.text');
            if (isMissing($text)) {
                $text = $('<div>').addClass("text").appendTo($column);
            }
            value = toDataValue(field_value);
            if (Array.isArray(value)) {
                const $tmp  = $('<i>');
                const lines = value.map(line => $tmp.text(line).html());
                $text.html(lines.join(HTML_BREAK));
            } else {
                $text.text(value);
            }
        }
    }

    // ========================================================================
    // Functions - entry display
    // ========================================================================

    /**
     * The container of the element containing the list of entries.
     *
     * @returns {jQuery}
     */
    function entriesDisplay() {
        return $entries_display ||=
            presence(container().find(LookupModal.ENTRIES)) || $(null);
    }

    /**
     * The element containing all generated lookup entries.
     *
     * @returns {jQuery}
     */
    function entriesList() {
        return $entries_list ||= entriesDisplay().find('.list');
    }

    /**
     * All entry selection radio buttons.
     *
     * **Implementation Notes**
     * This can't be "memoized" because the set of radio buttons will change
     * as entries are added dynamically.
     *
     * @returns {jQuery}
     */
    function entrySelectButtons() {
        return entriesList().find('.selection [type="radio"]');
    }

    /**
     * Present a candidate lookup result entry.
     *
     * @param {LookupResponse} message
     */
    function updateEntries(message) {
        const func = "updateEntries";
        const data = message.data;
        const init = modal && !modal.tabCycleStart;

        if (message.status === "STARTING") {
            OUT.debug(`${func}: ignoring STARTING message`);

        } else if (isMissing(data)) {
            OUT.warn(`${func}: missing message.data`);

        } else if (data.blend) {
            OUT.debug(`${func}: ignoring message.data.blend`);

        } else if (isMissing(data.items)) {
            OUT.warn(`${func}: empty message.data.items`);

        } else {
            OUT.debug(`${func}: ${Object.keys(data.items).length} entries`);
            const request = getRequestData();
            const req_ids = presence(request.ids);
            const service = camelCase(message.service);
            for (const [id, items] of Object.entries(data.items)) {
                const use_all = !req_ids || req_ids.includes(id);
                items.forEach(item => {
                    if (use_all || intersects(req_ids, item.dc_identifier)) {
                        addEntry(item, service);
                    }
                });
            }
        }

        modal.tabCycleStart ||= init && $start_tabbable;
    }

    /**
     * Include a candidate lookup result entry.
     *
     * @param {LookupResponseItem} item
     * @param {string}             [label]
     * @param {string}             [css_class]
     *
     * @returns {jQuery}
     */
    function addEntry(item, label, css_class) {
        OUT.debug("addEntry:", item, label, css_class);
        const $list  = entriesList();
        const row    = $list.children('.row').length;
        const $entry = makeResultEntry(row, label, css_class);
        fieldLockout($entry);
        fillEntry($entry, item);
        if (item) {
            $entry.data(LookupModal.ENTRY_ITEM_DATA, dupObject(item));
        }
        return $entry.appendTo($list);
    }

    /**
     * Fill **$entry** data fields from **item**.
     *
     * @param {jQuery}             $entry
     * @param {LookupResponseItem} item
     * @param {string[]}           [fields]
     *
     * @returns {jQuery}
     */
    function fillEntry($entry, item, fields) {
        const data    = item || {};
        const columns = fields || LookupModal.DATA_COLUMNS;
        columns.forEach(col => setColumnValue($entry, col, data[col]));
        return $entry;
    }

    /**
     * Remove all entries (not including the head and field values rows). <p/>
     *
     * If $entries_list does not exist, this returns immediately.
     */
    function resetEntries() {
        const func = "resetEntries";
        OUT.debug(func);
        if ($entries_list) {
            const RESERVED_ROWS = LookupModal.RESERVED_ROWS;
            $entries_list.children().not(RESERVED_ROWS).remove();
            refreshOriginalValuesEntry(func);
        } else {
            // Cause an empty list with reserved rows to be created.
            entriesList();
        }
        resetSelectedEntry();
        refreshFieldValuesEntry(func);
    }

    // ========================================================================
    // Functions - entry display
    // ========================================================================

    /**
     * Generate the container including the initially-empty list of entries.
     *
     * @returns {jQuery}
     */
    function makeEntriesDisplay() {
        const css      = LookupModal.ENTRIES_CLASS;
        const $display = $('<div>').addClass(css);
        const $list    = makeEntriesList();
        return $display.append($list);
    }

    /**
     * Generate the list of entries containing only the "reserved" non-entry
     * rows (column headers, field values, and field locks).
     *
     * @returns {jQuery}
     */
    function makeEntriesList() {
        const css        = "list";
        const cols       = LookupModal.ALL_COLUMNS.length;
        const $list      = $('<div>').addClass(`${css} columns-${cols}`);
        let row          = 0;
        const $heads     = makeHeadEntry(row++);
        const $values    = makeFieldValuesEntry(row++);
        const $locks     = makeFieldLocksEntry(row++);
        const $originals = makeOriginalValuesEntry(row++);
        return $list.append($heads, $values, $locks, $originals);
    }

    /**
     * Generate a lookup results entries heading row.
     *
     * @param {number} row
     *
     * @returns {jQuery}
     */
    function makeHeadEntry(row) {
        const css    = LookupModal.HEAD_ENTRY_CLASS;
        const fields = LookupModal.ALL_COLUMNS;
        const cols   = fields.map(label => makeHeadColumn(label));
        return makeEntry(row, cols, css);
    }

    /**
     * Generate the lookup results entries row which is primed with the
     * user-selected lookup result entry.
     *
     * @param {number} row
     *
     * @returns {jQuery}
     */
    function makeFieldValuesEntry(row) {
        const css     = LookupModal.FIELD_VALUES_CLASS;
        const fields  = LookupModal.DATA_COLUMNS;
        const $select = makeBlankColumn();
        const $label  = makeTagColumn();
        const inputs  = fields.map(field => makeFieldInputColumn(field));
        const cols    = [$select, $label, ...inputs];
        respondAsHighlightable(inputs);
        return setFieldValuesEntry(makeEntry(row, cols, css));
    }

    /**
     * Generate the row of controls which lock/unlock the contents of the
     * associated field value. <p/>
     *
     * Headings for the first two columns are displayed here rather than the
     * head row.
     *
     * @param {number} row
     *
     * @returns {jQuery}
     */
    function makeFieldLocksEntry(row) {
        const css     = LookupModal.FIELD_LOCKS_CLASS;
        const fields  = LookupModal.DATA_COLUMNS;
        const TABLE   = LookupModal.ENTRY_TABLE;
        const $select = makeBlankColumn(TABLE["selection"].label);
        const $label  = makeTagColumn(TABLE["tag"].label);
        const locks   = fields.map(field => makeFieldLockColumn(field));
        const cols    = [$select, $label, ...locks];
        return setFieldLocksEntry(makeEntry(row, cols, css));
    }

    /**
     * Generate the field contents of the original values row element.
     *
     * @param {number} row
     *
     * @returns {jQuery}
     */
    function makeOriginalValuesEntry(row) {
        const func = "makeOriginalValuesEntry";
        const tag  = Emma.Terms.original.toUpperCase();
        const css  = LookupModal.ORIG_VALUES_CLASS;
        setOriginalValuesEntry(makeResultEntry(row, tag, css));
        return refreshOriginalValuesEntry(func);
    }

    /**
     * Generate a row of data values from a lookup result entry.
     *
     * @param {number} row
     * @param {string} tag
     * @param {string} [css_class]    Default: {@link LookupModal.RESULT_CLASS}
     *
     * @returns {jQuery}
     */
    function makeResultEntry(row, tag, css_class) {
        const css    = css_class || LookupModal.RESULT_CLASS;
        const fields = LookupModal.DATA_COLUMNS;
        const label  = tag || capitalize(Emma.Terms.result);
        const $radio = makeSelectColumn();
        const $label = makeTagColumn(label);
        const values = fields.map(field => makeDataColumn(field));
        const cols   = [$radio, $label, ...values];
        handleClickAndKeypress($label, selectEntry);
        respondAsHighlightable(cols);
        respondAsVisibleOnFocus(cols);
        return makeEntry(row, cols, css);
    }

    /**
     * Generate a new row to be included in list of lookup results entries.
     *
     * @param {number}   row
     * @param {jQuery[]} columns
     * @param {string}   [css_class]
     *
     * @returns {jQuery}
     */
    function makeEntry(row, columns, css_class) {
        const css    = `row row-${row} ${css_class}`.trim();
        const $entry = $('<div>').addClass(css);
        columns.forEach(($c, col) => $c.addClass(`row-${row} col-${col}`));
        return $entry.append(columns);
    }

    /**
     * Generate the input area for a specific data field.
     *
     * @param {string}          field
     * @param {string|string[]} [value]
     * @param {string}          [css_class]
     *
     * @returns {jQuery}
     */
    function makeFieldInputColumn(field, value, css_class) {
        const $cell = $('<textarea>').attr("data-field", field);
        if (css_class) { $cell.addClass(css_class) }
        $cell.val(toInputValue(value));
        monitorEditing($cell);
        return $cell;
    }

    /**
     * Generate a field lock element.
     *
     * @param {string}         field
     * @param {boolean|string} [value]
     * @param {string}         [css_class]
     *
     * @returns {jQuery}
     */
    function makeFieldLockColumn(field, value, css_class) {
        const $cell = $('<div>').attr("data-field", field);
        const parts = makeLockControl(field);
        if (css_class) { $cell.addClass(css_class) }
        return $cell.append(parts);
    }

    /**
     * Generate an invisible checkbox paired with a visible indicator.
     *
     * @param {string}  field
     * @param {boolean} [checked]     If *true*, start in the locked state.
     *
     * @returns {[jQuery,jQuery]}
     */
    function makeLockControl(field, checked) {
        const name    = `lock-${field}`;
        const label   = LookupModal.ENTRY_TABLE[field]?.label || field;
        const id_base = randomizeName(field);
        const lbl_id  = `state-${id_base}`;
        const locked  = !!checked;

        /** @type {jQuery} */
        const $checkbox = $(`<input class="${LookupModal.LOCK_CLASS}">`);
        $checkbox.attr("type",            "checkbox");
        $checkbox.attr("role",            "switch");
        $checkbox.attr("name",            name);
        $checkbox.attr("aria-labelledby", lbl_id);
        $checkbox.attr("aria-checked",    locked);
        $checkbox.prop("checked",         locked);

        /** @type {jQuery} */
        const $slider = $('<div class="slider">');
        const $state  = $('<div class="state">');
        $state.attr("id",        lbl_id);
        $state.attr("data-name", label);

        /** @type {jQuery} */
        const $indicator = $('<div class="lock-indicator">');
        $indicator.attr("aria-hidden", true).append($slider).append($state);

        handleEvent($checkbox, "change", toggleFieldLock);
        return [$checkbox, $indicator];
    }

    /**
     * Generate a radio button for selecting the associated entry.
     *
     * @param {boolean} [active]
     *
     * @returns {jQuery}
     */
    function makeSelectColumn(active) {
        const css   = "selection";
        const $cell = $('<div>').addClass(css);
        const parts = makeSelectControl(active);
        return $cell.append(parts);
    }

    /**
     * Generate an invisible radio button paired with a visible indicator.
     *
     * @param {boolean} [active]
     * @param {string}  [css_class]
     *
     * @returns {[jQuery,jQuery]}
     */
    function makeSelectControl(active, css_class) {
        const $outer     = $('<div>').addClass("outer");
        const $inner     = $('<div>').addClass("inner");
        const $indicator = $('<div>').addClass("select-indicator");
        const $radio     = $('<input>').attr("type", "radio");
        if (css_class) { $radio.addClass(css_class) }
        $radio.prop("checked", (active === true));
        handleEvent($radio, "change", selectEntry);
        $start_tabbable ||= $radio;
        return [$radio, $indicator.append($outer, $inner)];
    }

    /**
     * Generate a heading row element with the label of the related data field.
     *
     * @param {string} field
     * @param {string} [css_class]
     *
     * @returns {jQuery}
     */
    function makeHeadColumn(field, css_class) {
        const value = LookupModal.ENTRY_TABLE[field]?.label || field;
        return makeBlankColumn(value, css_class);
    }

    /**
     * Generate an element for holding a designation for the related entry.
     *
     * @param {string} [label]
     *
     * @returns {jQuery}
     */
    function makeTagColumn(label) {
        const css = "tag";
        return makeBlankColumn(label).addClass(css);
    }

    /**
     * Generate an element for holding the value of the given field from the
     * related entry.
     *
     * @param {string} field
     * @param {string} [value]
     * @param {string} [css_class]
     *
     * @returns {jQuery}
     */
    function makeDataColumn(field, value, css_class) {
        const $cell = makeBlankColumn(value).attr("data-field", field);
        if (css_class) { $cell.addClass(css_class) }
        handleClickAndKeypress($cell, selectEntry);
        return $cell;
    }

    /**
     * Generate an empty column element.
     *
     * @param {string} [label]
     * @param {string} [css_class]
     *
     * @returns {jQuery}
     */
    function makeBlankColumn(label, css_class) {
        const $content = $('<span class="text">').text(label || "");
        const $cell    = $('<div>');
        if (css_class) { $cell.addClass(css_class) }
        return $cell.append($content);
    }

    // ========================================================================
    // Functions - event handlers
    // ========================================================================

    /**
     * Setup event handlers on a field value column to lock the field if the
     * user changes it manually.
     *
     * @param {Selector} item
     */
    function monitorEditing(item) {
        handleEvent(item, "input", debounce(lockIfChanged));
    }

    /**
     * Make the given items highlight when hovered or focused.
     *
     * @param {Selector|Selector[]} items
     */
    function respondAsHighlightable(items) {
        const enter = highlightEntry;
        const leave = unhighlightEntry;
        arrayWrap(items).forEach(i => handleHoverAndFocus(i, enter, leave));
    }

    /**
     * Make the given items scroll into view when visited by tabbing.
     *
     * @note This doesn't do anything yet...
     *
     * @param {Selector|Selector[]} items
     */
    function respondAsVisibleOnFocus(items) {
        //const scroll = (ev => $(ev.target)[0].scrollIntoView(false));
        //arrayWrap(items).forEach(i => handleEvent($(i), "focus", scroll));
    }

    // ========================================================================
    // Functions - input - prompt display
    // ========================================================================

    /**
     * The element containing manual input controls.
     *
     * @returns {jQuery}
     */
    function inputPrompt() {
        return $prompt ||= container().find(LookupModal.PROMPT);
    }

    /**
     * The `<input>` control for manual input.
     *
     * @returns {jQuery}
     */
    function inputText() {
        return $input ||= inputPrompt().find('[type="text"]');
    }

    /**
     * The submit button for manual input.
     *
     * @returns {jQuery}
     */
    function inputSubmit() {
        return $submit ||= inputPrompt().find('[type="submit"], .submit');
    }

    /**
     * The radio buttons for manual selection of allowed separator(s).
     *
     * @returns {jQuery}
     */
    function inputSeparator() {
        return $separator ||= inputPrompt().find('[type="radio"]');
    }

    // ========================================================================
    // Functions - input - search terms
    // ========================================================================

    /**
     * Get the terms to lookup.
     *
     * @returns {string|undefined}
     */
    function getSearchTerms() {
        return inputText().val();
    }

    /**
     * Set the terms to lookup.
     *
     * @param {string|string[]} terms
     * @param {string}          [separator]
     *
     * @returns {jQuery}
     */
    function setSearchTerms(terms, separator) {
        OUT.debug("setSearchTerms:", terms, separator);
        const chars  = (separator || getSeparators()).replaceAll("\\s", " ");
        const sep    = chars[0];
        const parts  = arrayWrap(terms);
        const $query = queryTerms();
        if (isPresent($query)) {
            const query_parts =
                parts.map(part => {
                    const words  = part.split(":");
                    const prefix = words.shift();
                    let value    = words.join(":");
                    if (value.match(/\s/)) {
                        value = `"${value}"`;
                    }
                    return `${prefix}:${value}`;
                });
            $query.text(query_parts.join(" "));
        }
        return inputText().val(parts.join(sep));
    }

    /**
     * Create the lookup request from the search terms provided by the event
     * target.
     *
     * @param {ElementEvt} [event]
     */
    function updateSearchTerms(event) {
        OUT.debug("updateSearchTerms:", event);
        const $data_src = event ? $(event.target) : dataElement();
        const data      = $data_src.data(LookupModal.SEARCH_TERMS_DATA);
        const request   = setRequestData(data);
        setSearchTerms(request.terms);
    }

    // ========================================================================
    // Functions - input - separator selection
    // ========================================================================

    /**
     * Return the currently-selected separator character(s).
     *
     * @returns {string}
     */
    function getSeparators() {
        const key = inputSeparator().filter(':checked').val();
        const SEP = LookupModal.SEPARATORS;
        return SEP[key] || SEP[LookupModal.DEF_SEPARATORS_KEY];
    }

    /**
     * Update the separator radio button selection if necessary.
     *
     * @param {string} new_characters
     *
     * @returns {string}
     */
    function setSeparators(new_characters) {
        if (getSeparators() !== new_characters) {
            $.each(LookupModal.SEPARATORS, (key, characters) => {
                if (new_characters !== characters) { return true } // continue
                $separator.filter(`[value="${key}"]`).trigger("click");
                return false; // break
            });
        }
        return new_characters;
    }

    // ========================================================================
    // Functions - output - message display
    // ========================================================================

    /**
     * The `<h2>` before the output display area.
     *
     * @returns {jQuery}
     */
    function panelHeading() {
        return $heading ||= container().find(LookupModal.HEADING);
    }

    /**
     * The output display area container
     *
     * @returns {jQuery}
     */
    function outputDisplay() {
        return $output ||= container().find(LookupModal.OUTPUT);
    }

    /**
     * Direct result display.
     *
     * @returns {jQuery}
     */
    function resultDisplay() {
        return $results ||= outputDisplay().find(LookupModal.RESULTS);
    }

    /**
     * Direct error display.
     *
     * @returns {jQuery}
     */
    function errorDisplay() {
        return $errors ||= outputDisplay().find(LookupModal.ERRORS);
    }

    /**
     * Direct diagnostics display.
     *
     * @returns {jQuery}
     */
    function diagnosticDisplay() {
        return $diagnostics ||= outputDisplay().find(LookupModal.DIAGNOSTICS);
    }

    // ========================================================================
    // Functions - output - message display
    // ========================================================================

    /**
     * Remove result display contents.
     */
    function clearResultDisplay() {
        resultDisplay().text("");
    }

    /**
     * Remove error display contents.
     */
    function clearErrorDisplay() {
        errorDisplay().text("");
    }

    /**
     * Remove diagnostic display contents.
     */
    function clearDiagnosticDisplay() {
        diagnosticDisplay().text("");
    }

    /**
     * Update the main display element.
     *
     * @param {LookupResponse|LookupResponsePayload} message
     */
    function updateResultDisplay(message) {
        const data = message?.payload || message || {};
        updateDisplay(resultDisplay(), data);
    }

    /**
     * Update the error log element.
     *
     * @param {object} data
     */
    function updateErrorDisplay(data) {
        updateDisplay(errorDisplay(), data);
    }

    /**
     * Update the diagnostics display element.
     *
     * @param {object} data
     */
    function updateDiagnosticDisplay(data) {
        updateDisplay(diagnosticDisplay(), data, "");
    }

    /**
     * Update the contents of a display element.
     *
     * @param {jQuery} $element
     * @param {object} data
     * @param {string} gap
     */
    function updateDisplay($element, data, gap = "\n") {
        const added = renderJson(data);
        let text    = $element.text()?.trimEnd();
        if (text) {
            text = text.concat("\n", gap, added);
        } else {
            text = added;
        }
        $element.text(text);
    }

    /**
     * Initialize the state of a display element.
     *
     * @param {jQuery} $element
     */
    function initializeDisplay($element) {
        if (!$element.attr("readonly")) {
            $element.attr("readonly", "true");
        }
        $element.text("");
    }

    // ========================================================================
    // Functions - in-progress overlay
    // ========================================================================

    /**
     * The overlay indicating that loading is occurring.
     *
     * @returns {jQuery}
     */
    function getLoadingOverlay() {
        return $loading_overlay ||=
            presence(container().children(LookupModal.LOADING)) ||
            makeLoadingOverlay().prependTo(container());
    }

    /**
     * Generate the element containing the loading overlay image.
     *
     * @param {boolean} [visible]     If *true*, do not create hidden.
     *
     * @returns {jQuery}
     */
    function makeLoadingOverlay(visible) {
        const css    = LookupModal.LOADING_CLASS;
        const hidden = (visible !== true);
        const $image = $('<div>').addClass("content");
        const $line  = $('<div>').addClass(css).append($image);
        return toggleHidden($line, hidden);
    }

    /**
     * Show the overlay indicating that loading is occurring.
     */
    function showLoadingOverlay() {
        toggleHidden(getLoadingOverlay(), false);
    }

    /**
     * Hide the overlay indicating that loading is occurring.
     */
    function hideLoadingOverlay() {
        toggleHidden(getLoadingOverlay(), true);
    }

}
