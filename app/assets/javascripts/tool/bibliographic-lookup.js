// app/assets/javascripts/tool/bibliographic-lookup.js
//
// Bibliographic Lookup


import { arrayWrap }                      from '../shared/arrays'
import { turnOffAutocomplete }            from '../shared/form'
import { HTML_BREAK }                     from '../shared/html'
import { renderJson }                     from '../shared/json'
import { LookupModal }                    from '../shared/lookup-modal'
import { LookupRequest }                  from '../shared/lookup-request'
import { ModalDialog }                    from '../shared/modal-dialog'
import { ModalHideHooks, ModalShowHooks } from '../shared/modal_hooks'
import { compact, dupObject, toObject }   from '../shared/objects'
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

    const DEBUGGING = false;

    let $base = $(base);

    /** @type {jQuery|undefined} */
    let $popup_button = $base.is('.lookup-button') ? $base : undefined;

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

    /** @type {LookupChannel} */
    let channel = await import('../channels/lookup-channel');

    channel.disconnectOnPageExit(DEBUGGING);

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
    let modal = $popup_button?.data(ModalDialog.MODAL_INSTANCE);

    /**
     * Base element associated with the dialog.
     *
     * @type {jQuery}
     */
    let $root =
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
        queryPanel().addClass('hidden');
    } else {
        inputPrompt().addClass('hidden');
    }

    if (output) {
        initializeDisplay(resultDisplay());
        initializeDisplay(errorDisplay());
        initializeDisplay(diagnosticDisplay());
    } else {
        outputHeading().addClass('hidden');
        outputDisplay().addClass('hidden');
    }

    if (isModal()) {
        ModalShowHooks.set($popup_button, show_hooks, onShowModal);
        ModalHideHooks.set($popup_button, onHideModal, hide_hooks);
    } else {
        entriesDisplay().addClass('hidden');
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
        clearFieldValuesData();
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
            clearFieldValuesData();
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
        let key  = message.job_id || randomizeName('response');
        let obj  = getSearchResultsData() || resetSearchResultsData();
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
    // Functions - new field values data
    // ========================================================================

    /**
     * Get user-selected field values stored on the data object.
     *
     * @returns {LookupResponseItem|undefined}
     */
    function getFieldValuesData() {
        return dataElement().data(LookupModal.FIELD_VALUES_DATA);
    }

    /**
     * Store the user-selected field values on the data object.
     *
     * @param {LookupResponseItem|undefined} [value]
     */
    function setFieldValuesData(value) {
        _debug('setFieldValuesData:', value);
        const new_value = value || {};
        dataElement().data(LookupModal.FIELD_VALUES_DATA, new_value);
    }

    /**
     * Clear the user-selected field values from lookup.
     *
     * @returns {void}
     */
    function clearFieldValuesData() {
        _debug('clearFieldValuesData');
        dataElement().removeData(LookupModal.FIELD_VALUES_DATA);
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
     *
     * @returns {jQuery}
     */
    function statusNotice(value) {
        $notice ||= statusPanel().find(LookupModal.NOTICE);
        return isDefined(value) ? $notice.text(value) : $notice;
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
        let finish, notice, status;
        switch (state) {

            // Waiter states

            case 'STARTING':
                notice = 'Working';
                serviceStatuses(srv);
                break;
            case 'TIMEOUT':
                notice = '(some searches took longer than expected)';
                finish = true;
                break;
            case 'PARTIAL':
                notice = '(partial results received)';
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
        if (notice) { statusNotice(notice) }
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
     * @param [css_class] Default: {@link LookupModal.STATUS_PANEL_CLASS}
     *
     * @returns {jQuery}
     */
    function makeStatusPanel(css_class) {
        const css      = css_class || LookupModal.STATUS_PANEL_CLASS;
        let $container = $('<div>').addClass(css);
        let $services  = makeServiceStatuses();
        let $notice    = makeStatusNotice();
        return $container.append($services, $notice);
    }

    /**
     * Generate the element for displaying textual status information.
     *
     * @param [css_class] Default: {@link LookupModal.NOTICE_CLASS}
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
     * @param [css_class] Default: {@link LookupModal.SERVICES_CLASS}
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
     * @param [name]                  Service name; default: 'unknown'.
     * @param [css_class]             Default: 'service'
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
     * {@link LookupModal.FIELD_VALUES_DATA FIELD_VALUES_DATA} from the current
     * contents of {@link $field_values}.
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
        let $button = commitButton();
        const set   = (enable === false);
        return $button.toggleClass('disabled', set).prop('disabled', set);
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
        let $button = commitButton();
        const set   = (disable !== false);
        return $button.toggleClass('disabled', set).prop('disabled', set);
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
     * Invoked when the user commits to the new field values.
     */
    function commitFieldValuesEntry() {
        _debug('commitFieldValuesEntry');
        let current    = getFieldValuesData();
        let new_values = entryValues(getFieldValuesEntry());
        if (isPresent(current)) {
            new_values = $.extend(true, current, new_values);
        }
        new_values = compact(new_values);
        setFieldValuesData(new_values);
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
        const df = 'data-field';
        let $tgt = $(target);
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
        let $textarea = $(event.target);
        if (!isLockedFieldValue($textarea)) {
            const current  = $textarea.val()?.trim() || '';
            const previous = getLatestFieldValue($textarea);
            if (current !== previous) {
                setLatestFieldValue($textarea, current);
                lockFor($textarea).click();
            }
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
        const value_name = LookupModal.FIELD_VALUE_DATA;
        return $textarea.data(value_name)?.trim() || '';
    }

    /**
     * Set the most-recently-saved value for a field value element.
     *
     * @param {jQuery} $textarea
     * @param {string} value
     */
    function setLatestFieldValue($textarea, value) {
        const value_name = LookupModal.FIELD_VALUE_DATA;
        const new_value  = value?.trim() || '';
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
        let $target = $(event.target);
        const field = fieldFor($target);
        const lock  = $target.is(':checked');
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
        const HEAD  = LookupModal.HEADING_ROWS;
        let $rows   = entriesList().children('.row').not(HEAD);
        let $column = $rows.children(`[data-field="${field}"]`);
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
            let $field   = $(column);
            const field  = $field.attr('data-field');
            const locked = isLockedFieldValue(field);
            $field.toggleClass('locked-out', locked);
        });
    }

    // ========================================================================
    // Methods - original field values
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
        let $target = $(event.currentTarget || event.target),
            $entry  = $target.parents('.row').first();
        if ($target.attr('type') !== 'radio') {
            $target.focus();
            $entry.find('[type="radio"]').click();
        } else if ($target.is(':checked')) {
            entrySelectButtons().not($target).prop('checked', false);
            useSelectedEntry($entry);
            if ($entry.is(LookupModal.RESULT)) {
                enableCommit();
            } else if (commitButton().is('.disabled')) {
                // For the initial selection of the "ORIGINAL" row, lock all
                // the fields that already have data.
                $entry.children('[data-field]').each((_, column) => {
                    let $field = $(column);
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
        let $target = $(event.target);
        let $entry  = $target.parents('.row').first();
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
        let $target = $(event.target);
        let $entry  = $target.parents('.row').first();
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
        let $entry = $(entry);
        let values = $entry.data(LookupModal.ENTRY_ITEM_DATA);
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
     * @returns {string[]|string|undefined}
     */
    function getColumnValue($entry, field) {
        /** @type {jQuery} */
        let $col  = $entry.children(`[data-field="${field}"]`);
        let value = $col.is('textarea') ? $col.val() : $col.text();
        if ((typeof value === 'string') && value.includes("\n")) {
            value = value.split("\n");
        }
        return value;
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
        let $column = $entry.children(`[data-field="${field}"]`);
        let value   = field_value;

        if ($column.is('textarea')) {
            // Operating on a column of the $field_values entry.  In addition
            // to setting the value of the input field, store a copy for use
            // when checking for editing.
            value = arrayWrap(value).join("\n").trim();
            $column.val(value);
            setLatestFieldValue($column, value);

        } else if (isPresent($column)) {
            // Operating on a column of a result entry.  Separate discrete
            // value parts visually with breaks.
            let $text = $column.children('.text');
            if (isMissing($text)) {
                $text = $('<div>').addClass('text').appendTo($column);
            }
            if ((typeof value === 'string') && value.includes("\n")) {
                value = value.split("\n");
            }
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
        let $list  = entriesList();
        const row  = $list.children('.row').length;
        let $entry = makeResultEntry(row, label, css_class);
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
        let data    = item || {};
        let columns = fields || LookupModal.DATA_COLUMNS
        columns.forEach(col => setColumnValue($entry, col, data[col]));
        return $entry;
    }

    /**
     * Remove all entries (not including the head and field values rows).
     *
     * If $entries_list does not exist, this returns immediately.
     */
    function resetEntries() {
        _debug('resetEntries');
        if ($entries_list) {
            $entries_list.children().not(LookupModal.RESERVED_ROWS).remove();
            getFieldValuesEntry().find('textarea').each((_, column) => {
                let $field = $(column);
                lockFor($field).prop('checked', false);
                unlockFieldValue($field);
                $field.val('');
            });
        } else {
            // Cause an empty list with reserved rows to be created.
            entriesList();
        }
        resetSelectedEntry();
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
        loadingPlaceholder().toggleClass('hidden', false);
    }

    /**
     * Hide the placeholder indicating that loading is occurring.
     */
    function hideLoading() {
        loadingPlaceholder().toggleClass('hidden', true);
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
        const css    = css_class || LookupModal.ENTRIES_CLASS;
        let $display = $('<div>').addClass(css);
        let $list    = makeEntriesList();
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
        const css      = css_class || 'list';
        const cols     = LookupModal.ALL_COLUMNS.length;
        let $list      = $('<div>').addClass(`${css} columns-${cols}`);
        let row        = 0;
        let $heads     = makeHeadEntry(row++);
        let $values    = makeFieldValuesEntry(row++);
        let $locks     = makeFieldLocksEntry(row++);
        let $originals = makeOriginalValuesEntry(row++);
        let $loading   = makeLoadingPlaceholder();
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
        let cols     = fields.map(label => makeHeadColumn(label));
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
        const css    = css_class || LookupModal.FIELD_VALUES_CLASS;
        const fields = LookupModal.DATA_COLUMNS;
        let $select  = makeBlankColumn();
        let $label   = makeTagColumn();
        let inputs   = fields.map(field => makeFieldInputColumn(field));
        let cols     = [$select, $label, ...inputs];
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
        const css    = css_class || LookupModal.FIELD_LOCKS_CLASS;
        const fields = LookupModal.DATA_COLUMNS;
        const TABLE  = LookupModal.ENTRY_TABLE;
        let $select  = makeBlankColumn(TABLE['selection'].label);
        let $label   = makeTagColumn(TABLE['tag'].label);
        let locks    = fields.map(field => makeFieldLockColumn(field));
        let cols     = [$select, $label, ...locks];
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
        const name = LookupModal.ENTRY_ITEM_DATA;
        let $entry = makeResultEntry(row, tag, css);
        let data   = dataElement().data(name);
        if (isPresent(data)) {
            fillEntry($entry, data);
            $entry.data(name, dupObject(data));
        } else {
            console.warn(`${func}: toggle missing .data(${name})`);
        }
        return setOriginalValuesEntry($entry);
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
        let $radio   = makeSelectColumn();
        let $label   = makeTagColumn(label);
        let values   = fields.map(field => makeDataColumn(field));
        let cols     = [$radio, $label, ...values];
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
        const css  = 'row';
        let $entry = $('<div>').addClass(`${css} row-${row}`);
        if (css_class) {
            $entry.addClass(css_class);
        }
        let col    = 0;
        let cols   = columns.map($c => $c.addClass(`row-${row} col-${col++}`));
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
        const hidden = visible ? '' : 'hidden';
        let $line    = $('<div>').addClass(`${css} ${hidden}`);
        let $image   = $('<div>'); // @see stylesheets/controllers/_entry.scss
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
        let $cell = $('<textarea>').attr('data-field', field);
        if (css_class) {
            $cell.addClass(css_class);
        }
        $cell.val(Array.isArray(value) ? value.join("\n") : value);
        monitorEditing($cell);
        return $cell;
    }

    /**
     * Generate a field lock element.
     *
     * @param {string}      field
     * @param {bool|string} [value]
     * @param {string}      [css_class]
     *
     * @returns {jQuery}
     */
    function makeFieldLockColumn(field, value, css_class) {
        let $cell = $('<div>').attr('data-field', field);
        if (css_class) {
            $cell.addClass(css_class);
        }
        let parts = makeLockControl(`lock-${field}`);
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
        const css = css_class || 'selection';
        let $cell = $('<div>').addClass(css);
        let parts = makeSelectControl(active);
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
        let $outer     = $('<div>').addClass('outer');
        let $inner     = $('<div>').addClass('inner');
        let $indicator = $('<div>').addClass('select-indicator');
        let $radio     = $('<input>').attr('type', 'radio');
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
        let $cell = makeBlankColumn(value).attr('data-field', field);
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
        let $content = $('<span class="text">').text(label || '');
        let $cell    = $('<div>');
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
        let $item = $(item);
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
        const chars = (separator || getSeparators()).replaceAll('\\s', ' ');
        const sep   = chars[0];
        const parts = arrayWrap(terms);
        let $query  = queryTerms();
        if (isPresent($query)) {
            let query_parts =
                parts.map(function(part) {
                    let words    = part.split(':');
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
        let $data_src = event ? $(event.target) : dataElement();
        const data    = $data_src.data(LookupModal.SEARCH_TERMS_DATA);
        const request = setRequestData(data);
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
        let added = renderJson(data);
        let text  = $element.text()?.trimEnd();
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

    /**
     * Console output if DEBUGGING is true.
     *
     * @param {...*} args
     * @private
     */
    function _debug(...args) {
        if (DEBUGGING) {
            console.log(...args);
        }
    }

}
