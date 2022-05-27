// app/assets/javascripts/tool/bibliographic-lookup.js
//
// Bibliographic Lookup


import { randomizeName, selector } from '../shared/css'
import { turnOffAutocomplete }     from '../shared/form'
import { LookupRequest }           from '../shared/lookup-request'
import { camelCase }               from '../shared/strings'
import { asDateTime }              from '../shared/time'
import {
    isDefined,
    isEmpty,
    isMissing,
    isPresent,
    presence,
} from '../shared/definitions'
import {
    handleClickAndKeypress,
    handleEvent,
    isEvent,
} from '../shared/events'
import {
    arrayWrap,
    deepFreeze,
    dupObject,
    maxSize
} from '../shared/objects'


// ============================================================================
// Constants
// ============================================================================

/**
 * The .data() key for storing the generated lookup request.
 *
 * @readonly
 * @type {string}
 */
export const REQUEST_DATA = 'lookupRequest';

/**
 * The .data() key for storing the field replacement(s) selected by the user.
 *
 * @readonly
 * @type {string}
 */
export const FIELD_VALUES_DATA = 'lookupFieldValues';

/**
 * The name by which parts of a search request can be passed in via jQuery
 * data().
 *
 * @readonly
 * @type {string}
 */
export const SEARCH_TERMS_DATA = 'lookupSearchTerms';

/**
 * The name by which the result of a search request can be passed back via
 * jQuery data().
 *
 * @readonly
 * @type {string}
 */
export const SEARCH_RESULT_DATA = 'lookupSearchResult';

/**
 * A table of separator style names and their associated separator characters.
 *
 * * space: Space, tab, newline and <strong>|</strong> (pipe)
 * * pipe:  Only <strong>|</strong> (pipe)
 *
 * @readonly
 * @type {{[k: string]: string}}
 */
const SEPARATORS = {
    space: '\\s|',
    pipe:  '|',
};

/**
 * The default key into {@link SEPARATORS}.
 *
 * @readonly
 * @type {string}
 */
const DEF_SEPARATORS_KEY = 'pipe';

/**
 * When replacing newlines with HTML breaks, it's important to retain the
 * newline itself so that `.text().split("\n")` can be used to reconstitute
 * arrays of values.
 *
 * @readonly
 * @type {string}
 */
const HTML_BREAK = "<br/>\n";

// ============================================================================
// Functions
// ============================================================================

// noinspection FunctionTooLongJS
/**
 * Setup a page with interactive bibliographic lookup.
 *
 * @param {Selector} [root]
 * @param {Selector} [source]         Element holding request term(s).
 * @param {function} [onOpen]         Called when opening the popup.
 *
 * @returns {Promise}
 */
export async function setup(root, source, onOpen) {

    /** @type {jQuery|undefined} */
    let $popup_button = source && $(source);

    // ========================================================================
    // Channel
    // ========================================================================

    let channel = await import('../channels/lookup_channel');

    channel.disconnectOnPageExit();
    channel.setCallback(updateResultDisplay);
    channel.setErrorCallback(updateErrorDisplay);
    channel.setDiagnosticCallback(updateDiagnosticDisplay);

    channel.addCallback(updateStatusPanel);
    
    if ($popup_button) {
        channel.addCallback(updateSearchResultsData);
        channel.addCallback(updateEntries);
    }

    // ========================================================================
    // Constants
    // ========================================================================

    const QUERY_PANEL_CLASS  = 'lookup-query';
    const QUERY_TERMS_CLASS  = 'terms';
    const STATUS_PANEL_CLASS = 'lookup-status';
    const NOTICE_CLASS       = 'notice';
    const SERVICES_CLASS     = 'services';
    const ENTRIES_CLASS      = 'lookup-entries';
    const HEAD_ENTRY_CLASS   = 'head';
    const FIELD_VALUES_CLASS = 'field-values';
    const PROMPT_CLASS       = 'lookup-prompt';
    const HEADING_CLASS      = 'lookup-heading';
    const OUTPUT_CLASS       = 'lookup-output';
    const RESULTS_CLASS      = 'item-results';
    const ERRORS_CLASS       = 'item-errors';
    const DIAGNOSTICS_CLASS  = 'item-diagnostics';

    const QUERY_PANEL        = selector(QUERY_PANEL_CLASS);
    const QUERY_TERMS        = selector(QUERY_TERMS_CLASS);
    const STATUS_PANEL       = selector(STATUS_PANEL_CLASS);
    const NOTICE             = selector(NOTICE_CLASS);
    const SERVICES           = selector(SERVICES_CLASS);
    const ENTRIES            = selector(ENTRIES_CLASS);
    const HEAD_ENTRY         = selector(HEAD_ENTRY_CLASS);
    const FIELD_VALUES       = selector(FIELD_VALUES_CLASS);
    const PROMPT             = selector(PROMPT_CLASS);
    const HEADING            = selector(HEADING_CLASS);
    const OUTPUT             = selector(OUTPUT_CLASS);
    const RESULTS            = selector(RESULTS_CLASS);
    const ERRORS             = selector(ERRORS_CLASS);
    const DIAGNOSTICS        = selector(DIAGNOSTICS_CLASS);

    /**
     * Schema for the columns displayed for each displayed lookup entry.
     *
     * @type {Object<{label: string, non_data?: bool}>}
     */
    const ENTRY_TABLE = deepFreeze({ // TODO: I18n
        selection:              { label: 'USE',  non_data: true },
        tag:                    { label: 'FROM', non_data: true },
        dc_identifier:          { label: 'IDENTIFIER' },
        dc_title:               { label: 'TITLE' },
        dc_creator:             { label: 'AUTHOR/CREATOR' },
        dc_publisher:           { label: 'PUBLISHER' },
        emma_publicationDate:   { label: 'DATE' },
        dcterms_dateCopyright:  { label: 'YEAR' },
        dc_description:         { label: 'DESCRIPTION' },
    });

    /**
     * All entry column keys.
     *
     * @type {string[]}
     */
    const ALL_COLUMNS = Object.keys(ENTRY_TABLE);

    /**
     * Keys for columns related to entry data values.
     *
     * @type {string[]}
     */
    const DATA_COLUMNS = deepFreeze(
        Object.entries(ENTRY_TABLE).map(kv => {
            let [field, config] = kv;
            return config.non_data ? [] : field;
        }).flat()
    );

    /**
     * For storing and retrieving entries values via jQuery .data().
     *
     * @type {string}
     */
    const ENTRY_ITEM_DATA = 'item-data';

    // ========================================================================
    // Variables
    // ========================================================================

    /**
     * Base element associated with the dialog.
     *
     * @type {jQuery}
     */
    let $root = root ? $(root) : $('body');

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
    let $entries_display, $entries_list, $entry_radio_buttons;

    /**
     * Result entry elements.
     *
     * @type {jQuery}
     */
    let $selected_entry, $field_values;

    /**
     * Raw communications display elements.
     *
     * @type {jQuery}
     */
    let $output      = $root.find(OUTPUT),
        $results     = $output.find(RESULTS),
        $errors      = $output.find(ERRORS),
        $diagnostics = $output.find(DIAGNOSTICS);

    /**
     * Manual input elements.
     *
     * @type {jQuery}
     */
    let $prompt    = $root.find(PROMPT),
        $input     = $prompt.find('[type="text"]'),
        $submit    = $prompt.find('[type="submit"], .submit'),
        $separator = $prompt.find('[type="radio"]');

    // ========================================================================
    // Event handlers
    // ========================================================================

    handleEvent($input, 'keyup', submit);
    handleClickAndKeypress($submit, submit);

    if ($popup_button) {
        handleClickAndKeypress($popup_button, submitOnOpen);
    }

    // ========================================================================
    // Actions
    // ========================================================================

    turnOffAutocomplete($input);

    initializeDisplay($results);
    initializeDisplay($errors);
    initializeDisplay($diagnostics);

    if ($popup_button) {
        resetSearchResultsData();
    }

    // ========================================================================
    // Functions
    // ========================================================================

    /**
     * Indicate whether operations are taking within a modal dialog.
     *
     * @returns {boolean}
     */
    function isModal() {
        return !!$popup_button;
    }

    /**
     * Submit the query terms as a lookup request.
     *
     * @param {|jQuery.Event|Event|KeyboardEvent} event
     */
    function submit(event) {
        if (isEvent(event, KeyboardEvent) && (event.key !== 'Enter')) {
            return;
        }
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
     * @param {jQuery.Event|Event} event
     */
    function submitOnOpen(event) {
        updateSearchTerms(event);
        performRequest();
    }

    /**
     * Perform the lookup request.
     */
    function performRequest() {
        initializeStatusPanel();
        clearResultDisplay();
        clearErrorDisplay();
        resetEntries();
        channel.request(getRequestData());
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
    // Functions - request data
    // ========================================================================

    /**
     * Get the current lookup request.
     *
     * @returns {LookupRequest|undefined}
     */
    function getRequestData() {
        const request = dataElement().data(REQUEST_DATA);
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
        let request = data;
        if (request instanceof LookupRequest) {
            setSeparators(request.separators);
        } else {
            request = new LookupRequest(request, getSeparators());
        }
        dataElement().data(REQUEST_DATA, request);
        return request;
    }

    /**
     * Clear the current lookup request.
     *
     * @returns {jQuery}              The effected element.
     */
    function clearRequestData() {
        return dataElement().removeData(REQUEST_DATA);
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
        return dataElement().data(SEARCH_RESULT_DATA);
    }

    /**
     * Set response data on the data object.
     *
     * @param {LookupResults} value
     *
     * @returns {LookupResults}
     */
    function setSearchResultsData(value) {
        dataElement().data(SEARCH_RESULT_DATA, value);
        return value;
    }

    /**
     * Empty response data from the data object.
     *
     * @returns {LookupResults}
     */
    function resetSearchResultsData() {
        return setSearchResultsData(blankSearchResultsData());
    }

    /**
     * Generate an empty response data object.
     *
     * @returns {LookupResults}
     */
    function blankSearchResultsData() {
        return {};
    }

    /**
     * Update the data object with the response data.
     *
     * @param {LookupResponse} message
     */
    function updateSearchResultsData(message) {
        let key     = message.job_id || randomizeName('response');
        let object  = getSearchResultsData() || resetSearchResultsData();
        object[key] = message.objectCopy;
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
        return dataElement().data(FIELD_VALUES_DATA);
    }

    /**
     * Store the user-selected field values on the data object.
     *
     * @param {LookupResponseItem} [value]
     *
     * @returns {jQuery}
     */
    function setFieldValuesData(value) {
        return dataElement().data(FIELD_VALUES_DATA, (value || {}));
    }

    /**
     * Clear the user-selected field values from lookup.
     *
     * @param {Selector} [form]
     *
     * @returns {jQuery}
     */
    function clearFieldValuesData(form) {
        return dataElement().removeData(FIELD_VALUES_DATA);
    }

    // ========================================================================
    // Functions - lookup query display
    // ========================================================================

    /**
     * queryPanel
     *
     * @returns {jQuery}
     */
    function queryPanel() {
        return $query_panel ||= presence($root.find(QUERY_PANEL));
    }

    /**
     * queryTerms
     *
     * @returns {jQuery}
     */
    function queryTerms() {
        return $query_terms ||= queryPanel().find(QUERY_TERMS);
    }

    // ========================================================================
    // Functions - lookup status display
    // ========================================================================

    /**
     * statusPanel
     *
     * @returns {jQuery}
     */
    function statusPanel() {
        $status_panel ||= presence($root.find(STATUS_PANEL));
        $status_panel ||= makeStatusPanel().insertAfter($prompt);
        return $status_panel;
    }

    /**
     * statusNotice
     *
     * @param {string} [value]
     *
     * @returns {jQuery}
     */
    function statusNotice(value) {
        $notice ||= statusPanel().find(NOTICE);
        if (isDefined(value)) {
            $notice.text(value || '');
        }
        return $notice;
    }

    /**
     * serviceStatuses
     *
     * @param {string|string[]} [services]
     *
     * @returns {jQuery}
     */
    function serviceStatuses(services) {
        $services ||= statusPanel().find(SERVICES);
        if (isDefined(services)) {
            if (isMissing($services.children('label'))) {
                $('<label>').text('Searching:').appendTo($services);
            }
            let data = $services.data('names');
            if (!data) {
                $services.data('names', (data = []));
            }
            arrayWrap(services).forEach(function(name) {
                if (!data.includes(name)) {
                    data.push(name);
                    makeServiceStatus(name).appendTo($services);
                }
            });
        }
        return $services;
    }

    /**
     * Clear service status elements.
     */
    function clearServiceStatuses() {
        serviceStatuses().removeData('names').find('.service').remove();
    }

    /**
     * Change status values based on received data.
     *
     * @param {LookupResponse} message
     */
    function updateStatusPanel(message) {
        const func = 'updateStatusPanel';
        let status;
        switch (message.status?.toUpperCase()) {

            // Waiter statuses

            case 'STARTING':
                statusNotice('Working');
                serviceStatuses(message.service).removeClass('invisible');
                break;
            case 'TIMEOUT':
                statusNotice('(some searches took longer than expected)');
                break;
            case 'PARTIAL':
                statusNotice('(partial results received)');
                break;
            case 'COMPLETE':
                statusNotice('Done');
                break;

            // Worker statuses

            case 'WORKING':
                statusNotice('' + statusNotice().text() + '.');
                break;
            case 'LATE':
                status = 'late';
                break;
            case 'DONE':
                const no_results = isEmpty(message.data.items);
                status = no_results ? ['done', 'empty'] : 'done';
                break;

            // Other

            default:
                console.warn(`${func}: ${message.status}: unexpected`);
                break;
        }
        if (status) {
            serviceStatuses().find(`.${message.service}`).addClass(status);
        }
    }

    // ========================================================================
    // Functions - lookup status display
    // ========================================================================

    /**
     * Put the status panel into the default state with any previous service
     * status elements removed.
     */
    function initializeStatusPanel() {
        serviceStatuses().removeClass('invisible');
        clearServiceStatuses();
        statusNotice('Starting...');
    }

    /**
     * makeStatusPanel
     *
     * @returns {jQuery}
     */
    function makeStatusPanel() {
        let $container = $('<div>').addClass(STATUS_PANEL_CLASS);
        makeServiceStatuses().appendTo($container);
        makeStatusNotice().appendTo($container);
        return $container;
    }

    /**
     * makeStatusNotice
     *
     * @returns {jQuery}
     */
    function makeStatusNotice() {
        return $('<div>').addClass(NOTICE_CLASS);
    }

    /**
     * makeServiceStatuses
     *
     * @returns {jQuery}
     */
    function makeServiceStatuses() {
        return $('<div>').addClass(SERVICES_CLASS);
    }

    /**
     * makeServiceStatus
     *
     * @returns {jQuery}
     */
    function makeServiceStatus(name) {
        const service = name || 'unknown';
        const classes = `service ${service}`;
        const label   = camelCase(service);
        return $('<div>').addClass(classes).text(label);
    }

    // ========================================================================
    // Functions - new field values
    // ========================================================================

    /**
     * getFieldValuesEntry
     * 
     * @returns {jQuery}
     */
    function getFieldValuesEntry() {
        $field_values?.removeData(ENTRY_ITEM_DATA);
        return $field_values;
    }

    /**
     * setFieldValuesEntry
     * 
     * @param {jQuery} $entry
     *
     * @returns {jQuery}
     */
    function setFieldValuesEntry($entry) {
        return $field_values = $entry;
    }

    /**
     * The user commits to the new field values.
     *
     * @param {jQuery.Event|Event} event
     */
    function commitFieldValuesEntry(event) {
        event.stopPropagation();
        event.preventDefault();
        let current    = getFieldValuesData();
        let new_values = entryValues(getFieldValuesEntry());
        if (isPresent(current)) {
            new_values = $.extend(true, current, new_values);
        }
        setFieldValuesData(new_values);
    }

    // ========================================================================
    // Functions - new field values
    // ========================================================================

    /**
     * makeCommitFieldValues
     *
     * @param {string} [label]
     *
     * @returns {jQuery}
     */
    function makeCommitFieldValues(label) {
        let $button = $('<button>').addClass('commit').attr('type', 'submit');
        $button.text(label || 'Commit'); // TODO: I18n
        handleClickAndKeypress($button, commitFieldValuesEntry);
        return $button;
    }

    // ========================================================================
    // Functions - entry selection
    // ========================================================================

    /**
     * getSelectedEntry
     *
     * @returns {jQuery}
     */
    function getSelectedEntry() {
        return $selected_entry ||=
            entryRadioButtons().filter(':checked').parent();
    }

    /**
     * setSelectedEntry
     *
     * @param {jQuery} $entry
     *
     * @returns {jQuery}
     */
    function setSelectedEntry($entry) {
        return $selected_entry = $entry;
    }

    /**
     * The user selects a lookup result entry as the basis for the new field
     * values for the originating submission entry.
     *
     * @param {jQuery.Event|Event} event
     */
    function selectEntry(event) {
        let $target = $(event.target);
        if ($target.is(':checked')) {
            let $entry = setSelectedEntry($target.parent());
            fillEntry(getFieldValuesEntry(), entryValues($entry));
            entryRadioButtons().not($target).prop('checked', false);
        }
    }

    // ========================================================================
    // Functions - entry values
    // ========================================================================

    /**
     * Get a copy of the given entry's field values.
     *
     * @param {jQuery} $entry
     *
     * @returns {LookupResponseItem}
     */
    function entryValues($entry) {
        let data = $entry.data(ENTRY_ITEM_DATA);
        data &&= dupObject(data);
        data ||= Object.fromEntries(
            DATA_COLUMNS.map(field => [field, getColumnValue($entry, field)])
        );
        return data;
    }

    /**
     * getColumnValue
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
     * setColumnValue
     *
     * @param {jQuery} $entry
     * @param {string} field
     * @param {*}      field_value
     */
    function setColumnValue($entry, field, field_value) {
        /** @type {jQuery} */
        let $col  = $entry.children(`[data-field="${field}"]`);
        let value = field_value;
        if ($col.is('textarea')) {
            $col.val(Array.isArray(value) ? value.join("\n") : value);
        } else if (isPresent($col)) {
            let $text = $col.children('.text');
            if (isMissing($text)) {
                $text = $('<div>').addClass('text').appendTo($col);
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
     * entriesDisplay
     *
     * @returns {jQuery}
     */
    function entriesDisplay() {
        $entries_display ||= presence($root.find(ENTRIES));
        $entries_display ||= makeEntriesDisplay().insertAfter(statusPanel());
        return $entries_display;
    }

    /**
     * Container for all generated lookup entries.
     *
     * @returns {jQuery}
     */
    function entriesList() {
        return $entries_list ||= entriesDisplay().find('.list');
    }

    /**
     * All entry selection radio buttons.
     *
     * @returns {jQuery}
     */
    function entryRadioButtons() {
        return $entry_radio_buttons ||= entriesList().find('.selection');
    }

    /**
     * Present a candidate lookup result entry.
     *
     * @param {LookupResponse} message
     */
    function updateEntries(message) {
        const func = 'updateEntries';
        const data = message.data;

        if (message.status === 'STARTING') {
            console.log(`${func}: ignoring STARTING message`);

        } else if (isMissing(data)) {
            console.warn(`${func}: missing message.data`);

        } else if (isPresent(data.blend)) {
            addEntry(data.blend, 'blend');

        } else if (data.blend) {
            console.log(`${func}: ignoring empty message.data.blend`);

        } else if (isMissing(data.items)) {
            console.warn(`${func}: empty message.data.items`);

        } else {
            const request = getRequestData();
            const req_ids = presence(request.ids);
            const service = camelCase(message.service);
            $.each(data.items, function(id, items) {
                if (!req_ids || req_ids.includes(id)) {
                    items.forEach(item => addEntry(item, service));
                }
            });
        }
    }

    /**
     * Include a candidate lookup result entry.
     *
     * @param {LookupResponseItem} item
     * @param {string}             [label]
     *
     * @returns {jQuery}
     */
    function addEntry(item, label) {
        let $list  = entriesList();
        const row  = $list.children().length;
        let $entry = makeEntry(row, label);
        fillEntry($entry, item);
        $entry.data(ENTRY_ITEM_DATA, dupObject(item));
        return $entry.appendTo($list);
    }

    /**
     * Fill *$entry* data fields from *item*.
     *
     * @param {jQuery}             $entry
     * @param {LookupResponseItem} item
     *
     * @returns {jQuery}
     */
    function fillEntry($entry, item) {
        $.each(item, (field, value) => setColumnValue($entry, field, value));
        return $entry;
    }

    /**
     * Remove all entries (not including the head and field values rows).
     *
     * If $entries_list does not exist, this returns immediately.
     */
    function resetEntries() {
        if ($entries_list) {
            /** @type {jQuery} */
            let $rows = $entries_list.children();
            $rows.not(`${HEAD_ENTRY}, ${FIELD_VALUES}`).remove();
            $rows.filter(FIELD_VALUES).find('textarea').val('');
            $entry_radio_buttons = $selected_entry = null;
        }
    }

    // ========================================================================
    // Functions - entry display
    // ========================================================================

    /**
     * makeEntriesDisplay
     *
     * @returns {jQuery}
     */
    function makeEntriesDisplay() {
        let $container = $('<div>').addClass(ENTRIES_CLASS);
        makeEntriesList().appendTo($container);
        return $container;
    }

    /**
     * makeEntriesList
     *
     * @returns {jQuery}
     */
    function makeEntriesList() {
        let cols  = ALL_COLUMNS.length;
        let row   = 0;
        let $list = $('<div>').addClass(`list columns-${cols}`);
        makeHeadEntry(row++).appendTo($list);
        makeFieldValuesEntry(row++).appendTo($list);
        return $list;
    }

    /**
     * Generate a lookup results entries heading row.
     *
     * @param {number} row
     *
     * @returns {jQuery}
     */
    function makeHeadEntry(row) {
        let $columns = ALL_COLUMNS.map(label => makeHeadColumn(label));
        return makeEntry(row, $columns).addClass(HEAD_ENTRY_CLASS);
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
        let $columns = [$('<div>'), $('<div>').addClass('tag')];
        $columns.push(...DATA_COLUMNS.map(field => makeInputColumn(field)));
        let $entry   = makeEntry(row, $columns).addClass(FIELD_VALUES_CLASS);
        let $col_1   = $entry.find('.tag');
        makeCommitFieldValues().appendTo($col_1);
        return setFieldValuesEntry($entry);
    }

    /**
     * Generate a new row to be included in list of lookup results entries.
     *
     * @param {number}          row
     * @param {string|jQuery[]} [tag]
     *
     * @returns {jQuery}
     */
    function makeEntry(row, tag) {
        let $columns;
        if (Array.isArray(tag)) {
            $columns = tag;
        } else {
            $columns = [makeSelectColumn(), makeTagColumn(tag)];
            $columns.push(...DATA_COLUMNS.map(field => makeDataColumn(field)));
        }
        let $entry = $('<div>').addClass(`row row-${row}`);
        let col    = 0;
        $columns.forEach(
            $col => $col.addClass(`row-${row} col-${col++}`).appendTo($entry)
        );
        return $entry;
    }

    /**
     * makeInputColumn
     *
     * @param {string} field
     * @param {string} [value]
     *
     * @returns {jQuery}
     */
    function makeInputColumn(field, value) {
        let $column = $('<textarea>').attr('data-field', field);
        // noinspection JSUnresolvedFunction
        $column.val(Array.isArray(value) ? value.join("\n") : value);
        return $column;
    }

    /**
     * makeSelectColumn
     *
     * @param {boolean} [active]
     *
     * @returns {jQuery}
     */
    function makeSelectColumn(active) {
        let $radio = $('<input>').addClass('selection').attr('type', 'radio');
        $radio.prop('checked', (isDefined(active) ? active : false));
        handleEvent($radio, 'change', selectEntry);
        return $radio;
    }

    /**
     * makeHeadColumn
     *
     * @param {string} field
     *
     * @returns {jQuery}
     */
    function makeHeadColumn(field) {
        const value = ENTRY_TABLE[field]?.label || field;
        return makeBlankColumn(value);
    }

    /**
     * makeTagColumn
     *
     * @param {string} tag
     *
     * @returns {jQuery}
     */
    function makeTagColumn(tag) {
        const value = tag || 'Result'; // TODO: I18n
        return makeBlankColumn(value).addClass('tag');
    }

    /**
     * makeDataColumn
     *
     * @param {string} field
     * @param {string} [value]
     *
     * @returns {jQuery}
     */
    function makeDataColumn(field, value) {
        return makeBlankColumn(value).attr('data-field', field);
    }

    /**
     * makeBlankColumn
     *
     * @param {string} [label]
     *
     * @returns {jQuery}
     */
    function makeBlankColumn(label) {
        let $column  = $('<div>');
        let $content = $('<span class="text">').text(label || '');
        return $column.append($content);
    }

    // ========================================================================
    // Functions - search terms input
    // ========================================================================

    /**
     * Get the terms to lookup.
     *
     * @returns {string|undefined}
     */
    function getSearchTerms() {
        return $input.val();
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
        let chars  = (separator || getSeparators()).replaceAll('\\s', ' ');
        let sep    = chars[0];
        let parts  = arrayWrap(terms);
        let $query = queryTerms();
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
        return $input.val(parts.join(sep));
    }

    /**
     * Extract the lookup request from the event target.
     *
     * @param {jQuery.Event|Event} [event]
     */
    function updateSearchTerms(event) {
        let $data_src = event ? $(event.target) : $popup_button;
        const data    = $data_src.data(SEARCH_TERMS_DATA);
        const request = setRequestData(data);
        setSearchTerms(request.terms);
    }

    // ========================================================================
    // Functions - separator selection
    // ========================================================================

    /**
     * Return the currently-selected separator character(s).
     *
     * @returns {string}
     */
    function getSeparators() {
        const key = $separator.filter(':checked').val();
        return SEPARATORS[key] || SEPARATORS[DEF_SEPARATORS_KEY];
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
            $.each(SEPARATORS, function(key, characters) {
                if (new_characters !== characters) { return true } // continue
                $separator.filter(`[value="${key}"]`).trigger('click');
                return false; // break
            });
        }
        return new_characters;
    }

    // ========================================================================
    // Functions - message display
    // ========================================================================

    /**
     * Remove result display contents.
     */
    function clearResultDisplay() {
        $results.text('');
    }

    /**
     * Remove error display contents.
     */
    function clearErrorDisplay() {
        $errors.text('');
    }

    /**
     * Remove diagnostic display contents.
     */
    function clearDiagnosticDisplay() {
        $diagnostics.text('');
    }

    /**
     * Update the main display element.
     *
     * @param {LookupResponse|LookupResponseObject} message
     */
    function updateResultDisplay(message) {
        const data = message?.object || message || {};
        updateDisplay($results, data);
    }

    /**
     * Update the error log element.
     *
     * @param {object} data
     */
    function updateErrorDisplay(data) {
        updateDisplay($errors, data);
    }

    /**
     * Update the diagnostics display element.
     *
     * @param {object} data
     */
    function updateDiagnosticDisplay(data) {
        updateDisplay($diagnostics, data, '');
    }

    /**
     * Update the contents of a display element.
     *
     * @param {jQuery} $element
     * @param {object} data
     * @param {string} gap
     */
    function updateDisplay($element, data, gap = "\n") {
        let added = formatResponseData(data);
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

    // ========================================================================
    // Functions - formatting
    // ========================================================================

    const DEF_INDENT     = 2;
    const DEF_INLINE_MAX = 80;

    /**
     * Render a data object as a sequence of lines.
     *
     * @param {object} data
     * @param {number} indent         Indentation of nested object.
     *
     * @returns {string}
     */
    function formatResponseData(data, indent = DEF_INDENT) {
        const item = alignKeys(data);
        const json = JSON.stringify(item, stringifyReplacer, indent);
        return postProcess(json);
    }

    /**
     * Recursively regenerate an item so that its object keys are replaced with
     * names appended with zero or more spaces in order to make each key the
     * same length.
     *
     * @param {object|array|*} item
     *
     * @returns {object|array|*}
     */
    function alignKeys(item) {
        if (typeof item !== 'object') {
            return item;
        } else if (Array.isArray(item)) {
            return item.map(element => alignKeys(element));
        } else {
            const max_width = maxSize(Object.keys(item));
            let result = {};
            $.each(item, function(k, v) {
                const space = Math.max(0, (max_width - k.length));
                const key   = '' + k + ' '.repeat(space);
                result[key] = alignKeys(v);
            });
            return result;
        }
    }

    /**
     * Replacer function for `JSON.stringify`.
     *
     * @param {*} _this
     * @param {*} item
     *
     * @returns {string|*}
     */
    function stringifyReplacer(_this, item) {
        const type = typeof(item);
        if (type === 'undefined')      { return '(undefined)'; }
        else if (item === null)        { return '(null)'; }
        else if (item instanceof Date) { return asDateTime(item); }
        else if (isEmpty(item))        { return item; }
        else if (type === 'object')    { return possiblyInlined(item); }
        return item;
    }

    /**
     * Render a data object as a sequence of lines.
     *
     * @param {object} obj
     * @param {number} threshold      Threshold for rendering a nested object
     *                                  on a single line.
     *
     * @returns {string|*}
     */
    function possiblyInlined(obj, threshold = DEF_INLINE_MAX) {
        let json =
            postProcess(JSON.stringify(obj, null, ' '))
                .replace(/\[\s+/g, '[')
                .replace(/\s+]/g,  ']')
                .replace(/{\s*/g,  '{ ')
                .replace(/\s*}/g,  ' }')
                .replace(/\s+/g,   ' ');
        return (json.length <= threshold) ? json : obj;
    }

    /**
     * Make the result of `JSON.stringify` look less like JSON.
     *
     * @param {string} item
     *
     * @returns {string}
     */
    function postProcess(item) {
        // noinspection RegExpRedundantEscape
        return item
            .replace(/\\"/g, '"')
            .replace(/"(\(\w+\))"/g, '$1')
            .replace(/"(\{.+\})"/gm, '$1')
            .replace(/"(\[.+\])"/gm, '$1')
            .replace(/^( *)"(\w+)(\s*)":/gm,  '$1$2:$3')
            .replace(/^( *)"(\S+?)(\s+)":/gm, '$1"$2":');
    }

}
