// app/assets/javascripts/controllers/manifest-remit.js


import { AppDebug }                             from '../application/debug';
import { appSetup }                             from '../application/setup';
import { arrayWrap, uniq }                      from '../shared/arrays';
import { BaseClass }                            from '../shared/base-class';
import { selector, toggleHidden }               from '../shared/css';
import { handleClickAndKeypress, handleEvent }  from '../shared/events';
import { clearFlash, flashError, flashMessage } from '../shared/flash';
import { SubmitModal }                          from '../shared/submit-modal';
import { BulkUploader }                         from '../shared/uploader';
import {
    isDefined,
    isEmpty,
    isMissing,
    isPresent,
    notDefined,
} from '../shared/definitions';
import {
    htmlDecode,
    selfOrDescendents,
    selfOrParent
} from '../shared/html';
import {
    BEST_CHOICE_MARKER,
    DISABLED_MARKER,
    ITEM_ATTR,
    ITEM_MODEL,
    MANIFEST_ATTR,
    attribute,
    buttonFor,
    enableButton,
    initializeButtonSet,
    serverSend,
} from '../shared/manifests';
import {
    compact,
    dup,
    fromJSON,
    invert,
    isObject,
    remove,
    toObject,
} from '../shared/objects';
import {
    SubmitControlResponse,
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
    const DATA_STATUS_CLASS         = 'data-status';
    const FILE_STATUS_CLASS         = 'file-status';
    const UPLOAD_STATUS_CLASS       = 'upload-status';
    const INDEX_STATUS_CLASS        = 'index-status';
    const ENTRY_STATUS_CLASS        = 'entry-status';
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
    const DATA_STATUS           = selector(DATA_STATUS_CLASS);
    const FILE_STATUS           = selector(FILE_STATUS_CLASS);
    const UPLOAD_STATUS         = selector(UPLOAD_STATUS_CLASS);
    const INDEX_STATUS          = selector(INDEX_STATUS_CLASS);
    const ENTRY_STATUS          = selector(ENTRY_STATUS_CLASS);
    const ACTIVE                = selector(ACTIVE_MARKER);
  //const NOT_STARTED           = selector(NOT_STARTED_MARKER);
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
        start:   $start,
        stop:    $stop,
        pause:   $pause,
        resume:  $resume,
        monitor: $monitor,
    };

    /**
     * @typedef {
     *      function(enable?: boolean, prop?: ActionPropertiesExt)
     * } ButtonEnableFunction
     */

    /**
     * Table of button enabling functions.
     *
     * @type {Object.<string,ButtonEnableFunction>}
     */
    const SUBMISSION_ENABLE = toObject(SUBMISSION_BUTTONS,
        name => ((v, prop) => enableSubmissionButton(name, v, prop))
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
        initializeUploader();
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
     * @param {string}              type       A {@link SUBMISSION_BUTTONS} key
     * @param {boolean}             [enable]
     * @param {ActionPropertiesExt} [prop]     Overrides configured properties.
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
            uploader.upload();
            const action  = startSubmissions();
            const options = { caller: func, fail: fail };
            submissionRequest(action, options);
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
            uploader.cancel();
            const action  = stopSubmissions();
            const options = { caller: func, fail: fail };
            submissionRequest(action, options);
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
            uploader.pause();
            const action  = pauseSubmissions();
            const options = { caller: func, fail: fail };
            submissionRequest(action, options);
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
            uploader.resume();
            const action  = resumeSubmissions();
            const options = { caller: func, fail: fail };
            submissionRequest(action, options);
        }
    }

    /**
     * Perform a Manifest submission action on the server.
     *
     * @param {string}                                       action
     * @param {{caller?:string, fail?:string, data?:object}} [options]
     */
    function submissionRequest(action, options) {
        const func = options?.caller || 'submissionRequest';
        _debug(`${func}: ${action}`);
        if (!submissionMonitor().command(action, options?.data)) {
            const tag  = options?.fail || `${action} failed`;
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

    const file_references = { local: {}, remote: {} };
    const files_remaining = { local: {}, remote: {} };

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
        prop.highlight = !blocked;
        SUBMISSION_ENABLE.start(!blocked, prop);
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
            const prop = started ? { highlight: false } : {};
            SUBMISSION_ENABLE.start(!started, prop);
            SUBMISSION_ENABLE.stop(started);
            SUBMISSION_ENABLE.pause(started);
            SUBMISSION_ENABLE.resume(false);
            SUBMISSION_ENABLE.monitor(true, prop);
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
        [DATA_STATUS]:   `${CANT_SUBMIT}, ${FAILED}`,
        [FILE_STATUS]:   `${CANT_SUBMIT}, ${FAILED}`,
        [UPLOAD_STATUS]: `${CANT_SUBMIT}`,
        [INDEX_STATUS]:  `${CANT_SUBMIT}`,
        [ENTRY_STATUS]:  `${CANT_SUBMIT}, ${SUCCEEDED}, ${DONE}`,
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
        const local = {}, remote = {};
        allItems().each((_, item) => {
            const $item   = $(item);
            const item_id = manifestItemId($item);
            STATUS_SELECTORS.forEach(status => {
                let name;
                const $status = $item.find(status);
                if ($status.is(FILE_NEEDED)) {
                    const path = $item.attr(FILE_NAME_ATTR) || '';
                    if ((name = path.split('\\').pop().split('/').pop())) {
                        local[item_id] = name;
                    } else if ((name = $item.attr(FILE_URL_ATTR))) {
                        remote[item_id] = name;
                    }
                }
                initializeStatusFor($item, status, name);
            });
            updateItemSelect($item);
        });
        file_references.local  = local;
        files_remaining.local  = dup(local);
        file_references.remote = remote;
        files_remaining.remote = dup(remote);
        _debug(`INITIAL file_references.local  =`, file_references.local);
        _debug(`INITIAL file_references.remote =`, file_references.remote);
    }

    /**
     * Restore the status values of selected items to their original state in
     * preparation for resubmitting.
     *
     * @param {boolean} [total]       If *true*, allow FILE_NEEDED.
     */
    function resetItems(total) {
        _debug('resetItems');
        itemsToTransmit().each((_, item) => {
            const $item = $(item);
            STATUS_TYPES.forEach(stat => resetStatusFor($item, stat, total));
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

    /**
     * Return all items which are to be transmitted.
     *
     * @returns {jQuery}
     */
    function itemsToTransmit() {
        const $selected = itemsSelected();
        return isPresent($selected) ? $selected : allItems();
    }

    /**
     * Return all items which are eligible for transmission.
     *
     * @returns {jQuery}
     */
    function itemsReady() {
        return itemsWhere(isReady);
    }

    /**
     * Return all items which have a checkmark and are not disabled.
     *
     * @returns {jQuery}
     */
    function itemsSelected() {
        return itemsWhere(isSelected);
    }

    /**
     * Return all items which have a checkmark (whether or not they are
     * disabled).
     *
     * @returns {jQuery}
     */
    function itemsChecked() {
        return itemsWhere(isChecked);
    }

    /**
     * Return all items which are currently active.
     *
     * @returns {jQuery}
     */
    function itemsTransmitting() {
        return itemsWhere(isTransmitting);
    }

    /**
     * Return all items which have been successfully submitted.
     *
     * @returns {jQuery}
     */
    function itemsSucceeded() {
        return itemsWhere(isSucceeded);
    }

    /**
     * Return all items which have failed.
     *
     * @returns {jQuery}
     */
    function itemsFailed() {
        return itemsWhere(isFailed);
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

    /**
     * Indicate whether the item's checkbox is checked (regardless of whether
     * it is disabled or not).
     *
     * @param {Selector} item
     *
     * @returns {boolean}
     */
    function isChecked(item) {
        const $item = itemRow(item);
        const cb    = checkbox($item);
        return !!cb && cb.checked && !cb.indeterminate;
    }

    /**
     * Indicate whether the item is checked and not disabled.
     *
     * @param {Selector} item
     *
     * @returns {boolean}
     */
    function isSelected(item) {
        const $item = itemRow(item);
        const cb    = checkbox($item);
        return !!cb && cb.checked && !cb.disabled && !cb.indeterminate;
    }

    /**
     * Indicate whether the item is eligible for transmission.
     *
     * @param {Selector} item
     *
     * @returns {boolean}
     */
    function isReady(item) {
        return !isNotReady(item);
    }

    function isNotReady(item) {
        const $item    = itemRow(item);
        const statuses = Object.entries(NOT_READY_VALUES);
        return statuses.some(([s, invalid]) => $item.find(s).is(invalid));
    }

    /**
     * Indicate whether the associated manifest item is not saved.
     *
     * @param {Selector} item
     *
     * @returns {boolean}
     */
    function isUnsaved(item) {
        return hasCondition(item, UNSAVED);
    }

    /**
     * Indicate whether the item is currently active in a submission step.
     *
     * @param {Selector} item
     *
     * @returns {boolean}
     */
    function isTransmitting(item) {
        return hasCondition(item, ACTIVE);
    }

    /**
     * Indicate whether the item has a failed submission step.
     *
     * @param {Selector} item
     *
     * @returns {boolean}
     */
    function isFailed(item) {
        return hasCondition(item, FAILED);
    }

    /**
     * Indicate whether the item has been submitted (i.e., all submission steps
     * have succeeded).
     *
     * @param {Selector} item
     *
     * @returns {boolean}
     */
    function isSucceeded(item) {
        return isExclusively(item, SUCCEEDED);
    }

    /**
     * Indicate whether any submission steps for the item match the given
     * criterion.
     *
     * @param {Selector} item
     * @param {Selector} matching
     * @param {string[]} [selectors]    The submission step statuses to check.
     *
     * @returns {boolean}
     */
    function hasCondition(item, matching, selectors = STATUS_SELECTORS) {
        const $item = itemRow(item);
        return selectors.some(status => $item.find(status).is(matching));
    }

    /**
     * Indicate whether *all* submission steps for the item match the given
     * criterion.
     *
     * @param {Selector} item
     * @param {Selector} matching
     * @param {string[]} [selectors]    The submission step statuses to check.
     *
     * @returns {boolean}
     */
    function isExclusively(item, matching, selectors = STATUS_SELECTORS) {
        const $item = itemRow(item);
        return selectors.every(status => $item.find(status).is(matching));
    }

/*
    function isMissingFile(item, name) {
        const $item   = itemRow(item);
        const $status = $item.find(FILE_STATUS);
        if (!$status.is(FILE_MISSING)) { return false }
        if (!name)                     { return true }
        return $status.find('.name').text() === name;
    }
*/

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
     * @param {boolean}  [total]      If *true*, allow FILE_NEEDED.
     */
    function resetStatusFor(item, status, total) {
        //_debug(`resetStatusFor "${status}" for item =`, item);
        const $item    = itemRow(item);
        const $status  = $item.find(selector(status));
        const original = $status.data(SAVED_DATA);
        if (!total && (original.value === FILE_NEEDED_MARKER)) {
            //setStatusFor($item, status, NOT_STARTED_MARKER);
        } else {
            setStatusFor($item, status, original.value, original.note);
        }
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
        start:   NOT_STARTED_MARKER,    // Pseudo step (internal use only).
        data:    DATA_STATUS_CLASS,     // First true step (client-side).
        file:    FILE_STATUS_CLASS,     // Client-side file acquisition.
        upload:  UPLOAD_STATUS_CLASS,   // Client-side file upload.
        cache:   UPLOAD_STATUS_CLASS,   // Server-side upload to AWS cache.
        promote: UPLOAD_STATUS_CLASS,   // Server-side promote to AWS storage.
        index:   INDEX_STATUS_CLASS,    // Server-side index ingest.
        entry:   ENTRY_STATUS_CLASS,    // Last true step (server-side).
        end:     DONE_MARKER,           // Pseudo step (internal use only).
    };
    const ALL_SUBMIT_STEPS  = Object.keys(SUBMIT_STEP_TO_STATUS);
    const BEFORE_FIRST_STEP = ALL_SUBMIT_STEPS[0];
    const [FINAL_STEP, AFTER_FINAL_STEP] = ALL_SUBMIT_STEPS.slice(-2);

    const SUBMITTING_DATA = 'submitIds';

    /**
     * @typedef SubmissionTableEntry
     *
     * @property {string} type
     * @property {string} status
     * @property {string} [message]
     */

    /**
     * @typedef {Object.<string,SubmissionTableEntry>} SubmissionTable
     */

    /**
     * getSubmissionTable
     *
     * @returns {SubmissionTable|undefined}
     */
    function getSubmissionTable() {
        return $body.data(SUBMITTING_DATA);
    }

    /**
     * setSubmissionTable
     *
     * @param {string[]|SubmissionTable} arg
     *
     * @returns {SubmissionTable}
     */
    function setSubmissionTable(arg) {
        _debug('setSubmissionTable: arg =', arg);
        let table;
        if (isObject(arg)) {
            table = arg;
        } else {
            const ids   = uniq(arg);
            const step  = BEFORE_FIRST_STEP;
            const value = SUBMIT_STEP_TO_STATUS[step];
            table = toObject(ids, _id => ({ step, value }));
        }
        $body.data(SUBMITTING_DATA, table);
        return table;
    }

    /**
     * updateSubmissionTable
     *
     * @param {string[]|SubmissionTable} replacement
     *
     * @returns {SubmissionTable}
     */
    function updateSubmissionTable(replacement) {
        _debug('updateSubmissionTable: replacement =', replacement);
        const item_table = setSubmissionTable(replacement);
        const item_done  = (item) => (item.step === AFTER_FINAL_STEP);
        if (Object.values(item_table).every(item_done)) {
            submissionsEnded();
        }
        return item_table;
    }

    /**
     * Process a message sent back from the server as part of a bulk submission
     * sequence.
     *
     * @param {SubmitResponseSubclass} message
     */
    function onSubmissionResponse(message) {
        const func = 'onSubmissionResponse';
        _debug(`${func}: message =`, message);
        if (message.isAck) {
            onAcknowledgement(message);
        } else if (message.isInitial) {
            onInitialResponse(message);
        } else if (message.step) {
            onStepResponse(message);
        } else if (message.isIntermediate) {
            onBatchResponse(message);
        } else if (message.isFinal) {
            onFinalResponse(message);
        } else {
            console.warn(`${func}: unexpected:`, message);
        }
    }

    /**
     * Process a message indicating bulk submission command response.
     *
     * @param {SubmitResponseSubclass} message
     */
    function onAcknowledgement(message) {
        _debug('onAcknowledgement');
        if (message instanceof SubmitControlResponse) {
            const command = message.command;
            _debug('onAcknowledgement: TODO: command =', command);
        } else {
            console.warn('onAcknowledgement: UNEXPECTED:', message);
        }
    }

    /**
     * Process a response message indicating the start of a bulk submission of
     * ManifestItem entries.
     *
     * @param {SubmitResponse} message
     */
    function onInitialResponse(message) {
        const func = 'onInitialResponse'; _debug(func);
        let items  = message.items;
        // noinspection JSUnresolvedVariable
        items = items.map(v => isObject(v) ? v.items : v).flat();
        items = items.map(v => (typeof v === 'number') ? `${v}` : v);

        const table = setSubmissionTable(items);
        if (isEmpty(table)) {
            console.warn(`${func}: no items indicated:`, message);
        }

        resetItems();
        counter.failed.clear();
        counter.succeeded.clear();
        counter.transmitting.value = Object.keys(table).length;
    }

    /**
     * Process a response message indicating the success/failure of one or more
     * ManifestItem entries at the given submission step.
     *
     * @param {SubmitStepResponse} message
     */
    function onStepResponse(message) {
        const func  = 'onStepResponse'; _debug(func);
        const table = { ...getSubmissionTable() };

        if (isEmpty(table)) {
            console.warn(`${func}: ignoring late response:`, message);
            return;
        }

        const total   = message.submitted.length;
        const success = message.success;
        const failure = message.failure;
        const invalid = message.invalid;
        const step    = message.step;
        const status  = SUBMIT_STEP_TO_STATUS[step];

        const success_step = (step === FINAL_STEP) ? AFTER_FINAL_STEP : step;
        const success_stat = SUBMIT_STEP_TO_STATUS[success_step];
        for (const [id, info] of Object.entries(success)) {
            const current = table[id]; // TODO: remove
            setStatusFor(itemFor(id), status, SUCCEEDED_MARKER);
            table[id] = { step: success_step, value: success_stat };
            console.log('*** RESP STEP', success_step, 'success | id', id, '| info: ', info, '| was:', current, 'now:', table[id]); // TODO: remove
        }

        const failed = FAILED_MARKER;
        for (const [id, info] of Object.entries(failure)) {
            const current = table[id]; // TODO: remove
            const error   = htmlDecode(info.error);
            setStatusFor(itemFor(id), status, failed, error);
            table[id] = { step: step, value: failed, message: error };
            console.log('*** RESP STEP', step, 'FAILURE | id', id, '| info: ', info, '| was:', current, 'now:', table[id]); // TODO: remove
        }

        if (isPresent(invalid)) {
            console.warn(`${func}: invalid:`, invalid);
        }

        const successes = Object.keys(success).length;
        const failures  = Object.keys(failure).length;
        const count     = successes + failures + invalid.length;
        if (count !== total) {
            console.warn(`${func}: ${count} entries but ${total} submitted`);
        }

        if (successes || failures) {
            updateSubmissionTable(table);
        }
    }

    /**
     * Process a response message indicating the overall success/failure of the
     * submission of one or more ManifestItem entries, updating displayed
     * counters accordingly.
     *
     * If messages are being sent for submission steps then this function
     * won't be updating the SubmissionTable or the individual status lines
     * assuming that each associated ManifestItem has already been represented
     * in a submission step response for the final submission step.
     *
     * If submission steps are not set up to generate real-time responses then
     * batch responses would be mandatory in order to invoke this function to
     * update the status of each associated ManifestItem submission.
     *
     * @param {SubmitStepResponse} message
     */
    function onBatchResponse(message) {
        const func  = 'onBatchResponse'; _debug(func);
        const table = { ...getSubmissionTable() };

        if (isEmpty(table)) {
            console.warn(`${func}: ignoring late response:`, message);
            return;
        }

        const total     = message.submitted.length;
        const success   = message.success;
        const failure   = message.failure;
        const invalid   = message.invalid;
        const this_step = FINAL_STEP;
        const status    = SUBMIT_STEP_TO_STATUS[this_step];
        const end_step  = AFTER_FINAL_STEP;

        const succeeded = SUCCEEDED_MARKER;
        for (const [id, info] of Object.entries(success)) {
            const current = table[id] || {};
            if (current.step !== end_step) {
                setStatusFor(itemFor(id), status, succeeded);
                table[id] = { step: end_step, value: succeeded };
                console.log('*** RESP BATCH success | id', id, '| info: ', info, '| was:', current, 'now:', table[id]); // TODO: remove
            }
        }

        const failed = FAILED_MARKER;
        for (const [id, info] of Object.entries(failure)) {
            const current = table[id];
            if ((current?.step !== end_step) && (current?.value !== failed)) {
                const error = htmlDecode(info.error);
                setStatusFor(itemFor(id), status, failed, error);
                table[id] = { step: end_step, value: failed, message: error };
                console.log('*** RESP BATCH FAILURE | id', id, '| info: ', info, '| was:', current, 'now:', table[id]); // TODO: remove
            }
        }

        if (isPresent(invalid)) {
            console.warn(`${func}: invalid:`, invalid);
        }

        const successes = Object.keys(success).length;
        const failures  = Object.keys(failure).length;
        const count     = successes + failures + invalid.length;
        if (count !== total) {
            console.warn(`${func}: ${count} entries but ${total} submitted`);
        }

        if (successes || failures) {
            counter.failed.increment(failures);
            counter.succeeded.increment(successes);
            counter.transmitting.decrement(successes + failures);
            updateSubmissionTable(table);
        }
    }

    /**
     * onFinalResponse
     *
     * @param {SubmitFinalResponse} message
     */
    function onFinalResponse(message) {
        const func  = 'onFinalResponse'; _debug(func);
        const data  = message.data || {};
        const table = getSubmissionTable() || {};

        let total = 0;
        let count = 0;
        for (const [_job, job_entry] of Object.entries(data)) {
            /** @type {SubmitStepResponseData} */
            const entry    = job_entry;
            const subtotal = entry.submitted?.length || 0;
            const invalid  = entry.invalid || [];
            const success  = entry.success || {};
            const failure  = entry.failure || {};

            const succeeded = SUCCEEDED_MARKER;
            for (const [id, _info] of Object.entries(success)) {
                const was = `"${table[id]}"`;
                const now = `"${succeeded}"`;
                if (was !== now) {
                    console.warn(`${func}: ${id}: was ${was}; now ${now}`);
                }
                count++;
            }

            const failed = FAILED_MARKER;
            for (const [id, info] of Object.entries(failure)) {
                const was = `"${table[id]}"`;
                const now = `"${failed}: ${htmlDecode(info.error)}"`;
                if (was !== now) {
                    console.warn(`${func}: ${id}: was ${was}; now ${now}`);
                }
                count++;
            }

            if (isPresent(invalid)) {
                console.warn(`${func}: invalid:`, invalid);
                count += invalid.length;
            }

            total += subtotal;
        }
        if (count !== total) {
            console.warn(`${func}: ${count} entries but ${total} submitted`);
        }

        submissionsEnded();
    }

    /**
     * Called when the server does not accept the WebSocket subscription
     * attempt (probably because reauthorization is required).
     */
    function onSubmissionRejected() {
        _debug('onSubmissionRejected');
        const note = 'Refresh this page to re-authenticate.';
        flashError(`Connection error: ${note}`);
        submissionsEnded();
    }

    /**
     * Update buttons after a submission sequence has terminated.
     */
    function submissionsEnded() {
        _debug('submissionsEnded');
        submissionsActive(false);
        $start.toggleClass(BEST_CHOICE_MARKER, false);
        $monitor.toggleClass(BEST_CHOICE_MARKER, true);
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
    // Functions - uploader
    // ========================================================================

    /** @type {BulkUploader} */
    let uploader;

    /**
     * Initialize the file uploader.
     *
     * @returns {BulkUploader}
     */
    function initializeUploader() {
        return uploader ||= newUploader($local_button);
    }

    /**
     * Create a new uploader instance.
     *
     * @param {Selector} owner
     *
     * @returns {BulkUploader}
     */
    function newUploader(owner) {
        //_debug('newUploader: owner =', owner);
        // noinspection JSUnusedGlobalSymbols
        const cbs      = { onSelect, onStart, onProgress, onError, onSuccess };
        const func     = 'uploader';
        const $owner   = $(owner);
        const features = { debugging: DEBUG };
        const instance = new BulkUploader($owner, ITEM_MODEL, features, cbs);

        // noinspection JSValidateTypes
        return instance.initialize();

        /**
         * Callback invoked when the file select button is pressed.
         *
         * @param {jQuery.Event} [event]    Ignored.
         */
        function onSelect(event) {
            _debug(`${func}: onSelect: event =`, event);
            clearFlash();
        }

        /**
         * @see BaseUploader._onFileUploadStart
         *
         * @param {UppyFileUploadStartData} data
         *
         * @returns {object}          URL parameters for the remote endpoint.
         */
        function onStart(data) {
            _debug(`${func}: onStart: data =`, data);
            clearFlash();
            const item_id  = manifestItemId($owner);
            const manifest = manifestId();
            return compact({ id: item_id, manifest_id: manifest });
        }

        /**
         * @see BaseUploader._onFileUploadProgress
         *
         * @param {UppyFile}     file
         * @param {FileProgress} progress
         *
         * @returns {boolean}
         */
        function onProgress(file, progress) {
            const tag     = `${func}: onProgress`;
            const item_id = file?.meta?.manifest_item_id;
            const $item   = itemFor(item_id);
            const status  = statusFor($item, UPLOAD_STATUS);
            _debug(`${tag}: item = ${item_id} | status =`, status, '| uploadStarted =', progress.uploadStarted, '| uploadComplete =', progress.uploadComplete, '| bytesTotal = ', progress.bytesTotal, '| bytesUploaded = ', progress.bytesUploaded, '| percentage = ', progress.percentage);
            if (status === FAILED_MARKER) {
                _debug(`${tag}: CANCEL: ${item_id} | file =`, file);
                return false;
            }
            _debug(`${tag}: item = ${item_id} | file =`, file);
            if (progress.uploadStarted) {
                setStatusFor($item, UPLOAD_STATUS, ACTIVE);
            }
            return true;
        }

        /**
         * @see BaseUploader._onFileUploadError
         *
         * @param {UppyFile}                       file
         * @param {Error}                          error
         * @param {{status: number, body: string}} [response]
         */
        function onError(file, error, response) {
            const item_id = file?.meta?.manifest_item_id;
            const $item   = itemFor(item_id);
            const note    = error?.message || error;
            setStatusFor($item, UPLOAD_STATUS, FAILED, note);
            _debug(`${func}: onError: item = ${item_id} | file =`, file);
        }

        /**
         * @see BaseUploader._onFileUploadSuccess
         *
         * @param {UppyFile}            file
         * @param {UppyResponseMessage} response
         */
        function onSuccess(file, response) {
            const item_id = file?.meta?.manifest_item_id;
            const $item   = itemFor(item_id);
            setStatusFor($item, UPLOAD_STATUS, SUCCEEDED);
            _debug(`${func}: onSuccess: item = ${item_id} | file =`, file);
        }
    }

    // ========================================================================
    // Functions - file resolution - local
    // ========================================================================

    /**
     * Setup handlers for local file selection.
     */
    function initializeLocalFilesResolution() {
        _debug('initializeLocalFilesResolution');
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
     * @type {FileExt[]|undefined}
     */
    let local_file_selection;

    /**
     * Local files selected by the user.
     *
     * @returns {FileExt[]}
     */
    function localFileSelection() {
        return local_file_selection ||= [];
    }

    /**
     * Include a local file.
     *
     * @param {FileExt}       obj
     * @param {string|number} [item_id]
     */
    function addLocalFile(obj, item_id) {
        _debug(`Queueing local file "${obj.name}" for item ${item_id}`, obj);
        let file = obj;
        if (item_id) {
            file.meta ||= {}
            file.meta.manifest_item_id = item_id.toString();
        }
        localFileSelection().push(file);
        uploader.addFiles(file);
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
        _debug('beforeLocalFilesSelected: event =', event);
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
            console.warn(`${func}: no files provided`);
        } else {
            _debug(`${func}: ${files.length} files`);
            queueLocalFiles(files);
            preProcessLocalFiles();
        }
    }

    /**
     * Replace the current list of selected files.
     *
     * @param {FileExt[]|FileList} files
     */
    function queueLocalFiles(files) {
        _debug(`queueLocalFiles: ${files.length} files =`, files);
        const remaining = new Set(Object.values(files_remaining.local));
        const count     = files?.length || 0;
        let lookup      = undefined;
        for (let i = 0; i < count; i++) {
            const file  = files[i];
            const name  = file?.name;
            let item_id = file?.meta?.manifest_item_id;
            if (name && !item_id) {
                lookup ||= invert(file_references.local);
                item_id = lookup[name];
            }
            if (!name) {
                _debug(`IGNORING nameless file[${i}]:`, file);
            } else if (!item_id) {
                _debug(`IGNORING unrequested file "${name}":`, file);
            } else if (!remaining.has(name)) {
                _debug(`IGNORING already handled file "${name}":`, file);
            } else {
                addLocalFile(file, item_id);
            }
        }
    }

    /**
     * Update submission statuses and report the result of pre-processing local
     * files.
     *
     * @param {FileExt[]} [files]
     */
    function preProcessLocalFiles(files = localFileSelection()) {
        const func = 'preProcessLocalFiles';
        _debug(`${func}: ${files.length} files =`, files);
        const lines = [];
        const names = [];
        const good  = [];
        const bad   = []; // TODO: are there "badness" criteria at this stage?
        const pairs = {};
        files.forEach(file => {
            const id   = file.meta.manifest_item_id;
            const name = file.name;
            const size = file.size;
            const line = `${id} : ${name} : ${size} bytes`;
            if (remove(files_remaining.local, id)) {
                pairs[id] = file;
                _debug(`${func}: ${line}`);
            } else {
                _debug(`${func}: ${line} -- ALREADY PROCESSED`);
            }
            names.push(name);
            good.push(line);
        });
        const resolved    = good.length;
        const problematic = bad.length;
        const remaining   = files_remaining.local.length;

        if (resolved) {
            let sel_changed = false;
            const fulfilled = new Set(names);
            const status    = FILE_STATUS;
            allItems().each((_, item) => {
                const $item   = $(item);
                const $status = $item.find(status);
                const needed  = $status.is(FILE_NEEDED);
                const name    = needed && $status.find('.name').text();
                if (name && fulfilled.has(name)) {
                    setStatusFor($item, status, SUCCEEDED);
                    sel_changed = updateItemSelect($item) || sel_changed;
                }
            });
            if (sel_changed) {
                updateGroupSelect();
            }
            lines.push(resolvedLabel(resolved), ...good, '');
            sendFileSizes(pairs);
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
     * Add file size to the :file_data column value of each item.
     *
     * @param {Object.<string,File>} pairs
     */
    function sendFileSizes(pairs) {
        const items = {};
        Object.entries(pairs).forEach(([id,file]) => {
            items[id] = { file_data: { name: file.name, size: file.size } };
        });
        sendFieldUpdates(items);
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
            submittable = `${count} ${items} READY FOR UPLOAD`;
        } else {
            const items = (total > 1) ? 'ITEMS'   : 'ITEM';
            const need  = (total > 1) ? 'REQUIRE' : 'REQUIRES';
            submittable = `${items} STILL ${need} ATTENTION`;
        }
        return `ALL FILES RESOLVED - ${submittable}`;
    }

    // ========================================================================
    // Functions - file resolution - remote
    // ========================================================================

    /**
     * Setup for acquiring files from cloud-based storage.
     */
    function initializeRemoteFilesResolution() {
        const func = 'initializeRemoteFilesResolution'; _debug(func);
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
     * @type {string[]|undefined}
     */
    let remote_file_selection;

    /**
     * Remote files selected by the user.
     *
     * @returns {string[]}
     */
    function remoteFileSelection() {
        return remote_file_selection ||= [];
    }

    /**
     * Include a remote file.
     *
     * @param {string}        obj
     * @param {string|number} [item_id]
     */
    function addRemoteFile(obj, item_id) {
        _debug(`Queueing remote file "${obj}" for item ${item_id}:`, obj);
        let file = obj;
/*
        if (item_id) {
            file.meta ||= {}
            file.meta.manifest_item_id = item_id.toString();
        }
*/
        remoteFileSelection().push(file);
/*
        uploader.addFiles(file);
*/
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
        const func = 'afterRemoteFilesSelected';
        const urls = []; // event.currentTarget?.files || event.target?.files;
        //_debug(`*** ${func}: event =`, event);
        if (!urls) {
            console.warn(`${func}: no event target`);
        } else if (isEmpty(urls)) {
            console.warn(`${func}: no URLs provided`);
        } else {
            _debug(`${func}: ${urls.length} URLs`);
            queueRemoteFiles(urls);
            preProcessRemoteFiles();
        }
    }

    /**
     * Replace the current list of selected files.
     *
     * @param {string[]} urls
     */
    function queueRemoteFiles(urls) {
        _debug(`queueRemoteFiles: ${urls.length} URLs =`, urls);
        const remaining = new Set(Object.values(files_remaining.remote));
        const count     = urls?.length || 0;
        let lookup      = undefined;
        for (let i = 0; i < count; i++) {
            const url   = urls[i];
            const name  = url;       // url?.name;
            let item_id = undefined; // url?.meta?.manifest_item_id;
            if (name && !item_id) {
                lookup ||= invert(file_references.remote);
                item_id = lookup[name];
            }
            if (!name) {
                _debug(`IGNORING nameless url[${i}]:`, url);
            } else if (!item_id) {
                _debug(`IGNORING unrequested URL "${name}":`, url);
            } else if (!remaining.has(name)) {
                _debug(`IGNORING already handled URL "${name}":`, url);
            } else {
                addRemoteFile(url, item_id);
            }
        }
    }

    /**
     * Update submission statuses and report the result of pre-processing
     * remote files.
     *
     * @param {string[]} [urls]
     */
    function preProcessRemoteFiles(urls = remoteFileSelection()) {
        const func = 'preProcessRemoteFiles';
        _debug(`${func}: ${urls.length} URLs =`, urls);
        const lines = [];
        const names = [];
        const good  = [];
        const bad   = []; // TODO: are there "badness" criteria at this stage?
        urls.forEach(url => {
            const id   = 0;   // url.meta.manifest_item_id;
            const name = url; // url.name;
            const line = `${id} : ${name}`;
            if (remove(files_remaining.remote, id)) {
                _debug(`${func}: ${line}`);
            } else {
                _debug(`${func}: ${line} -- ALREADY PROCESSED`);
            }
            names.push(name);
            good.push(line);
        });
        files_remaining.remote = []; // NOTE: simulate all resolved
        const resolved    = good.length;
        const problematic = bad.length;
        const remaining   = files_remaining.remote.length;

        if (resolved) {
            let sel_changed = false;
            const fulfilled = new Set(names);
            const status    = FILE_STATUS;
            allItems().each((_, item) => {
                const $item   = $(item);
                const $status = $item.find(status);
                const needed  = $status.is(FILE_NEEDED);
                const name    = needed && $status.find('.name').text();
                if (name && (fulfilled.has(name) || name.startsWith('http'))) {
                    setStatusFor($item, status, SUCCEEDED);
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
    // Functions - page - server interface
    // ========================================================================

    /**
     * Update field(s) of multiple ManifestItem records.
     *
     * @param {object|string} items
     * @param {object}        [opt]
     *
     * @see "ManifestItemController#bulk_fields"
     */
    function sendFieldUpdates(items, opt = {}) {
        const func     = opt?.caller || 'sendFieldUpdates';
        const manifest = manifestId();
        const method   = 'PUT';
        const action   = `bulk/fields/${manifest}`;
        const content  = 'multipart/form-data';
        const accept   = 'text/html';
        _debug(`${func}: items =`, items);

        if (!manifest) {
            _error(`${func}: no manifest ID`);
            return;
        }

        const hdr = opt?.headers;
        if (hdr) { delete opt.headers }
        const prm = opt?.params || opt;

        serverSend(action, {
            caller:  func,
            method:  method,
            params:  { data: items, ...prm },
            headers: { 'Content-Type': content, Accept: accept, ...hdr },
        });
    }

    // ========================================================================
    // Functions - database - ManifestItem
    // ========================================================================

    /**
     * The database ID for the ManifestItem associated with the target.
     *
     * @param {Selector} item
     *
     * @returns {number|undefined}
     */
    function manifestItemId(item) {
        const value = itemRow(item).attr(ITEM_ATTR);
        return Number(value) || undefined;
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
