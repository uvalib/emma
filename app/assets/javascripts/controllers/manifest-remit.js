// app/assets/javascripts/controllers/manifest-remit.js


import { AppDebug }                              from '../application/debug';
import { appSetup }                              from '../application/setup';
import { arrayWrap, removeFrom }                 from '../shared/arrays';
import { BaseClass }                             from '../shared/base-class';
import { selector, toggleHidden }                from '../shared/css';
import { handleClickAndKeypress, handleEvent }   from '../shared/events';
import { flashError, flashMessage }              from '../shared/flash';
import { selfOrDescendents, selfOrParent }       from '../shared/html';
import { compact, fromJSON, isObject, toObject } from '../shared/objects';
import { SubmitModal }                           from '../shared/submit-modal';
import {
    isDefined,
    isEmpty,
    isMissing,
    isPresent,
    notDefined,
} from '../shared/definitions';
import {
    DISABLED_MARKER,
    MANIFEST_ATTR,
    ITEM_ATTR,
    attribute,
    buttonFor,
    enableButton,
    initializeButtonSet,
} from '../shared/manifests';
import {
    SubmitStepResponse,
} from '../shared/submit-response';


const MODULE = 'ManifestRemit';
const DEBUG  = true;

AppDebug.file('controllers/manifest-remit', MODULE, DEBUG);

// noinspection SpellCheckingInspection, FunctionTooLongJS
appSetup(MODULE, function() {

    /**
     * Manifest creation page.
     *
     * @type {jQuery}
     */
    const $body = $('body.manifest:not(.select)').filter('.remit');

    // Only perform these actions on the appropriate pages.
    if (isMissing($body)) {
        return;
    }

    // ========================================================================
    // Constants
    // ========================================================================

    const SUBMISSION_TRAY_CLASS     = 'submission-controls';
    const START_BUTTON_CLASS        = 'start-button';
    const STOP_BUTTON_CLASS         = 'stop-button';
    const PAUSE_BUTTON_CLASS        = 'pause-button';
    const RESUME_BUTTON_CLASS       = 'resume-button';
    const MONITOR_BUTTON_CLASS      = 'monitor-button';

    const AUXILIARY_TRAY_CLASS      = 'auxiliary-buttons';
    const REMOTE_FILE_CLASS         = 'remote-file';
    const LOCAL_FILE_CLASS          = 'local-file';
    const FILE_BUTTON_CLASS         = 'file-button';
    const BEST_CHOICE_MARKER        = 'best-choice';

    const SUBMISSION_COUNTS_CLASS   = 'submission-counts'
    const TOTAL_COUNT_CLASS         = 'total';
    const READY_COUNT_CLASS         = 'ready';
    const TRANSMITTING_COUNT_CLASS  = 'transmitting';
    const FAILED_COUNT_CLASS        = 'failed';
    const SUCCEEDED_COUNT_CLASS     = 'succeeded';

    const SUBMISSION_LIST_CLASS     = 'submission-status-list';
    const SUBMISSION_CLASS          = 'submission-status';
    const CONTROLS_CLASS            = 'controls';
  //const CHECKBOX_CLASS            = 'checkbox';
    const DB_STATUS_CLASS           = 'db-status';
    const FILE_STATUS_CLASS         = 'file-status';
    const UPLOAD_STATUS_CLASS       = 'upload-status';
    const INDEX_STATUS_CLASS        = 'index-status';
    const ACTIVE_MARKER             = 'active';
    const NOT_STARTED_MARKER        = 'not-started';
    const UNSAVED_MARKER            = 'unsaved';
    const FILE_NEEDED_MARKER        = 'file-needed';
    const FILE_MISSING_MARKER       = 'file-missing';
    const DATA_MISSING_MARKER       = 'data-missing';
    const BLOCKED_MARKER            = 'blocked';
    const FAILED_MARKER             = 'failed';
    const SUCCEEDED_MARKER          = 'succeeded';
    const DONE_MARKER               = 'done';

    const SUBMISSION_TRAY       = selector(SUBMISSION_TRAY_CLASS);
    const START_BUTTON          = selector(START_BUTTON_CLASS);
    const STOP_BUTTON           = selector(STOP_BUTTON_CLASS);
    const PAUSE_BUTTON          = selector(PAUSE_BUTTON_CLASS);
    const RESUME_BUTTON         = selector(RESUME_BUTTON_CLASS);
    const MONITOR_BUTTON        = selector(MONITOR_BUTTON_CLASS);

    const AUXILIARY_TRAY        = selector(AUXILIARY_TRAY_CLASS);
    const REMOTE_FILE           = selector(REMOTE_FILE_CLASS);
    const LOCAL_FILE            = selector(LOCAL_FILE_CLASS);
    const FILE_BUTTON           = selector(FILE_BUTTON_CLASS);
  //const BEST_CHOICE           = selector(BEST_CHOICE_MARKER);

    const SUBMISSION_COUNTS     = selector(SUBMISSION_COUNTS_CLASS);
    const TOTAL_COUNT           = selector(TOTAL_COUNT_CLASS);
    const READY_COUNT           = selector(READY_COUNT_CLASS);
    const TRANSMITTING_COUNT    = selector(TRANSMITTING_COUNT_CLASS);
    const FAILED_COUNT          = selector(FAILED_COUNT_CLASS);
    const SUCCEEDED_COUNT       = selector(SUCCEEDED_COUNT_CLASS);

    const SUBMISSION_LIST       = selector(SUBMISSION_LIST_CLASS);
    const SUBMISSION_HEAD       = selector(SUBMISSION_CLASS, '.head');
    const SUBMISSION            = selector(SUBMISSION_CLASS) + ':not(.head)';
    const CONTROLS              = selector(CONTROLS_CLASS);
    const CHECKBOX              = 'input[type="checkbox"]';
    const DB_STATUS             = selector(DB_STATUS_CLASS);
    const FILE_STATUS           = selector(FILE_STATUS_CLASS);
    const UPLOAD_STATUS         = selector(UPLOAD_STATUS_CLASS);
    const INDEX_STATUS          = selector(INDEX_STATUS_CLASS);
    const ACTIVE                = selector(ACTIVE_MARKER);
    const NOT_STARTED           = selector(NOT_STARTED_MARKER);
    const UNSAVED               = selector(UNSAVED_MARKER);
    const FILE_NEEDED           = selector(FILE_NEEDED_MARKER);
    const FILE_MISSING          = selector(FILE_MISSING_MARKER);
    const FILE_PROBLEMATIC      = `${FILE_MISSING}, ${FILE_NEEDED}`;
    const DATA_MISSING          = selector(DATA_MISSING_MARKER);
    const DATA_PROBLEMATIC      = `${DATA_MISSING}, ${UNSAVED}`;
    const PROBLEMATIC           = `${FILE_PROBLEMATIC}, ${DATA_PROBLEMATIC}`;
    const BLOCKED               = selector(BLOCKED_MARKER);
    const FAILED                = selector(FAILED_MARKER);
    const SUCCEEDED             = selector(SUCCEEDED_MARKER);
    const DONE                  = selector(DONE_MARKER);

    // ========================================================================
    // Classes
    // ========================================================================

    /**
     * Base class for managing counter value elements.
     */
    class Counter extends BaseClass {

        static CLASS_NAME = 'BaseClass';

        /**
         * Default console debug output setting (overridden per class).
         *
         * @type {boolean}
         */
        static DEBUGGING = false;

        // ====================================================================
        // Class fields
        // ====================================================================

        /**
         * All Counter subclass instances.
         *
         * @type {Counter[]}
         * @protected
         */
        static _all = [];

        // ====================================================================
        // Fields
        // ====================================================================

        /**
         * The counter display element.
         *
         * @type {jQuery|undefined}
         */
        $element;

        /**
         * The counter value display element.
         *
         * @type {jQuery|undefined}
         */
        $target;

        /**
         * The current counter value.
         *
         * @type {number}
         * @protected
         */
        _value = 0;

        // ====================================================================
        // Constructor
        // ====================================================================

        constructor(selector, initial) {
            super();
            let sel, val;
            if (typeof selector === 'number') {
                [sel, val] = [undefined, selector.toString()];
            } else if (isDefined(initial)) {
                [sel, val] = [selector,  initial.toString()];
            } else {
                [sel, val] = [selector,  undefined];
            }
            this.$element = sel && $submit_counts.find(sel);
            this.$target  = sel && selfOrDescendents(this.$element, '.value');
            this.value    = val || this.$target?.text();
            this.constructor._all.push(this);
        }

        // ====================================================================
        // Properties
        // ====================================================================

        get value()  { return this._value }
        set value(v) { this.update(v) }

        // ====================================================================
        // Methods
        // ====================================================================

        clear()      { return this.update(0) }
        reset()      { return this.update(this.constructor.current) }
        increment(v) { return this.update(this.value + Number(v || 0)) }
        decrement(v) { return this.update(this.value - Number(v || 0)) }

        update(v) {
            this._value = Number(v || 0);
            this.$target?.text(this._value);
            return this._value;
        }

        // ====================================================================
        // Class properties
        // ====================================================================

        static get current() { return this.$items.length }
        static get $items()  { return $(null) }

        // ====================================================================
        // Class methods
        // ====================================================================

        static clearAll() { this._all.forEach(instance => instance.clear()) }
        static resetAll() { this._all.forEach(instance => instance.reset()) }
    }

    /**
     * The number of manifest items in the manifest.
     */
    class TotalCounter extends Counter {
        static CLASS_NAME = 'TotalCounter';
        constructor()       { super(TOTAL_COUNT) }
        static get $items() { return allItems() }
    }

    /**
     * The number of manifest items ready for submission.
     */
    class ReadyCounter extends Counter {
        static CLASS_NAME = 'ReadyCounter';
        constructor()       { super(READY_COUNT) }
        static get $items() { return itemsReady() }
    }

    /**
     * The number of manifest items currently being submitted.
     */
    class TransmitCounter extends Counter {
        static CLASS_NAME = 'TransmitCounter';
        constructor()       { super(TRANSMITTING_COUNT) }
        static get $items() { return itemsTransmitting() }
    }

    /**
     * The number of failed manifest item submissions.
     */
    class FailedCounter extends Counter {
        static CLASS_NAME = 'FailedCounter';
        constructor()       { super(FAILED_COUNT) }
        static get $items() { return itemsFailed() }
    }

    /**
     * The number of successfully submitted manifest items.
     */
    class SucceededCounter extends Counter {
        static CLASS_NAME = 'SucceededCounter';
        constructor()       { super(SUCCEEDED_COUNT) }
        static get $items() { return itemsSucceeded() }
    }

    // ========================================================================
    // Variables - counts
    // ========================================================================

    const $submit_counts = $(SUBMISSION_COUNTS);

    // @see "en.emma.bulk.submit.counts"
    const counter = {
        total:        new TotalCounter(),
        ready:        new ReadyCounter(),
        transmitting: new TransmitCounter(),
        failed:       new FailedCounter(),
        succeeded:    new SucceededCounter(),
    };

    // ========================================================================
    // Variables - buttons
    // ========================================================================

    /**
     * Manifest submission controls.
     *
     * @type {jQuery}
     */
    const $submit_tray = $(SUBMISSION_TRAY);
    const $start       = $submit_tray.find(START_BUTTON);
    const $stop        = $submit_tray.find(STOP_BUTTON);
    const $pause       = $submit_tray.find(PAUSE_BUTTON);
    const $resume      = $submit_tray.find(RESUME_BUTTON);
    const $monitor     = $submit_tray.find(MONITOR_BUTTON);

    /**
     * Table of symbolic names for button elements.
     *
     * @type {Object.<string,jQuery>}
     */
    const SUBMISSION_BUTTONS = {
        start:  $start,
        stop:   $stop,
        pause:  $pause,
        resume: $resume,
    };

    /**
     * Table of button enabling functions.
     *
     * @type {Object.<string,function(enable?: boolean)>}
     */
    const SUBMISSION_ENABLE = toObject(SUBMISSION_BUTTONS,
        name => (v => enableSubmissionButton(name, v))
    );

    // ========================================================================
    // Functions
    // ========================================================================

    /**
     * Initialize the Manifest submission controls.
     */
    function initializeSubmissionForm() {
        _debug('initializeSubmissionForm');
        initializeSubmissionMonitor();
        initializeSubmissionButtons();
        initializeItems();
        initializeLocalFilesResolution();
        initializeRemoteFilesResolution();
        updateSubmitReady();
    }

    /**
     * A submission entry correlated with a ManifestItem.
     *
     * @param {Selector} item
     *
     * @returns {jQuery}
     */
    function itemRow(item) {
        return selfOrParent(item, SUBMISSION);
    }

    // ========================================================================
    // Functions - buttons
    // ========================================================================

    /**
     * initializeSubmissionButtons
     */
    function initializeSubmissionButtons() {
        const func = 'initializeSubmissionButtons'; //_debug(func);
        initializeButtonSet(SUBMISSION_BUTTONS, func);
        submissionsActive(false);
    }

    /**
     * Change submission button state.
     *
     * @param {string}           type       A {@link SUBMISSION_BUTTONS} key.
     * @param {boolean}          [enable]
     * @param {ActionProperties} [prop]     Overrides configured properties.
     *
     * @returns {jQuery|undefined}
     */
    function enableSubmissionButton(type, enable, prop) {
        const func    = 'enableSubmissionButton';
        _debug(`${func}: type = "${type}"; enable = "${enable}"`);
        const $button = buttonFor(type, SUBMISSION_BUTTONS, func);
        return enableButton($button, enable, type, prop);
    }

    /**
     * Submit Manifest items.
     *
     * @param {jQuery.Event|UIEvent} [event]
     */
    function onSubmissionStart(event) {
        const func = 'onSubmissionStart'; _debug(`${func}: event =`, event);
        const fail = 'Submission failed'; // TODO: I18n
        if (submissionsActive()) {
            _error(`${fail} - already submitting`);
        } else {
            const action = startSubmissions();
            submissionRequest(action, func, fail);
        }
    }

    /**
     * Terminate the current Manifest submission.
     *
     * @param {jQuery.Event|UIEvent} event
     */
    function onSubmissionStop(event) {
        const func = 'onSubmissionStop'; _debug(`${func}: event =`, event);
        const fail = 'Cancel failed'; // TODO: I18n
        if (!submissionsActive()) {
            _error(`${fail} - not submitting`);
        } else {
            const action = stopSubmissions();
            submissionRequest(action, func, fail);
        }
    }

    /**
     * Pause the current Manifest submission.
     *
     * @param {jQuery.Event|UIEvent} event
     */
    function onSubmissionPause(event) {
        const func = 'onSubmissionPause'; _debug(`${func}: event =`, event);
        const fail = 'Pause failed'; // TODO: I18n
        if (!submissionsActive()) {
            _error(`${fail} - not submitting`);
        } else if (submissionsPaused()) {
            _error(`${fail} - already paused`);
        } else {
            const action = pauseSubmissions();
            submissionRequest(action, func, fail);
        }
    }

    /**
     * Resume the currently-paused Manifest submission.
     *
     * @param {jQuery.Event|UIEvent} event
     */
    function onSubmissionResume(event) {
        const func = 'onSubmissionResume'; _debug(`${func}: event =`, event);
        const fail = 'Resume failed'; // TODO: I18n
        if (!submissionsActive()) {
            _error(`${fail} - not submitting`);
        } else if (!submissionsPaused()) {
            _error(`${fail} - not paused`);
        } else {
            const action = resumeSubmissions();
            submissionRequest(action, func, fail);
        }
    }

    /**
     * Perform a Manifest submission action on the server.
     *
     * @param {string} action
     * @param {string} [caller]
     * @param {string} [fail]
     */
    function submissionRequest(action, caller, fail) {
        const func = caller || 'submissionRequest';
        _debug(`${func}: ${action}`);
        if (!submissionMonitor().command(action)) {
            const tag  = fail || `${action} failed`;
            const note = 'Refresh this page to re-authenticate.';
            flashError(`${tag}: ${note}`);
        }
    }

    // ========================================================================
    // Functions - auxiliary controls
    // ========================================================================

    const $auxiliary_tray = $(AUXILIARY_TRAY);

    const $remote_prompt  = $auxiliary_tray.find(REMOTE_FILE);
    const $remote_button  = $remote_prompt.filter(FILE_BUTTON);
    const $remote_input   = $remote_button.find('input[type="file"]');

    const $local_prompt   = $auxiliary_tray.find(LOCAL_FILE);
    const $local_button   = $local_prompt.filter(FILE_BUTTON);
    const $local_input    = $local_button.find('input[type="file"]');

    const file_references = { local: [], remote: [] };
    const files_remaining = { local: [], remote: [] };

    /**
     * Submit button tooltip override. # TODO: I18n
     *
     * @type {string}
     */
    const SUBMISSION_BLOCKED_TOOLTIP =
        'Files must be resolved before the submission process can begin';
    const NOTHING_TO_SUBMIT_TOOLTIP =
        'None of the items in the manifest have been completed and saved';

    /**
     * Change whether the Submit button is enabled based on conditions.
     *
     * If not ready, a custom tooltip is provided to indicate the reason.
     */
    function updateSubmitReady() {
        _debug('updateSubmitReady');

        const remote_needed = isPresent(files_remaining.remote);
        const local_needed  = isPresent(files_remaining.local);

        showRemoteFilesPrompt(remote_needed, remote_needed);
        showLocalFilesPrompt(local_needed, !remote_needed);

        let blocked;
        const prop = {};
        if ((blocked = remote_needed || local_needed)) {
            prop.tooltip = SUBMISSION_BLOCKED_TOOLTIP;
        } else if ((blocked = !counter.ready.reset())) {
            prop.tooltip = NOTHING_TO_SUBMIT_TOOLTIP;
        }
        enableSubmissionButton('start', !blocked, prop);
    }

    /**
     * showRemoteFilesPrompt
     *
     * @param {boolean} visible
     * @param {boolean} first
     */
    function showRemoteFilesPrompt(visible, first) {
        //_debug('showRemoteFilesPrompt:', visible, first);
        if (visible) {
            $remote_button.toggleClass(BEST_CHOICE_MARKER, first);
            $remote_button.toggleClass(DISABLED_MARKER, !first);
            $remote_input.prop('disabled', !first);
        }
        toggleHidden($remote_prompt, !visible);
    }

    /**
     * showLocalFilesPrompt
     *
     * @param {boolean} visible
     * @param {boolean} first
     */
    function showLocalFilesPrompt(visible, first) {
        //_debug('showLocalFilesPrompt:', visible, first);
        if (visible) {
            $local_button.toggleClass(BEST_CHOICE_MARKER, first);
            $local_button.toggleClass(DISABLED_MARKER, !first);
            $local_input.prop('disabled', !first);
        }
        toggleHidden($local_prompt, !visible);
    }

    // ========================================================================
    // Functions - submissions
    // ========================================================================

    /**
     * Begin submitting all items marked for submission.
     *
     * @returns {string}              Submission action.
     */
    function startSubmissions() {
        _debug('START SUBMISSIONS');
        if (isMissing(itemsChecked())) {
            itemsReady().each((_, item) => selectItem(item));
            updateGroupSelect();
        }
        setSubmissionRequest();
        submissionsActive(true);
        return 'start';
    }

    /**
     * Terminate the current round of submissions.
     *
     * @returns {string}              Submission action.
     */
    function stopSubmissions() {
        _debug('STOP SUBMISSIONS');
        submissionsActive(false);
        return 'stop';
    }

    /**
     * Pause the current round of submissions.
     *
     * @returns {string}              Submission action.
     */
    function pauseSubmissions() {
        _debug('PAUSE SUBMISSIONS');
        submissionsPaused(true);
        return 'pause';
    }

    /**
     * Un-pause the current round of submissions.
     *
     * @returns {string}              Submission action.
     */
    function resumeSubmissions() {
        _debug('RESUME SUBMISSIONS');
        submissionsPaused(false);
        return 'resume';
    }

    let started = false;
    let paused  = false;

    /**
     * submissionsActive
     *
     * @param {boolean} [now]
     *
     * @returns {boolean}
     */
    function submissionsActive(now) {
        if (isDefined(now)) {
            started = !!now;
            _debug('SUBMISSION', (started ? 'STARTED' : 'STOPPED'));
            SUBMISSION_ENABLE.start(!started && !!itemsReady().length);
            SUBMISSION_ENABLE.stop(started);
            SUBMISSION_ENABLE.pause(started);
            SUBMISSION_ENABLE.resume(false);
            if (!started) {
                const no_submission = $stop.attr('title');
                $pause.attr( 'title', no_submission);
                $resume.attr('title', no_submission);
            }
            paused = false;
        }
        return started;
    }

    /**
     * submissionsPaused
     *
     * @param {boolean} [now]
     *
     * @returns {boolean}
     */
    function submissionsPaused(now) {
        if (isDefined(now)) {
            paused = !!now;
            _debug('SUBMISSION', (paused ? 'PAUSED' : 'RESUMED'));
            SUBMISSION_ENABLE.pause(!paused);
            SUBMISSION_ENABLE.resume(paused);
        }
        return paused;
    }

    // ========================================================================
    // Functions - submission items
    // ========================================================================

    const CANT_SUBMIT = `${PROBLEMATIC}, ${BLOCKED}`;

    const NOT_READY_VALUES = {
        [DB_STATUS]:     `${CANT_SUBMIT}, ${FAILED}`,
        [FILE_STATUS]:   `${CANT_SUBMIT}, ${FAILED}`,
        [UPLOAD_STATUS]: `${CANT_SUBMIT}`,
        [INDEX_STATUS]:  `${CANT_SUBMIT}, ${SUCCEEDED}, ${DONE}`,
    };

    const STATUS_SELECTORS = Object.keys(NOT_READY_VALUES);
    const STATUS_TYPES     = STATUS_SELECTORS.map(s => s.replace(/^\./, ''));

    const FILE_NAME_ATTR   = 'data-file-name';
    const FILE_URL_ATTR    = 'data-file-url';

    const $item_container  = $(SUBMISSION_LIST);
    const $items           = $item_container.find(SUBMISSION);

    /**
     * All item rows.
     *
     * @returns {jQuery}
     */
    function allItems() {
        return $items;
    }

    /**
     * initializeItems
     */
    function initializeItems() {
        _debug('initializeItems');
        let changed = false;
        const local = [], remote = [];
        allItems().each((_, item) => {
            const $item = $(item);
            STATUS_SELECTORS.forEach(status => {
                let name;
                if (status === FILE_NEEDED) {
                    const path = $item.attr(FILE_NAME_ATTR) || '';
                    if ((name = path.split('\\').pop().split('/').pop())) {
                        local.push(name);
                    } else if ((name = $item.attr(FILE_URL_ATTR))) {
                        remote.push(name);
                    }
                }
                initializeStatusFor($item, status, name);
            });
            changed = updateItemSelect($item) || changed;
        });
        file_references.local  = [...local];
        files_remaining.local  = [...local];
        file_references.remote = [...remote];
        files_remaining.remote = [...remote];
        _debug(`INITIAL local_files  =`, file_references.local);
        _debug(`INITIAL remote_files =`, file_references.remote);
    }

    /**
     * Restore the status values of selected items to their original state in
     * preparation for resubmitting.
     */
    function resetItems() {
        _debug('resetItems');
        itemsToTransmit().each((_, item) => {
            const $item = $(item);
            STATUS_SELECTORS.forEach(status => resetStatusFor($item, status));
        });
    }

    /**
     * The submission entry associated with the given ManifestItem ID.
     *
     * @param {string, number} id
     *
     * @returns {jQuery}
     */
    function itemFor(id) {
        return allItems().filter(`[${ITEM_ATTR}="${id}"]`);
    }

    function itemsToTransmit() {
        const $selected = itemsSelected();
        return isPresent($selected) ? $selected : allItems();
    }

    function itemsReady() {
        return itemsWhere(isReady);
    }

    function itemsSelected() {
        return itemsWhere(isSelected);
    }

    function itemsChecked() {
        return itemsWhere(isChecked);
    }

    function itemsTransmitting() {
        return itemsWhere(isTransmitting);
    }

    function itemsSucceeded() {
        return itemsWhere(isSucceeded);
    }

    function itemsFailed() {
        return itemsWhere(isFailed);
    }

    function itemsMissingFile(name) {
        return itemsWhere(isMissingFile, name);
    }

    /**
     * Return the matching submission items.
     *
     * @param {function(Selector,...) : boolean} has_condition
     * @param {...}                              [args]
     *
     * @returns {jQuery}
     */
    function itemsWhere(has_condition, ...args) {
        return allItems().filter((_, item) => has_condition(item, ...args));
    }

    function isChecked(item) {
        const $item = itemRow(item);
        const cb    = checkbox($item);
        return !!cb && cb.checked && !cb.indeterminate;
    }

    function isDisabled(item) {
        const $item = itemRow(item);
        const cb    = checkbox($item);
        return !!cb && (cb.disabled || cb.indeterminate);
    }

    function isSelected(item) {
        const $item = itemRow(item);
        const cb    = checkbox($item);
        return !!cb && cb.checked && !cb.disabled && !cb.indeterminate;
    }

    function isReady(item) {
        return !isNotReady(item);
    }

    function isNotReady(item) {
        const $item    = itemRow(item);
        const statuses = Object.entries(NOT_READY_VALUES);
        return statuses.some(([s, invalid]) => $item.find(s).is(invalid));
    }

    function isUnsaved(item) {
        return hasCondition(item, UNSAVED);
    }

    function isBlocked(item) {
        return hasCondition(item, CANT_SUBMIT);
    }

    function isTransmitting(item) {
        return hasCondition(item, ACTIVE);
    }

    function isFailed(item) {
        return hasCondition(item, FAILED);
    }

    function isSucceeded(item) {
        return isExclusively(item, SUCCEEDED);
    }

    function isMissingFile(item, name) {
        const $item   = itemRow(item);
        const $status = $item.find(FILE_STATUS);
        if (!$status.is(FILE_MISSING)) { return false }
        if (!name)                     { return true }
        return $status.find('.name').text() === name;
    }

    function hasCondition(item, matching, selectors = STATUS_SELECTORS) {
        const $item = itemRow(item);
        return selectors.some(status => $item.find(status).is(matching));
    }

    function isExclusively(item, matching, selectors = STATUS_SELECTORS) {
        const $item = itemRow(item);
        return selectors.every(status => $item.find(status).is(matching));
    }

    // ========================================================================
    // Functions - submission selection
    // ========================================================================

    const $head_row        = $item_container.find(SUBMISSION_HEAD);
    const $group_checkbox  = $head_row.find(`${CONTROLS} ${CHECKBOX}`);
    const $item_checkboxes = $items.find(`${CONTROLS} ${CHECKBOX}`);

    /**
     * checkbox
     *
     * @param {Selector} item
     * @param {boolean}  [check]            Check/uncheck
     * @param {boolean}  [indeterminate]
     *
     * @returns {HTMLInputElement|undefined}
     */
    function checkbox(item, check, indeterminate) {
        const cb = selfOrDescendents(item, CHECKBOX)[0];
        if (!cb) { console.warn('checkbox: missing for item', item); return }
        if (isDefined(check))         { cb.checked       = !!check }
        if (isDefined(indeterminate)) { cb.indeterminate = !!indeterminate }
        return cb;
    }

    /**
     * selectItem
     *
     * @param {Selector} item
     * @param {boolean}  [check]            If *false*, uncheck.
     * @param {boolean}  [indeterminate]
     */
    function selectItem(item, check, indeterminate) {
        const $item = itemRow(item);
        if (indeterminate || (notDefined(indeterminate) && isUnsaved($item))) {
            checkbox($item, false, true);
        } else {
            const checked = notDefined(check) || !!check;
            checkbox($item, checked, indeterminate);
        }
    }

    /**
     * deselectItem
     *
     * @param {Selector} item
     * @param {boolean}  [uncheck]          If *false*, check.
     * @param {boolean}  [indeterminate]
     */
    function deselectItem(item, uncheck, indeterminate) {
        const check = isDefined(uncheck) ? !uncheck : undefined;
        selectItem(item, check, indeterminate);
    }

    /**
     * Indicate whether an item can be selected by the user.
     *
     * @param {Selector} item
     *
     * @returns {boolean}
     */
    function isItemSelectable(item) {
        const $item = itemRow(item);
        const cb    = checkbox($item);
        return !!cb && !cb.disabled;
    }

    /**
     * Allow user selection of an item.
     *
     * @param {Selector} item
     * @param {boolean}  [enable]           If *false*, disable.
     * @param {boolean}  [indeterminate]
     *
     * @returns {boolean}                   If selectability changed.
     */
    function enableItemSelect(item, enable, indeterminate) {
        const $item = itemRow(item);
        const cb    = checkbox($item); if (!cb) { return false }
        const ind   =
            isDefined(indeterminate) ? indeterminate : isUnsaved($item);
        const was_enabled = !cb.disabled;
        const now_enabled = ind ? !!enable : (notDefined(enable) || !!enable);
        cb.indeterminate  = ind;
        cb.disabled       = !now_enabled;
        return (was_enabled !== now_enabled);
    }

    /**
     * Prevent user selection of an item.
     *
     * @param {Selector} item
     * @param {boolean}  [disable]          If *false*, enable.
     * @param {boolean}  [indeterminate]
     *
     * @returns {boolean}                   If selectability changed.
     */
    function disableItemSelect(item, disable, indeterminate) {
        const enable = isDefined(disable) ? !disable : undefined;
        return enableItemSelect(item, enable, indeterminate);
    }

    /**
     * Update the selectability of an item.
     *
     * @param {Selector} item
     *
     * @returns {boolean}             If selectability changed.
     */
    function updateItemSelect(item) {
        const $item       = itemRow(item);
        const was_enabled = isItemSelectable($item);
        const old_tooltip = $item.attr('title');
        if (old_tooltip) {
            const tip_data = was_enabled ? 'enabledTip' : 'disabledTip';
            if (notDefined($item.data(tip_data))) {
                $item.data(tip_data, old_tooltip);
            }
        }
        const now_enabled = isReady($item);
        const tip_data    = now_enabled ? 'enabledTip' : 'disabledTip';
        let new_tooltip   = $item.data(tip_data);
        if (notDefined(new_tooltip)) {
            if (!now_enabled) {
                new_tooltip = 'Not selectable until resolved'; // TODO: I18n
                $item.data(tip_data, new_tooltip);
                $item.attr('title', new_tooltip);
            }
        }
        $item.attr('title', (new_tooltip || ''));
        return enableItemSelect($item, now_enabled);
    }

    /**
     * Update the state of the group select checkbox.
     */
    function updateGroupSelect() {
        const func     = 'updateGroupSelect'; _debug(func);
        const group_cb = checkbox($group_checkbox);
        if (!group_cb) { return }
        const count    = $item_checkboxes.filter((_, cb) => cb.checked).length;
        const checked  = !!count;
        group_cb.checked       = checked;
        group_cb.indeterminate = checked && (count < $item_checkboxes.length);
    }

    /**
     * Respond after the group checkbox has been changed.
     *
     * @param {jQuery.Event|Event} event
     */
    function onGroupCheckboxChange(event) {
        const func          = 'onGroupCheckboxChange';
        const group_cb      = event.currentTarget || event.target;
        const $all_items    = $item_checkboxes;
        const checked_items = $all_items.filter((_, cb) => cb.checked).length;
        _debug(`${func}: event =`, event);
        if (group_cb.checked && checked_items) {
            group_cb.indeterminate = (checked_items < $all_items.length);
        } else {
            group_cb.indeterminate = false;
            $all_items.each((_, cb) => selectItem(cb, group_cb.checked));
        }
    }

    /**
     * Respond after an item checkbox has been changed.
     *
     * @param {jQuery.Event|Event} event
     */
    function onItemCheckboxChange(event) {
        _debug('onItemCheckboxChange: event =', event);
        updateGroupSelect();
    }

    // ========================================================================
    // Functions - submission status
    // ========================================================================

    const DEFAULT_LABEL = '???';
    const LABELS_ATTR   = 'data-labels';
    const STATUS_DATA   = 'status';
    const SAVED_DATA    = 'statusInitial';

    /** @type {Object.<string,string>} */
    let status_value_labels;

    /** @type {Set.<string>} */
    let status_values;

    /**
     * The mapping of status class name to label.
     *
     * @returns {Object.<string,string>}
     */
    function statusValueLabels() {
        return status_value_labels ||= getStatusValueLabels();
    }

    /**
     * Extract the mapping of status class name to label.
     *
     * @returns {Object<string,string>}
     */
    function getStatusValueLabels() {
        const func = 'getStatusValueLabels'; //_debug(func);
        const src  = $item_container.attr(LABELS_ATTR);
        let result;
        if (isMissing(src)) {
            console.warn(`${func}: ${LABELS_ATTR}: missing or empty`);
        } else {
            result = fromJSON(src, func);
        }
        // noinspection JSValidateTypes
        return result || {};
    }

    /**
     * statusValues
     *
     * @returns {Set.<string>}
     */
    function statusValues() {
        return status_values ||= new Set(Object.keys(statusValueLabels()));
    }

    /**
     * statusLabelFor
     *
     * @param {Selector} item
     * @param {string}   status       Status type class or selector.
     * @param {string}   [def_label]
     *
     * @returns {string|undefined}
     */
    function statusLabelFor(item, status, def_label = DEFAULT_LABEL) {
        const key = statusFor(item, status);
        return key && statusValueLabels()[key] || def_label;
    }

    /**
     * statusFor
     *
     * @param {Selector} item
     * @param {string}   status       Status type class or selector.
     *
     * @returns {string|undefined}    Key into {@link statusValueLabels}.
     */
    function statusFor(item, status) {
        //_debug(`statusFor "${status}" for item =`, item);
        const $item = itemRow(item);
        const data  = $item.data(STATUS_DATA);
        const key   = status.replace(/^\./, '');
        return data && data[key] || setStatusFor($item, key);
    }

    /**
     * Restore a status display to its original state.
     *
     * @param {Selector} item
     * @param {string}   status       Status type class or selector.
     */
    function resetStatusFor(item, status) {
        //_debug(`resetStatusFor "${status}" for item =`, item);
        const $item    = itemRow(item);
        const $status  = $item.find(selector(status));
        const original = $status.data(SAVED_DATA);
        setStatusFor($item, status, original.value, original.note);
    }

    /**
     * setStatusFor
     *
     * @param {Selector} item
     * @param {string}   status       Status type class or selector.
     * @param {string}   [new_value]
     * @param {string}   [new_note]
     *
     * @return {string|undefined}
     */
    function setStatusFor(item, status, new_value, new_note) {
        _debug(`setStatusFor "${new_value}" -> "${status}" for item =`, item);
        const $item = itemRow(item);
        const data  = $item.data(STATUS_DATA);
        const key   = status.replace(/^\./, '');
        let value   = new_value;
        value &&= setStatusValueFor($item, key, value, new_note);
        value ||= getStatusValueFor($item, key);
        $item.data(STATUS_DATA, { ...data, [key]: value });
        return value;
    }

    /**
     * getStatusValueFor
     *
     * @param {Selector} item
     * @param {string}   status       Status type class or selector.
     *
     * @return {string|undefined}
     */
    function getStatusValueFor(item, status) {
        //_debug(`getStatusValueFor "${status}" for item =`, item);
        const $item   = itemRow(item);
        const $status = $item.find(selector(status));
        const classes = Array.from($status[0]?.classList || []);
        return classes.findLast(cls => statusValues().has(cls));
    }

    /**
     * setStatusValueFor
     *
     * @param {Selector} item
     * @param {string}   status       Status type class or selector.
     * @param {string}   new_value
     * @param {string}   [new_note]   Filename or other note text.
     *
     * @return {string}
     */
    function setStatusValueFor(item, status, new_value, new_note) {
        //_debug(`setStatusValueFor "${new_value}" -> "${status}"`);
        const $item   = itemRow(item);
        const $status = $item.find(selector(status));
        const value   = new_value.replace(/^\./, '');
        if (!$status.hasClass(value)) {
            const label = statusValueLabels()[value];
            $status.removeClass(Array.from(statusValues()));
            $status.addClass(value);
            setStatusDetails($status, label, new_note);
        }
        return value;
    }

    /**
     * initializeStatusFor
     *
     * @param {Selector} item
     * @param {string}   status       Status type class or selector.
     * @param {string}   [note]       Filename or other note text.
     */
    function initializeStatusFor(item, status, note) {
        //_debug(`initializeStatusFor "${status}" for item =`, item);
        const $item   = itemRow(item);
        const $status = $item.find(selector(status));
        const label   = statusLabelFor($item, status);
        const value   = statusFor($item, status);
        setStatusDetails($status, label, note);
        $status.data(SAVED_DATA, { value: value, note: note });
    }

    /**
     * setStatusDetails
     *
     * @param {jQuery} $status
     * @param {string} label
     * @param {string} [note]         Filename or other note text.
     */
    function setStatusDetails($status, label, note) {
        const $text    = $status.find('div.text');
        const $details = $status.find('details.text');
        const $edit    = $status.find('.fix');
        const needed   = $status.is(FILE_NEEDED);
        const fixable  = !needed && $status.is(PROBLEMATIC);
        const details  = needed || isDefined(note);
        if (details) {
            const $note = $details.children('.name');
            let file = note;
            if (file) { $note.text(file) } else { file = $note.text() }
            if (file) { $details.attr('title', `${label}: ${file}`) }
            $details.children('summary').text(label);
        } else {
            $text.text(label);
        }
        toggleHidden($text,    details);
        toggleHidden($details, !details);
        toggleHidden($edit,    !fixable);
    }

    // ========================================================================
    // Functions - submission steps
    // ========================================================================

    /**
     * Mapping of submission step name to the status column that it updates
     * (not including pseudo states).
     *
     * @type {Object.<string,string>}
     *
     * @see "en.emma.bulk.step"
     *
     * TODO: pass in via assets.js.erb.
     */
    const SUBMIT_STEP_TO_STATUS = {
        db:      FILE_STATUS_CLASS,
        cache:   UPLOAD_STATUS_CLASS,
        promote: UPLOAD_STATUS_CLASS,
        index:   INDEX_STATUS_CLASS,
    };

    const SUBMITTING_DATA = 'submitIds';

    /**
     * getSubmissionList
     *
     * @returns {Object.<string,string>|undefined}
     */
    function getSubmissionList() {
        return $body.data(SUBMITTING_DATA);
    }

    /**
     * setSubmissionList
     *
     * @param {string[]|object} ids
     *
     * @returns {Object.<string,string>}
     */
    function setSubmissionList(ids) {
        _debug('setSubmissionList: ids =', ids);
        // noinspection JSUnusedLocalSymbols
        const table = isObject(ids) ? ids : toObject(ids, id => 'STARTING');
        $body.data(SUBMITTING_DATA, table);
        return table;
    }

    /**
     * Process a message sent back from the server as part of a bulk submission
     * sequence.
     *
     * @param {SubmitResponseSubclass} message
     */
    function onSubmissionResponse(message) {
        if (message.isInitial) {
            onInitialResponse(message);
        } else if (message.step) {
            onStepResponse(message);
        } else if (message.isIntermediate) {
            onBatchResponse(message);
        } else if (message.isFinal) {
            onFinalResponse(message);
        } else {
            console.warn('onSubmissionResponse: unexpected:', message);
        }
    }

    /**
     * Process a response message indicating the start of a bulk submission of
     * ManifestItem entries.
     *
     * @param {SubmitResponse} message
     */
    function onInitialResponse(message) {
        _debug('onInitialResponse: message =', message);
        resetItems();
        let items = message.items;
        items = items.map(id => isObject(id) ? id.items : id).flat();
        items = items.map(id => (typeof id === 'number') ? `${id}` : id);
        setSubmissionList(items);
        counter.failed.clear();
        counter.succeeded.clear();
        counter.transmitting.value = items.length;
    }

    /**
     * Process a response message indicating the success/failure of one or more
     * ManifestItem entries at the given submission step.
     *
     * @param {SubmitStepResponse} message
     */
    function onStepResponse(message) {
        const func    = 'onStepResponse';
        const total   = message.submitted.length;
        const success = message.success;
        const failure = message.failure;
        const invalid = message.invalid;
        const step    = message.step;
        const status  = SUBMIT_STEP_TO_STATUS[step];
        const list    = getSubmissionList() || {};
        let changed   = false;
        _debug(`${func}: message =`, message);

        success.forEach(id => {
            const value  = SUCCEEDED_MARKER;
            const $item  = itemFor(id);
            setStatusFor($item, status, value);
            list[id] = value;
            changed  = true;
        });
        for (const [id, error] of Object.entries(failure)) {
            const value  = FAILED_MARKER;
            const $item  = itemFor(id);
            setStatusFor($item, status, value, error);
            list[id] = `${value}: ${error}`;
            changed  = true;
        }
        if (isPresent(invalid)) {
            console.warn(`${func}: invalid:`, invalid);
        }

        const successes = success.length;
        const failures  = Object.keys(failure).length;
        const count     = successes + failures + invalid.length;
        if (count !== total) {
            console.warn(`${func}: ${count} entries but ${total} submitted`);
        }

        if (changed) {
            setSubmissionList(list);
        }
    }

    /**
     * onBatchResponse
     *
     * @param {SubmitStepResponse} message
     */
    function onBatchResponse(message) {
        const func    = 'onBatchResponse';
        const total   = message.submitted.length;
        const success = message.success;
        const failure = message.failure;
        const invalid = message.invalid;
        const list    = getSubmissionList() || {};
        let changed   = false;
        _debug(`${func}: message =`, message);

        success.forEach(id => {
            if (!list[id]) {
                const value  = SUCCEEDED_MARKER;
                const status = SUBMIT_STEP_TO_STATUS.index;
                const $item  = itemFor(id);
                setStatusFor($item, status, value);
                list[id] = value;
                changed  = true;
            }
        });
        for (const [id, error] of Object.entries(failure)) {
            if (!list[id]) {
                const value  = FAILED_MARKER;
                const status = SUBMIT_STEP_TO_STATUS.index;
                const $item  = itemFor(id);
                setStatusFor($item, status, value, error);
                list[id] = `${value}: ${error}`;
                changed  = true;
            }
        }
        if (isPresent(invalid)) {
            console.warn(`${func}: invalid:`, invalid);
        }

        const successes = success.length;
        const failures  = Object.keys(failure).length;
        const count     = successes + failures + invalid.length;
        if (count !== total) {
            console.warn(`${func}: ${count} entries but ${total} submitted`);
        }

        counter.failed.increment(failures);
        counter.succeeded.increment(successes);
        counter.transmitting.decrement(successes + failures);

        if (changed) {
            setSubmissionList(list);
        }
    }

    /**
     * onFinalResponse
     *
     * @param {SubmitResponse} message
     */
    function onFinalResponse(message) {
        const func = 'onFinalResponse';
        const list = getSubmissionList() || {};
        const data = message.data || {};
        _debug(`${func}: message =`, message);

        let total = 0;
        let count = 0;
        for (const [_job, entry] of Object.entries(data)) {
            /** @type {SubmitStepResponseData} */
            const message = entry;
            const success = message.success || [];
            const failure = message.failure || {};
            const invalid = message.invalid || [];
            success.forEach(id => {
                const value = SUCCEEDED_MARKER;
                const was   = `"${list[id]}"`;
                const now   = `"${value}"`;
                if (was !== now) {
                    console.warn(`${func}: ${id}: was ${was}; now ${now}`);
                }
                count++;
            });
            for (const [id, error] of Object.entries(failure)) {
                const value = FAILED_MARKER;
                const was   = `"${list[id]}"`;
                const now   = `"${value}: ${error}"`;
                if (was !== now) {
                    console.warn(`${func}: ${id}: was ${was}; now ${now}`);
                }
                count++;
            }
            if (isPresent(invalid)) {
                console.warn(`${func}: invalid:`, invalid);
                count += invalid.length;
            }
            total += (message.submitted?.length || 0);
        }
        if (count !== total) {
            console.warn(`${func}: ${count} entries but ${total} submitted`);
        }

        submissionsActive(false);
    }

    /**
     * Called when the server does not accept the WebSocket subscription
     * attempt (probably because reauthorization is required).
     */
    function onSubmissionRejected() {
        _debug('onSubmissionRejected');
        const note = 'Refresh this page to re-authenticate.';
        flashError(`Connection error: ${note}`);
        submissionsActive(false);
    }

    // ========================================================================
    // Functions - submission monitor
    // ========================================================================

    let submission_monitor;

    /**
     * submissionMonitor
     *
     * @returns {SubmitModal}
     */
    function submissionMonitor() {
        return submission_monitor ||= SubmitModal.instanceFor($monitor);
    }

    /**
     * Get the current submission request, creating it if necessary.
     *
     * @returns {SubmitRequest}
     */
    function getSubmissionRequest() {
        //_debug('getSubmissionRequest');
        return submissionMonitor().getRequestData() || setSubmissionRequest();
    }

    /**
     * Set the current submission request to the currently checked items
     * by default.
     *
     * @param {string|string[]|SubmitRequest|SubmitRequestPayload} [values]
     *
     * @returns {SubmitRequest}
     */
    function setSubmissionRequest(values) {
        _debug('setSubmissionRequest:', values);
        let data = values;
        if (notDefined(data)) {
            data = itemsChecked().toArray();
            data = { items: data.map(item => $(item).attr(ITEM_ATTR)) };
        } else if (Array.isArray(data)) {
            data = { items: data };
        } else if (typeof data !== 'object') {
            data = { items: arrayWrap(data) };
        }
        data = { manifest_id: manifestId(), ...data };
        return submissionMonitor().setRequestData(data);
    }

    /**
     * Open a channel for making and controlling submissions.
     */
    function initializeSubmissionMonitor() {
        _debug('initializeSubmissionMonitor');

        SubmitModal.setupFor($monitor, {
            rejected:   onSubmissionRejected,
            onResponse: onSubmissionResponse,
            onOpen:     onOpen,
            onClose:    onClose,
        });

        function onOpen($activator, check_only, halted) {
            _debug('onOpen SubmitModal', halted, check_only, $activator);
            // TODO: ?
        }

        function onClose($activator, check_only, halted) {
            _debug('onClose SubmitModal', halted, check_only, $activator);
            // TODO: ?
        }
    }

    // ========================================================================
    // Functions - file resolution
    // ========================================================================

    /**
     * A FileReader along with the original File object.
     */
    class FileReaderExt extends FileReader {

        /** @param {File} file */
        file;

        /** @param {File} file */
        constructor(file) { super(); this.file = file }

        /** @param {Blob} [blob] */
        readAsBinaryString(blob = this.file) { super.readAsBinaryString(blob) }

        read() { this.readAsBinaryString() }

        get stateLabel() {return this.constructor.stateLabel(this.readyState)}

        static stateLabel(state) {
            switch (state) {
                case this.DONE:    return 'DONE';
                case this.EMPTY:   return 'EMPTY';
                case this.LOADING: return 'LOADING';
                default:           return state?.toString?.() || '-';
            }
        }
    }

    /**
     * @type {Object.<string,FileReaderExt>}
     */
    let local_readers;

    /**
     * Local files selected by the user.
     *
     * @returns {Object.<string,FileReaderExt>}
     */
    function localFileReaders() {
        return local_readers ||= {};
    }

    /**
     * Local files selected by the user.
     *
     * @param {string} file_name
     *
     * @returns {FileReaderExt|undefined}
     */
    function localFileReaderFor(file_name) {
        return localFileReaders()[file_name];
    }

    /**
     * Include a local file.
     *
     * @param {File|FileReaderExt} f
     * @param {string}             [caller]     For diagnostics.
     *
     * @returns {FileReaderExt}
     */
    function addLocalFileReader(f, caller) {
        const fr   = (f instanceof FileReader) ? f : new FileReaderExt(f);
        const name = fr.file.name;
        if (localFileReaderFor(name)) {
            const func = caller || 'addLocalFileReader';
            _debug(`${func}: replacing reader for "${name}"`);
        }
        return localFileReaders()[name] = fr;
    }

    /**
     * Initialize local file readers.
     */
    function clearLocalFileReaders() {
        local_readers = undefined;
    }

    // ========================================================================
    // Functions - file resolution - local
    // ========================================================================

    /**
     * Setup handlers for local file selection.
     */
    function initializeLocalFilesResolution() {
        _debug('initializeLocalFilesResolution');
        clearLocalFileReaders();
        clearLocalFileSelection();
        setupLocalFilePrompt();
    }

    /**
     * Setup control for local file selection.
     */
    function setupLocalFilePrompt() {
        // Set up the visible button to proxy for the non-visible <input>.
        $local_button.attr('tabindex', 0);
        handleClickAndKeypress($local_button, beforeLocalFilesSelected);

        // The <input> is made non-visible.
        $local_input.attr('tabindex', -1).attr('aria-hidden', true);
        handleEvent($local_input, 'change', afterLocalFilesSelected);
    }

    /**
     * @type {File[]|undefined}
     */
    let local_file_selection;

    /**
     * Local files selected by the user.
     *
     * @returns {File[]}
     */
    function localFileSelection() {
        return local_file_selection ||= [];
    }

    /**
     * Include a local file.
     *
     * @param {File} file
     */
    function addLocalFile(file) {
        _debug(`Queueing local file "${file.name}":`, file);
        localFileSelection().push(file);
    }

    /**
     * Clear any previous file selection.
     */
    function clearLocalFileSelection() {
        $local_input.val(null);
        local_file_selection = undefined;
    }

    /**
     * Respond before the file chooser is invoked.
     *
     * @param {jQuery.Event|Event} event
     */
    function beforeLocalFilesSelected(event) {
        _debug('*** beforeLocalFilesSelected: event =', event);
        if (event.currentTarget === event.target) {
            clearLocalFileSelection();
            $local_input.click();
        }
    }

    /**
     * Respond after the file chooser returns.
     *
     * @param {jQuery.Event|Event} event
     */
    function afterLocalFilesSelected(event) {
        const func  = 'afterLocalFilesSelected';
        const files = event.currentTarget?.files || event.target?.files;
        //_debug(`*** ${func}: event =`, event);
        if (!files) {
            console.warn(`${func}: no event target`);
        } else if (isEmpty(files)) {
            console.warn(`${func}: no files selected`);
        } else {
            _debug(`${func}: ${files.length} files`);
            queueLocalFiles(files);
            preProcessLocalFiles();
        }
    }

    /**
     * Replace the current list of selected files.
     *
     * @param {File[]|FileList} files
     */
    function queueLocalFiles(files) {
        _debug(`queueLocalFiles: ${files.length} files =`, files);
        const count = files?.length || 0;
        for (let i = 0; i < count; i++) {
            const file = files[i];
            const name = file?.name;
            if (!name) {
                _debug(`IGNORING nameless file[${i}]:`, file);
            } else if (!file_references.local.includes(name)) {
                _debug(`IGNORING unrequested file "${name}":`, file);
            } else if (!files_remaining.local.includes(name)) {
                _debug(`IGNORING already handled file "${name}":`, file);
            } else {
                addLocalFile(file);
            }
        }
    }

    /**
     * Update submission statuses and report the result of pre-processing local
     * files.
     *
     * @param {File[]} [files]
     */
    function preProcessLocalFiles(files = localFileSelection()) {
        const func = 'preProcessLocalFiles';
        _debug(`${func}: ${files.length} files =`, files);
        const lines = [];
        const names = [];
        const good  = [];
        const bad   = []; // TODO: are there "badness" criteria at this stage?
        files.forEach(file => {
            const fr   = new FileReaderExt(file);
            const name = fr.file.name;
            const size = fr.file.size;
            const item = `${name} : ${size} bytes`;
            if (!removeFrom(files_remaining.local, name)) {
                _debug(`${func}: ${item} -- ALREADY PROCESSED`);
            } else {
                _debug(`${func}: ${item}`);
            }
            addLocalFileReader(fr, func);
            names.push(name);
            good.push(item);
        });
        const resolved    = good.length;
        const problematic = bad.length;
        const remaining   = files_remaining.local.length;

        if (resolved) {
            let sel_changed = false;
            const fulfilled = new Set(names);
            allItems().each((_, item) => {
                const $item   = $(item);
                const $status = $item.find(FILE_STATUS);
                const needed  = $status.is(FILE_NEEDED);
                const name    = needed && $status.find('.name').text();
                if (name && fulfilled.has(name)) {
                    setStatusFor($item, FILE_STATUS, SUCCEEDED);
                    sel_changed = updateItemSelect($item) || sel_changed;
                }
            });
            if (sel_changed) {
                updateGroupSelect();
            }
            lines.push(resolvedLabel(resolved), ...good, '');
        }

        if (problematic) {
            lines.push(problematicLabel(problematic), ...bad, '');
        }

        if (remaining) {
            lines.push(remainingLabel(remaining), ...files_remaining.local);
        } else {
            updateSubmitReady();
            lines.push(allResolvedLabel());
        }

        flashMessage(lines.join("\n"));
    }

    /**
     * resolvedLabel # TODO: I18n
     *
     * @param {number} [count]
     *
     * @returns {string}
     */
    function resolvedLabel(count) {
        const files = (count === 1) ? 'FILE' : 'FILES';
        return `RESOLVED ${files}:`;
    }

    /**
     * problematicLabel # TODO: I18n
     *
     * @param {number} [count]
     *
     * @returns {string}
     */
    function problematicLabel(count) {
        const files = (count === 1) ? 'FILE' : 'FILES';
        return `PROBLEM ${files}:`;
    }

    /**
     * remainingLabel # TODO: I18n
     *
     * @param {number} [count]
     *
     * @returns {string}
     */
    function remainingLabel(count) {
        const num   = Number(count || 0);
        const files = (num === 1) ? 'FILE' : 'FILES';
        return `${num} ${files} STILL NEEDED:`;
    }

    /**
     * allResolvedLabel # TODO: I18n
     *
     * @returns {string}
     */
    function allResolvedLabel() {
        const total = allItems().length;
        const ready = itemsReady().length;
        let count, submittable;
        if (ready) {
            if (ready === total) {
                count = (total > 1) ? 'ALL' : 'THE';
            } else {
                const selected = itemsSelected().length;
                if (!selected) {
                    count = ready.toString();
                } else if (ready >= selected) {
                    count = 'ALL SELECTED';
                } else {
                    count = 'SOME SELECTED';
                }
            }
            const items = (ready > 1) ? 'ITEMS'   : 'ITEM';
            submittable = `${count} ${items} READY FOR SUBMISSION`;
        } else {
            const items = (total > 1) ? 'ITEMS'   : 'ITEM';
            const need  = (total > 1) ? 'REQUIRE' : 'REQUIRES';
            submittable = `${items} STILL ${need} ATTENTION`;
        }
        return `ALL FILES RESOLVED - ${submittable}`;
    }

    // ========================================================================
    // Functions - file resolution - local
    // ========================================================================

    /**
     * Make use of the file readers stored in {@link preProcessLocalFiles}.
     *
     * @param {jQuery.Event|UIEvent} [event]
     */
    function processLocalFiles(event) {
        const func     = 'processLocalFiles';
        _debug(`${func}: event =`, event);
        _debug(`${func}: local_readers =`, local_readers);
        const readers  = local_readers && Object.values(local_readers);
        /** @type {Promise<FileReaderExt>[]} */
        const promises = readers?.map(reader => asyncLocalFileRead(reader));
        if (!promises) {
            console.warn(`${func}: No files have ever been selected`);
        } else if (isEmpty(promises)) {
            console.warn(`${func}: No files to read`);
        } else {
            Promise.all(promises).then(fulfilledLocalFiles);
        }
    }

    /**
     * Generate a new Promise for accessing a file.
     *
     * @param {File|FileReaderExt} f
     *
     * @returns {Promise<FileReaderExt>}
     */
    function asyncLocalFileRead(f) {
        // NOTE: maybe this should have a callback that is run when the file
        //  has been read -- this callback could perform the next step of
        //  uploaded the FileReader content, then progressing with the
        //  submission of that ManifestItem.
        _debug('asyncLocalFileRead', f);
        return new Promise((resolve, reject) => {
            /** @param {ProgressEvent} ev */
            const fr_log = (ev) => {
                const state = ev.target?.stateLabel || '???';
                console.log(`*** FR ${ev.type} | ${state} | ev =`, ev);
                return true;
            };
            const fr = (f instanceof FileReader) ? f : new FileReaderExt(f);
            fr.onabort     = ev => fr_log(ev);
            fr.onerror     = ev => fr_log(ev) && reject(fr);
            fr.onload      = ev => fr_log(ev) && resolve(fr);
            fr.onloadend   = ev => fr_log(ev);
            fr.onloadstart = ev => fr_log(ev);
            fr.onprogress  = ev => fr_log(ev);
            fr.read();
        });
    }

    /**
     * Called after the content from all FileReaders has been acquired.
     *
     * @param {FileReaderExt[]} readers
     */
    function fulfilledLocalFiles(readers) {
        const func = 'fulfilledLocalFiles';
        _debug(`${func}: readers =`, readers);
        // NOTE: This gets run after all selected files have been read.
        //  Maybe this is the place to batch up FileReader content for upload
        //  and then progressing with batch submission of related ManifestItems
    }

    // ========================================================================
    // Functions - file resolution - remote
    // ========================================================================

    /**
     * Setup for acquiring files from cloud-based storage.
     */
    function initializeRemoteFilesResolution() {
        const func = 'initializeRemoteFilesResolution'; _debug(func);
        //clearRemoteFileReaders();
        clearRemoteFileSelection();
        setupRemoteFilePrompt();
    }

    /**
     * Setup control for remote file selection. // TODO: cloud-based storage
     */
    function setupRemoteFilePrompt() {
        // Set up the visible button to proxy for the non-visible <input>.
        $remote_button.attr('tabindex', 0);
        handleClickAndKeypress($remote_button, beforeRemoteFilesSelected);

        // The <input> is made non-visible.
        $remote_input.attr('tabindex', -1).attr('aria-hidden', true);
        handleEvent($remote_input, 'change', afterRemoteFilesSelected);
    }

    /**
     * @type {File[]|undefined}
     */
    let remote_file_selection;

    /**
     * Remote files selected by the user.
     *
     * @returns {File[]}
     */
    function remoteFileSelection() {
        return remote_file_selection ||= [];
    }

    /**
     * Include a remote file.
     *
     * @param {File} file
     */
    function addRemoteFile(file) {
        _debug(`Queueing remote file "${file.name}":`, file);
        remoteFileSelection().push(file);
    }

    /**
     * Clear any previous file selection.
     */
    function clearRemoteFileSelection() {
        $remote_input.val(null);
        remote_file_selection = undefined;
    }

    /**
     * Respond before the file chooser is invoked.
     *
     * @param {jQuery.Event|Event} event
     */
    function beforeRemoteFilesSelected(event) {
        _debug('*** beforeRemoteFilesSelected: event =', event);
        if (event.currentTarget === event.target) {
            clearRemoteFileSelection();
            $remote_input.click();
        }
    }

    /**
     * Respond after the file chooser returns.
     *
     * @param {jQuery.Event|Event} event
     */
    function afterRemoteFilesSelected(event) {
        const func  = 'afterRemoteFilesSelected';
        const files = event.currentTarget?.files || event.target?.files;
        //_debug(`*** ${func}: event =`, event);
        if (!files) {
            console.warn(`${func}: no event target`);
        } else if (isEmpty(files)) {
            console.warn(`${func}: no files selected`);
        } else {
            _debug(`${func}: ${files.length} files`);
            queueRemoteFiles(files);
            preProcessRemoteFiles();
        }
    }

    /**
     * Replace the current list of selected files.
     *
     * @param {File[]|FileList} files
     */
    function queueRemoteFiles(files) {
        _debug(`queueRemoteFiles: ${files.length} files =`, files);
        const count = files?.length || 0;
        for (let i = 0; i < count; i++) {
            const file = files[i];
            const name = file?.name;
            if (!name) {
                _debug(`IGNORING nameless file[${i}]:`, file);
            } else if (!file_references.remote.includes(name)) {
                _debug(`IGNORING unrequested file "${name}":`, file);
            } else if (!files_remaining.remote.includes(name)) {
                _debug(`IGNORING already handled file "${name}":`, file);
            } else {
                addRemoteFile(file);
            }
        }
        // NOTE: For testing purposes, make it look like the selected file(s)
        //  were needed.
        for (let i = 0; i < count; i++) {
            const file = files[i];
            const name = file?.name;
            let add;
            if (!file_references.remote.includes(name)) {
                add = file_references.remote.push(name);
            }
            if (!files_remaining.remote.includes(name)) {
                add = files_remaining.remote.push(name);
            }
            if (add) {
                addRemoteFile(file);
            }
        }
    }

    /**
     * Update submission statuses and report the result of pre-processing
     * remote files.
     *
     * @param {File[]} [files]
     */
    function preProcessRemoteFiles(files = remoteFileSelection()) {
        const func = 'preProcessRemoteFiles';
        _debug(`${func}: ${files.length} files =`, files);
        const lines = [];
        const names = [];
        const good  = [];
        const bad   = []; // TODO: are there "badness" criteria at this stage?
        files.forEach(file => {
            const fr   = new FileReaderExt(file);
            const name = fr.file.name;
            const size = fr.file.size;
            const item = `${name} : ${size} bytes`;
            if (!removeFrom(files_remaining.remote, name)) {
                _debug(`${func}: ${item} -- ALREADY PROCESSED`);
            } else {
                _debug(`${func}: ${item}`);
            }
            //addRemoteFileReader(fr, func); // TODO: ???
            names.push(name);
            good.push(item);
        });
        files_remaining.remote = []; // NOTE: simulate all resolved
        const resolved    = good.length;
        const problematic = bad.length;
        const remaining   = files_remaining.remote.length;

        if (resolved) {
            let sel_changed = false;
            const fulfilled = new Set(names);
            allItems().each((_, item) => {
                const $item   = $(item);
                const $status = $item.find(FILE_STATUS);
                const needed  = $status.is(FILE_NEEDED);
                const name    = needed && $status.find('.name').text();
                if (name && (fulfilled.has(name) || name.startsWith('http'))) {
                    setStatusFor($item, FILE_STATUS, SUCCEEDED);
                    sel_changed = updateItemSelect($item) || sel_changed;
                }
            });
            if (sel_changed) {
                updateGroupSelect();
            }
            //lines.push(resolvedLabel(resolved), ...good, '');
        }

        if (problematic) {
            lines.push(problematicLabel(problematic), ...bad, '');
        }

        if (remaining) {
            //lines.push(remainingLabel(remaining), ...files_remaining.remote);
        } else {
            updateSubmitReady();
            //lines.push(allResolvedLabel());
        }

        if (isPresent(lines)) {
            flashMessage(lines.join("\n"));
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
     * @param {Selector} [target]     Default: {@link $start}.
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
            (id = attribute($start, MANIFEST_ATTR)) ||
            _debug(`${func}: no manifest ID`);
        }
        return id || manifest_id;
    }

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

    // ========================================================================
    // Event handlers
    // ========================================================================

    handleClickAndKeypress($start,  onSubmissionStart);
    handleClickAndKeypress($stop,   onSubmissionStop);
    handleClickAndKeypress($pause,  onSubmissionPause);
    handleClickAndKeypress($resume, onSubmissionResume);

    handleEvent($group_checkbox,  'change', onGroupCheckboxChange);
    handleEvent($item_checkboxes, 'change', onItemCheckboxChange);

    // ========================================================================
    // Actions
    // ========================================================================

    SubmitModal.initializeAll();
    initializeSubmissionForm();
    Counter.resetAll();

});
