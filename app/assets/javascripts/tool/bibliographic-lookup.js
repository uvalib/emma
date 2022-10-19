// app/assets/javascripts/tool/bibliographic-lookup.js
//
// Bibliographic Lookup
//
// noinspection JSUnusedLocalSymbols


import { arrayWrap }                      from '../shared/arrays'
import { turnOffAutocomplete }            from '../shared/form'
import { HTML_BREAK }                     from '../shared/html'
import { renderJson }                     from '../shared/json'
import { LookupModal }                    from '../shared/lookup-modal'
import { LookupRequest }                  from '../shared/lookup-request'
import { ModalDialog }                    from '../shared/modal-dialog'
import { ModalHideHooks, ModalShowHooks } from '../shared/modal_hooks'
import { dupObject, toObject }            from '../shared/objects'
import { randomizeName }                  from '../shared/random'
import { camelCase }                      from '../shared/strings'
import {
    isDefined,
    isEmpty,
    isMissing,
    isPresent,
    presence,
} from '../shared/definitions'
import {
    debounce,
    handleClickAndKeypress,
    handleEvent,
    handleHoverAndFocus,
    isEvent,
} from '../shared/events'


// ============================================================================
// Functions
// ============================================================================

// noinspection FunctionTooLongJS
/**
 * Setup a page with interactive bibliographic lookup.
 *
 * @param {Selector}                                      base
 * @param {CallbackChainFunction|CallbackChainFunction[]} [show_hooks]
 * @param {CallbackChainFunction|CallbackChainFunction[]} [hide_hooks]
 *
 * @returns {Promise}
 */
export async function setup(base, show_hooks, hide_hooks) {

    const $base = $(base);

    /** @type {jQuery|undefined} */
    const $popup_button = $base.is('.lookup-button') ? $base : undefined;

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

    // ========================================================================
    // Channel
    // ========================================================================

    const channel = await import('../channels/lookup-channel');

    channel.disconnectOnPageExit(_debugging());

    channel.setCallback(updateResultDisplay);
    channel.setErrorCallback(updateErrorDisplay);
    channel.setDiagnosticCallback(updateDiagnosticDisplay);

    channel.addCallback(updateStatusPanel);

    if ($popup_button) {
        channel.addCallback(updateSearchResultsData);
        channel.addCallback(updateEntries);
    }

    // ========================================================================
    // Variables
    // ========================================================================

    /**
     * The modal class instance.
     *
     * @type {ModalDialog|undefined}
     */
    const modal = $popup_button?.data(ModalDialog.MODAL_INSTANCE);

    /**
     * Base element associated with the dialog.
     *
     * @type {jQuery}
     */
    const $root =
        modal?.modalPanel ||
        $popup_button?.siblings(ModalDialog.PANEL) ||
        $('body');

    /**
     * Operational status elements.
     *
     * @type {jQuery}
     */
    let $query_panel, $query_terms, $status_panel, $notice, $services;

    /**
     * Result entry elements.
     *
     * @type {jQuery}
     */
    let $entries_display, $entries_list, $loading;

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
        handleEvent(inputText(), 'keyup', manualSubmission);
        handleClickAndKeypress(inputSubmit(), manualSubmission);
        turnOffAutocomplete(inputText());
        queryPanel().addClass(LookupModal.HIDDEN_MARKER);
    } else {
        inputPrompt().addClass(LookupModal.HIDDEN_MARKER);
    }

    if (output) {
        initializeDisplay(resultDisplay());
        initializeDisplay(errorDisplay());
        initializeDisplay(diagnosticDisplay());
    } else {
        outputHeading().addClass(LookupModal.HIDDEN_MARKER);
        outputDisplay().addClass(LookupModal.HIDDEN_MARKER);
    }

    if (isModal()) {
        ModalShowHooks.set($popup_button, show_hooks, onShowModal);
        ModalHideHooks.set($popup_button, onHideModal, hide_hooks);
    } else {
        entriesDisplay().addClass(LookupModal.HIDDEN_MARKER);
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

    // ========================================================================
    // Functions
    // ========================================================================

    /**
     * Submit the query terms as a lookup request.
     *
     * @param {|jQuery.Event|Event|KeyboardEvent} event
     */
    function manualSubmission(event) {
        if (isEvent(event, KeyboardEvent) && (event.key !== 'Enter')) {
            return;
        }
        _debug('manualSubmission:', event);
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
     * @returns {boolean|undefined}
     *
     * @see onShowModalHook
     */
    function onShowModal(_$target, check_only, halted) {
        _debug('onShowModal:', _$target, check_only, halted);
        if (check_only || halted) { return }
        resetSearchResultsData();
        clearFieldResultsData();
        updateSearchTerms();
        disableCommit();
        resetEntries();
        showLoading();
        performRequest();
    }

    /**
     * Commit when leaving the popup from the Update button.
     *
     * @param {jQuery}  $target       Checked for `.is(LookupModal.COMMIT)`.
     * @param {boolean} check_only
     * @param {boolean} [halted]
     *
     * @returns {boolean|undefined}
     *
     * @see onHideModalHook
     */
    function onHideModal($target, check_only, halted) {
        _debug('onHideModal:', $target, check_only, halted);
        if (check_only || halted) {
            // do nothing
        } else if ($target.is(LookupModal.COMMIT)) {
            commitFieldValuesEntry();
        } else {
            clearFieldResultsData();
        }
    }

    /**
     * Perform the lookup request.
     */
    function performRequest() {
        _debug('performRequest');
        initializeStatusPanel();
        if (output) {
            clearResultDisplay();
            clearErrorDisplay();
        }
        channel.request(getRequestData());
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
     * @param {string|string[]|LookupRequest|LookupRequestObject} data
     *
     * @returns {LookupRequest}       The current request object.
     */
    function setRequestData(data) {
        _debug('setRequestData:', data);
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
     *
     * @returns {void}
     */
    function clearRequestData() {
        _debug('clearRequestData');
        dataElement().removeData(LookupModal.REQUEST_DATA);
    }

    // ========================================================================
    // Functions - response data
    // ========================================================================

    /**
     * Lookup results are stored as a table of job identifiers mapped on to
     * their associated responses.
     *
     * @typedef {{[job_id: string]: LookupResponseObject}} LookupResults
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
        _debug('setSearchResultsData:', value);
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
        _debug('resetSearchResultsData');
        return setSearchResultsData(blankSearchResultsData());
    }

    /**
     * Update the data object with the response data.
     *
     * @param {LookupResponse} message
     */
    function updateSearchResultsData(message) {
        _debug('updateSearchResultsData:', message);
        const key = message.job_id || randomizeName('response');
        const obj = getSearchResultsData() || resetSearchResultsData();
        obj[key] = message.objectCopy;
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
            const func = caller || 'getOriginalFieldValues';
            const name = LookupModal.ENTRY_ITEM_DATA;
            console.warn(`${func}: toggle missing .data(${name})`);
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
     * @param {LookupResponseItem|undefined} [value]
     */
    function setFieldResultsData(value) {
        _debug('setFieldResultsData:', value);
        const new_value = value || {};
        dataElement().data(LookupModal.FIELD_RESULTS_DATA, new_value);
    }

    /**
     * Clear the user-selected field values from lookup.
     *
     * @returns {void}
     */
    function clearFieldResultsData() {
        _debug('clearFieldResultsData');
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
        return $query_panel ||= presence($root.find(LookupModal.QUERY_PANEL));
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
    function statusPanel() {
        $status_panel ||= presence($root.find(LookupModal.STATUS_PANEL));
        $status_panel ||= makeStatusPanel().insertAfter(inputPrompt());
        return $status_panel;
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
        $notice ||= statusPanel().find(LookupModal.NOTICE);
        if (isDefined(value)) {
            $notice.text(value);
            if (tooltip) {
                $notice.addClass('tooltip').attr('title', tooltip);
            } else {
                $notice.removeClass('tooltip').removeAttr('title');
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
        $services ||= statusPanel().find(LookupModal.SERVICES);
        if (isDefined(services)) {
            _debug('serviceStatuses:', services);
            if (isMissing($services.children('label'))) {
                $('<label>').text('Searching:').prependTo($services);
            }
            let names = arrayWrap(services);
            let data  = $services.data('names');
            if (data) {
                names = names.filter(srv => !data.includes(srv));
            } else {
                $services.data('names', (data = []));
            }
            if (isPresent(names)) {
                const statuses = names.map(name => makeServiceStatus(name));
                $services.append(statuses);
                data.push(...names);
            }
            $services.removeClass('invisible');
        }
        return $services;
    }

    /**
     * Clear service status contents and data.
     */
    function clearServiceStatuses() {
        _debug('clearServiceStatuses');
        serviceStatuses().removeData('names').find('.service').remove();
    }

    /**
     * Change status values based on received data.
     *
     * @param {LookupResponse} message
     */
    function updateStatusPanel(message) {
        const func  = 'updateStatusPanel';
        _debug(`${func}:`, message);
        const state = message.status?.toUpperCase();
        const srv   = message.service;
        const data  = message.data;
        let finish, notice, n_tip, status;
        switch (state) {

            // Waiter states

            case 'STARTING':
                notice = 'Working';
                serviceStatuses(srv);
                break;
            case 'TIMEOUT':
                notice = 'Done';
                n_tip  = 'Some searches took longer than expected';
                finish = true;
                break;
            case 'PARTIAL':
                notice = 'Done';
                n_tip  = 'Partial results received';
                finish = true;
                break;
            case 'COMPLETE':
                notice = 'Done';
                finish = true;
                break;

            // Worker states

            case 'WORKING':
                notice =`${statusNotice().text()}.`;
                break;
            case 'LATE':
                status = 'late';
                break;
            case 'DONE':
                status = isEmpty(data?.items) ? ['done', 'empty'] : 'done';
                break;

            // Other

            default:
                console.warn(`${func}: ${message.status}: unexpected`);
                break;
        }
        if (notice) { statusNotice(notice, n_tip) }
        if (status) { serviceStatuses().find(`.${srv}`).addClass(status) }
        if (finish) { hideLoading() }
    }

    // ========================================================================
    // Functions - lookup status display
    // ========================================================================

    /**
     * Put the status panel into the default state with any previous service
     * status elements removed.
     */
    function initializeStatusPanel() {
        _debug('initializeStatusPanel');
        serviceStatuses().removeClass('invisible');
        clearServiceStatuses();
        statusNotice('Starting...');
    }

    /**
     * Generate the element displaying the state of the parallel requests.
     *
     * @param {string} [css_class]  Def: {@link LookupModal.STATUS_PANEL_CLASS}
     *
     * @returns {jQuery}
     */
    function makeStatusPanel(css_class) {
        const css        = css_class || LookupModal.STATUS_PANEL_CLASS;
        const $container = $('<div>').addClass(css);
        const $services  = makeServiceStatuses();
        const $notice    = makeStatusNotice();
        return $container.append($services, $notice);
    }

    /**
     * Generate the element for displaying textual status information.
     *
     * @param {string} [css_class]  Default: {@link LookupModal.NOTICE_CLASS}
     *
     * @returns {jQuery}
     */
    function makeStatusNotice(css_class) {
        const css = css_class || LookupModal.NOTICE_CLASS;
        return $('<div>').addClass(css);
    }

    /**
     * Generate the element containing the dynamic set of external services.
     *
     * @param {string} [css_class]  Default: {@link LookupModal.SERVICES_CLASS}
     *
     * @returns {jQuery}
     */
    function makeServiceStatuses(css_class) {
        const css = css_class || LookupModal.SERVICES_CLASS;
        return $('<div>').addClass(css);
    }

    /**
     * Generate an element for displaying the status of an external service.
     *
     * @param {string} [name]         Service name; default: 'unknown'.
     * @param {string} [css_class]    Default: 'service'
     *
     * @returns {jQuery}
     */
    function makeServiceStatus(name, css_class) {
        const css     = css_class || 'service';
        const service = name      || 'unknown';
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
        _debug('enableCommit:', enable);
        const $button = commitButton();
        const marker  = LookupModal.DISABLED_MARKER;
        const set     = (enable === false);
        return $button.toggleClass(marker, set).prop('disabled', set);
    }

    /**
     * Disable commit button(s).
     *
     * @param {boolean} [disable]     If *false*, enable.
     *
     * @returns {jQuery}              The commit button(s).
     */
    function disableCommit(disable) {
        _debug('disableCommit:', disable);
        const $button = commitButton();
        const marker  = LookupModal.DISABLED_MARKER;
        const set     = (disable !== false);
        return $button.toggleClass(marker, set).prop('disabled', set);
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
            return $elem.val()?.trim() || '';
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

        } else if (typeof item !== 'string') {
            return item?.toString() || '';

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
        if (typeof item === 'string') {
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
        const func   = caller || 'refreshFieldValuesEntry';
        const data   = getOriginalFieldValues(func);
        const $entry = getFieldValuesEntry();
        fillEntry($entry, data);
        $entry.find('textarea').each((_, column) => {
            const $field = $(column);
            const lock   = !!getValue($field);
            this.lockFor($field).prop('checked', lock);
            this.lockFieldValue($field, lock);
        });
        return $entry;
    }

    /**
     * Invoked when the user commits to the new field values.
     */
    function commitFieldValuesEntry() {
        const func     = 'commitFieldValuesEntry';
        _debug(func);
        const original = getOriginalFieldValues(func);
        const current  = getColumnValues(getFieldValuesEntry());
        const result   = {};
        $.each(current, (field, value) => {
            let use_value = true;
            if (original.hasOwnProperty(field)) {
                const orig = toInputValue(original[field]);
                const curr = toInputValue(value);
                use_value  = (curr !== orig);
            }
            if (use_value) {
                result[field] = value;
            }
        });
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
        const func = 'fieldValueCell';
        let $result;
        if (typeof field === 'string') {
            $result = getFieldValuesEntry().find(`[data-field="${field}"]`);
        } else {
            $result = $(field);
        }
        if (!$result.is('textarea[data-field]')) {
            console.warn(`${func}: not a field value:`, field);
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
        const df   = 'data-field';
        const $tgt = $(target);
        return $tgt.attr(df) || $tgt.parents(`[${df}]`).first().attr(df);
    }

    /**
     * If a field value column is not already locked, lock it if its contents
     * have changed.
     *
     * @param {jQuery.Event|Event} event
     */
    function lockIfChanged(event) {
        _debug('lockIfChanged:', event);
        const $textarea = $(event.target);
        const current   = getValue($textarea);
        const previous  = getLatestFieldValue($textarea);
        if (current !== previous) {
            setLatestFieldValue($textarea, current);
            if (!isLockedFieldValue($textarea)) {
                lockFor($textarea).click();
            }
        }
        const field    = $textarea.attr('data-field');
        const original = originalFieldValues()[field] || '';
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
        return $textarea.data(value_name)?.trim() || '';
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
        const field = fieldFor(target);
        /** @type {jQuery} */
        let $column = getFieldLocksEntry().children(`[data-field="${field}"]`);
        return $column.find(LookupModal.LOCK);
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
     * selected entry.
     *
     * (The field is not disabled, so it is still editable by the user.)
     *
     * @param {string|jQuery|HTMLElement} field
     * @param {boolean}                   [locking] If *false*, unlock instead.
     */
    function lockFieldValue(field, locking) {
        _debug('lockFieldValue:', field, locking);
        const flag_name = LookupModal.FIELD_LOCKED_DATA;
        const lock      = (locking !== false);
        fieldValueCell(field).data(flag_name, lock);
    }

    /**
     * Unlock the associated field value to allow updating by changing the
     * selected entry.
     *
     * @param {string|jQuery|HTMLElement} field
     * @param {boolean}                   [unlocking] If *false*, lock instead.
     */
    function unlockFieldValue(field, unlocking) {
        _debug('unlockFieldValue:', field, unlocking);
        const flag_name = LookupModal.FIELD_LOCKED_DATA;
        const lock      = (unlocking === false);
        fieldValueCell(field).data(flag_name, lock);
    }

    /**
     * The lock/unlock control is toggled.
     *
     * @param {jQuery.Event|Event} event
     */
    function toggleFieldLock(event) {
        _debug('toggleFieldLock:', event);
        const $target = $(event.target);
        const field   = fieldFor($target);
        const lock    = $target.is(':checked');
        lockFieldValue(field, lock);
        columnLockout(field, lock);
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
        $column.toggleClass('locked-out', lock);
    }

    /**
     * Add 'locked-out' to every field of an entry row according to the locked
     * state of the related field.
     *
     * @param {Selector} entry
     */
    function fieldLockout(entry) {
        $(entry).children('[data-field]').each((_, column) => {
            const $field = $(column);
            const field  = $field.attr('data-field');
            const locked = isLockedFieldValue(field);
            $field.toggleClass('locked-out', locked);
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
        const func   = caller || 'refreshOriginalValuesEntry';
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
        _debug('resetSelectedEntry');
        $selected_entry = null;
        getOriginalValuesEntry().find('[type="radio"]').click();
    }

    /**
     * Use the entry row selected by the user to update unlocked field values.
     *
     * @param {Selector} [entry]      Default: {@link getSelectedEntry}
     */
    function useSelectedEntry(entry) {
        _debug('useSelectedEntry:', entry);
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
     * values for the originating submission entry.
     *
     * The event target is assumed to have an entry row as a parent.
     *
     * @param {jQuery.Event|Event} event
     */
    function selectEntry(event) {
        _debug('selectEntry:', event);
        /** @type {jQuery} */
        const $target = $(event.currentTarget || event.target),
              $entry  = $target.parents('.row').first();
        if ($target.attr('type') !== 'radio') {
            $target.focus();
            $entry.find('[type="radio"]').click();
        } else if ($target.is(':checked')) {
            entrySelectButtons().not($target).prop('checked', false);
            useSelectedEntry($entry);
            if ($entry.is(LookupModal.RESULT)) {
                enableCommit();
            } else if (commitButton().is(LookupModal.DISABLED)) {
                // For the initial selection of the "ORIGINAL" row, lock all
                // the fields that already have data.
                $entry.children('[data-field]').each((_, column) => {
                    const $field = $(column);
                    if (isPresent($field.text())) {
                        lockFor($field).click();
                    }
                });
            }
        }
    }

    /**
     * Accentuate all of the elements of the related entry.
     *
     * The event target is assumed to have an entry row as a parent.
     *
     * @param {jQuery.Event|Event} event
     */
    function highlightEntry(event) {
        const $target = $(event.target);
        const $entry  = $target.parents('.row').first();
        $entry.children().toggleClass('highlight', true);
    }

    /**
     * De-accentuate all of the elements of the related entry.
     *
     * The event target is assumed to have an entry row as a parent.
     *
     * @param {jQuery.Event|Event} event
     */
    function unhighlightEntry(event) {
        const $target = $(event.target);
        const $entry  = $target.parents('.row').first();
        $entry.children().toggleClass('highlight', false);
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
        const columns = fields || LookupModal.DATA_COLUMNS
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
                $text = $('<div>').addClass('text').appendTo($column);
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
        $entries_display ||= presence($root.find(LookupModal.ENTRIES));
        $entries_display ||= makeEntriesDisplay().insertAfter(statusPanel());
        return $entries_display;
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
        const func = 'updateEntries';
        const data = message.data;
        const init = modal && !modal.tabCycleStart;

        if (message.status === 'STARTING') {
            _debug(`${func}: ignoring STARTING message`);

        } else if (isMissing(data)) {
            console.warn(`${func}: missing message.data`);

        } else if (data.blend) {
            _debug(`${func}: ignoring empty message.data.blend`);

        } else if (isMissing(data.items)) {
            console.warn(`${func}: empty message.data.items`);

        } else {
            const request = getRequestData();
            const req_ids = presence(request.ids);
            const service = camelCase(message.service);
            $.each(data.items, (id, items) => {
                if (!req_ids || req_ids.includes(id)) {
                    items.forEach(item => addEntry(item, service));
                }
            });
        }

        if (init && $start_tabbable) {
            modal.tabCycleStart = $start_tabbable;
        }
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
        _debug('addEntry:', item, label, css_class);
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
     * Fill *$entry* data fields from *item*.
     *
     * @param {jQuery}             $entry
     * @param {LookupResponseItem} item
     * @param {string[]}           [fields]
     *
     * @returns {jQuery}
     */
    function fillEntry($entry, item, fields) {
        const data    = item || {};
        const columns = fields || LookupModal.DATA_COLUMNS
        columns.forEach(col => setColumnValue($entry, col, data[col]));
        return $entry;
    }

    /**
     * Remove all entries (not including the head and field values rows).
     *
     * If $entries_list does not exist, this returns immediately.
     */
    function resetEntries() {
        const func = 'resetEntries';
        _debug(func);
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

    /**
     * The placeholder indicating that loading is occurring.
     *
     * @returns {jQuery}
     */
    function loadingPlaceholder() {
        return $loading ||= entriesList().children(LookupModal.LOADING);
    }

    /**
     * Show the placeholder indicating that loading is occurring.
     */
    function showLoading() {
        loadingPlaceholder().toggleClass(LookupModal.HIDDEN_MARKER, false);
    }

    /**
     * Hide the placeholder indicating that loading is occurring.
     */
    function hideLoading() {
        loadingPlaceholder().toggleClass(LookupModal.HIDDEN_MARKER, true);
    }

    // ========================================================================
    // Functions - entry display
    // ========================================================================

    /**
     * Generate the container including the initially-empty list of entries.
     *
     * @param {string} [css_class] Default: {@link LookupModal.ENTRIES_CLASS}
     *
     * @returns {jQuery}
     */
    function makeEntriesDisplay(css_class) {
        const css      = css_class || LookupModal.ENTRIES_CLASS;
        const $display = $('<div>').addClass(css);
        const $list    = makeEntriesList();
        return $display.append($list);
    }

    /**
     * Generate the list of entries containing only the "reserved" non-entry
     * rows (column headers, field values, and field locks).
     *
     * @param {string} [css_class]    Default: 'list'
     *
     * @returns {jQuery}
     */
    function makeEntriesList(css_class) {
        const css        = css_class || 'list';
        const cols       = LookupModal.ALL_COLUMNS.length;
        const $list      = $('<div>').addClass(`${css} columns-${cols}`);
        let row          = 0;
        const $heads     = makeHeadEntry(row++);
        const $values    = makeFieldValuesEntry(row++);
        const $locks     = makeFieldLocksEntry(row++);
        const $originals = makeOriginalValuesEntry(row++);
        const $loading   = makeLoadingPlaceholder();
        return $list.append($heads, $values, $locks, $originals, $loading);
    }

    /**
     * Generate a lookup results entries heading row.
     *
     * @param {number} row
     * @param {string} [css_class]   Def.: {@link LookupModal.HEAD_ENTRY_CLASS}
     *
     * @returns {jQuery}
     */
    function makeHeadEntry(row, css_class) {
        const css    = css_class || LookupModal.HEAD_ENTRY_CLASS;
        const fields = LookupModal.ALL_COLUMNS;
        const cols   = fields.map(label => makeHeadColumn(label));
        return makeEntry(row, cols, css);
    }

    /**
     * Generate the lookup results entries row which is primed with the
     * user-selected lookup result entry.
     *
     * @param {number} row
     * @param {string} [css_class] Def.: {@link LookupModal.FIELD_VALUES_CLASS}
     *
     * @returns {jQuery}
     */
    function makeFieldValuesEntry(row, css_class) {
        const css     = css_class || LookupModal.FIELD_VALUES_CLASS;
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
     * associated field value.
     *
     * Headings for the first two columns are displayed here rather than the
     * head row.
     *
     * @param {number} row
     * @param {string} [css_class]  Def.: {@link LookupModal.FIELD_LOCKS_CLASS}
     *
     * @returns {jQuery}
     */
    function makeFieldLocksEntry(row, css_class) {
        const css     = css_class || LookupModal.FIELD_LOCKS_CLASS;
        const fields  = LookupModal.DATA_COLUMNS;
        const TABLE   = LookupModal.ENTRY_TABLE;
        const $select = makeBlankColumn(TABLE['selection'].label);
        const $label  = makeTagColumn(TABLE['tag'].label);
        const locks   = fields.map(field => makeFieldLockColumn(field));
        const cols    = [$select, $label, ...locks];
        return setFieldLocksEntry(makeEntry(row, cols, css));
    }

    /**
     * Generate the field contents of the original values row element.
     *
     * @param {number} row
     * @param {string} [css_class]  Def.: {@link LookupModal.ORIG_VALUES_CLASS}
     *
     * @returns {jQuery}
     */
    function makeOriginalValuesEntry(row, css_class) {
        const func = 'makeOriginalValuesEntry';
        const tag  = 'ORIGINAL'; // TODO: I18n
        const css  = css_class || LookupModal.ORIG_VALUES_CLASS;
        setOriginalValuesEntry(makeResultEntry(row, tag, css));
        return refreshOriginalValuesEntry(func);
    }

    /**
     * Generate a row of data values from a lookup result entry.
     *
     * @param {number} row
     * @param {string} tag
     * @param {string} [css_class] Default: {@link LookupModal.RESULT_CLASS}
     *
     * @returns {jQuery}
     */
    function makeResultEntry(row, tag, css_class) {
        const css    = css_class || LookupModal.RESULT_CLASS;
        const fields = LookupModal.DATA_COLUMNS;
        const label  = tag || 'Result'; // TODO: I18n
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
        const css    = 'row';
        const $entry = $('<div>').addClass(`${css} row-${row}`);
        if (css_class) {
            $entry.addClass(css_class);
        }
        let col    = 0;
        const cols = columns.map($c => $c.addClass(`row-${row} col-${col++}`));
        return $entry.append(cols);
    }

    /**
     * Generate the element containing the loading placeholder image.
     *
     * @param {boolean} [visible]     If *true* do not create hidden.
     * @param {string}  [css_class]   Def.: {@link LookupModal.LOADING_CLASS}.
     */
    function makeLoadingPlaceholder(visible, css_class) {
        const css    = css_class || LookupModal.LOADING_CLASS;
        const hidden = visible ? '' : LookupModal.HIDDEN_MARKER;
        const $line  = $('<div>').addClass(`${css} ${hidden}`);
        const $image = $('<div>'); // @see stylesheets/controllers/_entry.scss
        return $line.append($image);
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
        const $cell = $('<textarea>').attr('data-field', field);
        $cell.val(toInputValue(value));
        if (css_class) {
            $cell.addClass(css_class);
        }
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
        const $cell = $('<div>').attr('data-field', field);
        if (css_class) {
            $cell.addClass(css_class);
        }
        const parts = makeLockControl(`lock-${field}`);
        return $cell.append(parts);
    }

    /**
     * Generate an invisible checkbox paired with a visible indicator.
     *
     * @param {string}  [name]
     * @param {boolean} [checked]
     * @param {string}  [css_class] Default: {@link LookupModal.LOCK_CLASS}.
     *
     * @returns {[jQuery,jQuery]}
     */
    function makeLockControl(name, checked, css_class) {
        const css      = css_class || LookupModal.LOCK_CLASS;
        let $slider    = $('<div>').addClass('slider');
        let $indicator = $('<div>').addClass('lock-indicator').append($slider);
        let $checkbox  = $('<input>').attr('type', 'checkbox').addClass(css);
        isDefined(name)    && $checkbox.attr('name',    name);
        isDefined(checked) && $checkbox.prop('checked', checked);
        handleEvent($checkbox, 'change', toggleFieldLock);
        return [$checkbox, $indicator];
    }

    /**
     * Generate a radio button for selecting the associated entry.
     *
     * @param {boolean} [active]
     * @param {string}  [css_class]   Default: 'selection'.
     *
     * @returns {jQuery}
     */
    function makeSelectColumn(active, css_class) {
        const css   = css_class || 'selection';
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
        const $outer     = $('<div>').addClass('outer');
        const $inner     = $('<div>').addClass('inner');
        const $indicator = $('<div>').addClass('select-indicator');
        const $radio     = $('<input>').attr('type', 'radio');
        if (css_class) {
            $radio.addClass(css_class);
        }
        $radio.prop('checked', (active === true));
        handleEvent($radio, 'change', selectEntry);
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
     * @param {string} [css_class]    Default: 'tag'.
     *
     * @returns {jQuery}
     */
    function makeTagColumn(label, css_class) {
        const css = css_class || 'tag';
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
        const $cell = makeBlankColumn(value).attr('data-field', field);
        if (css_class) {
            $cell.addClass(css_class);
        }
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
        const $content = $('<span class="text">').text(label || '');
        const $cell    = $('<div>');
        if (css_class) {
            $cell.addClass(css_class);
        }
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
        const $item = $(item);
        handleEvent($item, 'input', debounce(lockIfChanged));
    }

    /**
     * Make the given items highlight when hovered or focused.
     *
     * @param {Selector|Selector[]} items
     */
    function respondAsHighlightable(items) {
        const enter = highlightEntry;
        const leave = unhighlightEntry;
        arrayWrap(items).forEach(i => handleHoverAndFocus($(i), enter, leave));
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
        //arrayWrap(items).forEach(i => handleEvent($(i), 'focus', scroll));
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
        return $prompt ||= $root.find(LookupModal.PROMPT);
    }

    /**
     * The <input> control for manual input.
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
        _debug('setSearchTerms:', terms, separator);
        const chars  = (separator || getSeparators()).replaceAll('\\s', ' ');
        const sep    = chars[0];
        const parts  = arrayWrap(terms);
        const $query = queryTerms();
        if (isPresent($query)) {
            const query_parts =
                parts.map(function(part) {
                    const words  = part.split(':');
                    const prefix = words.shift();
                    let value    = words.join(':');
                    if (value.match(/\s/)) {
                        value = `"${value}"`;
                    }
                    return `${prefix}:${value}`;
                });
            $query.text(query_parts.join(' '));
        }
        return inputText().val(parts.join(sep));
    }

    /**
     * Create the lookup request from the search terms provided by the event
     * target.
     *
     * @param {jQuery.Event|Event} [event]
     */
    function updateSearchTerms(event) {
        _debug('updateSearchTerms:', event);
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
            $.each(LookupModal.SEPARATORS, function(key, characters) {
                if (new_characters !== characters) { return true } // continue
                $separator.filter(`[value="${key}"]`).trigger('click');
                return false; // break
            });
        }
        return new_characters;
    }

    // ========================================================================
    // Functions - output - message display
    // ========================================================================

    /**
     * The <h2> before the output display area.
     *
     * @returns {jQuery}
     */
    function outputHeading() {
        return $heading ||= $root.find(LookupModal.HEADING);
    }

    /**
     * The output display area container
     *
     * @returns {jQuery}
     */
    function outputDisplay() {
        return $output ||= $root.find(LookupModal.OUTPUT);
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
        resultDisplay().text('');
    }

    /**
     * Remove error display contents.
     */
    function clearErrorDisplay() {
        errorDisplay().text('');
    }

    /**
     * Remove diagnostic display contents.
     */
    function clearDiagnosticDisplay() {
        diagnosticDisplay().text('');
    }

    /**
     * Update the main display element.
     *
     * @param {LookupResponse|LookupResponseObject} message
     */
    function updateResultDisplay(message) {
        const data = message?.object || message || {};
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
        updateDisplay(diagnosticDisplay(), data, '');
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
        if (!$element.attr('readonly')) {
            $element.attr('readonly', 'true');
        }
        $element.text('');
    }

    // ========================================================================
    // Functions - other
    // ========================================================================

    /**
     * Indicate whether console debugging is active.
     *
     * @returns {boolean}
     */
    function _debugging() {
        return window.DEBUG.activeFor('BibliographicLookup', false);
    }

    /**
     * Emit a console message if debugging.
     *
     * @param {...*} args
     */
    function _debug(...args) {
        _debugging() && console.log(...args);
    }

}
