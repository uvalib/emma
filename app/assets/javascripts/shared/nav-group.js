// app/assets/javascripts/shared/nav-group.js
// noinspection FunctionNamingConventionJS


import { AppDebug }                            from '../application/debug';
import { Emma }                                from './assets';
import { BaseClass }                           from './base-class';
import { attributeSelector, HIDDEN, selector } from './css';
import { handleCapture, handleEvent, phase }   from './events';
import { ValidationError }                     from './exceptions';
import { keyCombo, keyFormat, modifiersOnly }  from './keyboard';
import { underscore }                          from './strings';
import {
    FOCUSABLE_ELEMENT,
    getCurrentFocusables,
    getMaybeFocusables,
    maybeFocusable,
    neutralizeFocusables,
    nextInTabOrder,
    prevInTabOrder,
    restoreFocusables,
    setFocusable,
} from './accessibility';
import {
    isDefined,
    isEmpty,
    isMissing,
    isPresent,
    notDefined,
    presence,
} from './definitions';
import {
    CHECKBOX,
    RADIO,
    containedBy,
    contains,
    sameElements,
    selfAndDescendents,
    selfOrDescendents,
    selfOrParent,
    single,
} from './html';


const MODULE = 'NavGroup';
const DEBUG  = true;

AppDebug.file('shared/nav-group', MODULE, DEBUG);

// ============================================================================
// Constants
// ============================================================================

export const NAV_GROUP_DATA  = 'navGroupInstance';
export const NAV_FOCUS_DATA  = 'navGroupFocus';

export const CB_ENTRY        = 'li[role="option"]';

export const CB_GROUP        = 'ul[role="listbox"]';
export const RADIO_GROUP     = 'fieldset[role="radiogroup"]';
export const TEXT_GROUP      = 'fieldset:not([role="radiogroup"])';
export const LIST_GROUP      = `${CB_GROUP}, ${RADIO_GROUP}, ${TEXT_GROUP}`;
export const CONTROL_GROUP   = '.control-group';
export const MENU_GROUP      = CONTROL_GROUP;
export const SINGLETON_GROUP = CONTROL_GROUP;
export const NAV_GROUP       = `${LIST_GROUP}, ${CONTROL_GROUP}`;

export const TEXT_INPUT      = '[type="text"], [role="textbox"], textarea';
export const LIST_INPUT      = [CHECKBOX, RADIO, TEXT_INPUT].join(', ');
export const CONTROL_INPUT   = `${FOCUSABLE_ELEMENT}, [tabindex]`;
export const MENU_INPUT      = 'select';
export const SINGLETON_INPUT = CONTROL_INPUT;
export const NAV_INPUT       = CONTROL_INPUT;

// ============================================================================
// Classes
// ============================================================================

/**
 * Base class for groupings of controls for accessibility.
 *
 * @abstract
 * @extends BaseClass
 */
export class NavGroup extends BaseClass {

    static CLASS_NAME = 'NavGroup';
    static DEBUGGING  = DEBUG;
    static DEBUG_CTOR = false;

    // ========================================================================
    // Constants
    // ========================================================================

    static GROUP        = NAV_GROUP;
    static CONTROL      = NAV_INPUT;
    static START_ACTIVE = false;
    static WRAP_MOVE    = false;
    static SET_TABINDEX = true;
    static CURRENT_ATTR = 'aria-current';
    static PRUNE_AT     = [HIDDEN];
    static MODAL_ROOT   = selector(Emma.Popup.panel.class);

    // ========================================================================
    // Type definitions
    // ========================================================================

    /**
     * @typedef {object} NavGroupCallbackOptions
     *
     * @property {jQuery} container
     * @property {jQuery} group
     * @property {jQuery} [control]
     */

    /**
     * @typedef {function(NavGroupCallbackOptions) : boolean} NavGroupCallback
     */

    /**
     * @typedef {object} NavGroupControlType
     *
     * @property {boolean} [link]       is `<a>`. <p/>
     * @property {boolean} [details]    is `<details>`. <p/>
     * @property {boolean} [select]     is `<select>`. <p/>
     * @property {boolean} [button]     has a button role. <p/>
     * @property {boolean} [check]      is a checkbox. <p/>
     * @property {boolean} [radio]      is a radio button. <p/>
     * @property {boolean} [text]       is `<textarea>` or [type="text"]. <p/>
     * @property {boolean} [input]      is a generic input. <p/>
     */

    // ========================================================================
    // Variables
    // ========================================================================

    /** @type {jQuery}  */ _container;
    /** @type {jQuery}  */ _group;
    /** @type {jQuery}  */ _controls;
    /** @type {jQuery}  */ _entries;
    /** @type {boolean} */ _active;
    /** @type {boolean} */ _standalone;

    /** @type {Object.<string,NavGroupCallback[]>} */ _callbacks = {};

    // ========================================================================
    // Constructor
    // ========================================================================

    /**
     * Create a new instance.
     *
     * @param {Selector} group
     * @param {Selector} [container]
     * @param {boolean}  [standalone]
     */
    constructor(group, container, standalone) {
        super();
        this.group     = group;
        this.container = container;
        if (!this._validate()) {
            return;
        }
        if (isDefined(standalone)) {
            this._standalone = standalone;
        } else if (container) {
            this._standalone = !this._isGridCell(this.container);
        } else {
            this._standalone = !this._insideGridCell(this.group);
        }
        if (this.constructor.START_ACTIVE) {
            this._enterNavigation(false);
        } else {
            this._leaveNavigation(false);
        }
        this._groupEventHandlers();
        this._controlEventHandlers();
    }

    // ========================================================================
    // Properties
    // ========================================================================

    get GROUP()             { return this.constructor.GROUP }
    get CONTROL()           { return this.constructor.CONTROL }
    get WRAP_MOVE()         { return this.constructor.WRAP_MOVE }
    get SET_TABINDEX()      { return this.constructor.SET_TABINDEX }
    get CURRENT_ATTR()      { return this.constructor.CURRENT_ATTR }
    get MODAL_ROOT()        { return this.constructor.MODAL_ROOT }
    get typeDesc()          { return this.constructor.typeDesc }

    get active()            { return this._active }
    get group()             { return this._group }
    set group(el)           { this._group = $(el) }
    get container()         { return this._getContainer() }
    set container(el)       { this._setContainer(el) }

    get controls()          { return this._controls ||= this._getControls() }
    get entries()           { return this._entries  ||= this._getEntries() }
    get activeControls()    { return getCurrentFocusables(this.controls) }
    get activeEntries()     { return this._getEntries(this.activeControls) }

    get currentControl()    { return this.control(this.currentEntry) }
    get currentEntry()      { return this.activeEntries.filter(this._current) }

    get standalone()        { return this._standalone }

    // ========================================================================
    // Properties - controls
    // ========================================================================

    /**
     * The control which has focus.
     *
     * @returns {jQuery|undefined}
     */
    get focusControl() {
        return this._getFocusControl();
    }

    set focusControl(ctrl) {
        this._setFocusControl(ctrl);
    }

    /**
     * The entry which has focus or contains a control which has focus.
     *
     * @returns {jQuery|undefined}
     */
    get focusEntry() {
        return this.entry(this.focusControl);
    }

    // ========================================================================
    // Properties - internal
    // ========================================================================

    get _current() { return this.constructor._current }

    // ========================================================================
    // Methods - validation
    // ========================================================================

    /**
     * Determine whether a valid instance can be created.
     *
     * @param {boolean} [no_throw]
     *
     * @returns {boolean}             **false** if there was an error.
     * @protected
     */
    _validate(no_throw) {
        let msg;
        if (!this.isGroup(this.group)) {
            msg = [`not a valid ${this.typeDesc}`, this.group];
        } else if (isMissing(this.group)) {
            msg = ['empty group', this.group];
        }
        return !this._validationError(msg, no_throw);
    }

    /**
     * Conditionally throw a ValidationError.
     *
     * @param {array|undefined} parts
     * @param {boolean}         [no_throw]
     *
     * @returns {boolean}             **true** if there was an error.
     * @protected
     */
    _validationError(parts, no_throw) {
        if (isEmpty(parts)) { return false }
        this._clearInstance();
        if (!no_throw) { this._throwValidationError(parts) }
        this._error(parts);
        return true;
    }

    _throwValidationError(...args) {
        throw new ValidationError(...this._prefix(...args));
    }

    // ========================================================================
    // Methods - group events
    // ========================================================================

    _groupEventHandlers(group) {
        const $e = group ? $(group) : this.group;
        //this._debug('_groupEventHandlers:', $e);
        this._handleEvent(  $e, 'focus',   this._groupFocus);
        this._handleEvent(  $e, 'blur',    this._groupBlur);
        this._handleCapture($e, 'click',   this._groupClickCapture);
        this._handleCapture($e, 'keydown', this._groupKeydownCapture);
    }

    /**
     * Respond to the group element gaining focus.
     *
     * @param {jQuery.Event|FocusEvent} event
     */
    _groupFocus(event) {
        const func   = '_groupFocus';
        const enter  = event.currentTarget;
        const leave  = event.relatedTarget;
        const $other = leave && this.constructor.group(leave);

        let leaving_other, leaving_ctrl;
        if (!leave) {
            // ?
        } else if (!sameElements(this.group, $other)) {
            leaving_other = true;
        } else if (!sameElements(enter, leave)) {
            leaving_ctrl  = true;
        }

        if (this._debugging) {
            /** @type {*[]} */
            const msg = [`${func}: old focus:`];
            switch (true) {
                case !leave:        msg.push('outside of');         break;
                case leaving_other: msg.push($other, 'outside of'); break;
                case leaving_ctrl:  msg.push(leave,  'was inside');  break;
                default:            msg.push(leave,  'was outside'); break;
            }
            this._debug(...msg, 'group =', this.group, 'event =', event);
        }

        if (!this.active) {
            this.activate();
        }
    }

    /**
     * Respond to the group element losing focus.
     *
     * @param {jQuery.Event|FocusEvent} event
     */
    _groupBlur(event) {
        const func   = '_groupBlur';
        const enter  = event.relatedTarget;
        const $other = enter && this.constructor.group(enter);

        let leaving_group, entering_ctrl;
        if (!enter) {
            leaving_group = true;
        } else if (!sameElements(this.group, $other)) {
            leaving_group = true;
        } else {
            entering_ctrl = true;
        }

        if (this._debugging) {
            /** @type {*[]} */
            const msg = [`${func}: new focus:`];
            switch (true) {
                case !enter:        msg.push('outside of');         break;
                case leaving_group: msg.push($other, 'outside of'); break;
                case entering_ctrl: msg.push(enter,  'inside');     break;
                default:            msg.push(enter,  'outside of'); break;
            }
            this._debug(...msg, 'group =', this.group, 'event =', event);
        }

        if (leaving_group && this.active) {
            this.deactivate();
        }
    }

    /**
     * Respond to a mouse click in a control or anywhere within the group.
     *
     * @param {jQuery.Event|MouseEvent} event
     *
     * @returns {EventHandlerReturn}
     */
    _groupClickCapture(event) {
        const func  = '_groupClickCapture';
        const debug = this.debugging;
        const {
            $tgt,
            $entry,
            $control,
            $target,
            $focus,
            to_entry,
            to_ctrl,
            in_modal,
        } = this._analyzeGroupEvent(func, event);

        if (debug) {
            const msg = [];
            switch (true) {
                case in_modal:  msg.push('to modal',        $tgt);      break;
                case to_entry:  msg.push('to $entry',       $entry);    break;
                case to_ctrl:   msg.push('to $control',     $control);  break;
                case !!$focus:  msg.push('redirect to',     $focus);    break;
                case !!$target: msg.push('unexpected',      $target);   break;
                default:        msg.push('non-focusable',   $tgt);      break;
            }
            this._debug(`${func}:`, ...msg, 'event =', event);
        }

        let handled, $ctrl;
        if ($focus) {
            $focus.click();
            handled = true;
        } else if (to_entry && ($ctrl = this._getControls($entry))) {
            $ctrl.click();
            handled = true;
        }

        if (handled) { event.stopPropagation() }
        if (handled) { event.preventDefault()  }

        !in_modal && debug && this._logGroupEventEnd(event, undefined, func);
    }

    // noinspection FunctionTooLongJS
    /**
     * Handle keyboard navigation within the group or allow the event to pass
     * to the destination.
     *
     * @param {jQuery.Event|KeyboardEvent} event
     *
     * @returns {EventHandlerReturn}
     */
    _groupKeydownCapture(event) {
        const func  = '_groupKeydownCapture';
        const debug = this.debugging;
        const key   = keyCombo(event);
        if (!key) { return this._warn(`${func}: not a KeyboardEvent`, event) }
        if (modifiersOnly(key)) { return } // Avoid excess console logging.

        const {
            $tgt,
            $group,
            $entry,
            $control,
            $target,
            to_entry,
            to_ctrl,
            in_modal,
        } = this._analyzeGroupEvent(func, event);

        const $ctrl    = $entry ? this._getControls($entry) : $control;
        const category = this._controlCategory($ctrl);
        const active   = this.active;

        let enter, leave, move, tab_fwd, tab_rev, handled;
        if (in_modal) {
            // Event for an element which is inside the group element but is
            // not a group control (e.g. focusables in a popup modal dialog).
        } else if (this.standalone) {
            // If not in a grid cell, allow the default tab behavior to move
            // outside the group to a neighboring focusable element.
            switch (key) {
                case 'Enter':     break; // Propagate to the control.
                case 'Escape':    break; // Propagate to the control.
                case 'Tab':       handled = tab_fwd = true; break;
                case 'Shift+Tab': handled = tab_rev = true; break;
                default:          handled = move    = this.handle(key, $ctrl);
            }
        } else if (active && category.text) {
            // Event for a text control within the nav group.
            handled = leave = (key === 'Escape');
        } else if (active) {
            // Event for a control within the nav group.
            switch (key) {
                case 'Enter':  break; // Propagate to the control.
                case 'Escape': handled = leave = true; break;
                default:       handled = move  = this.handle(key, $ctrl);
            }
        } else if (key !== 'Escape') {
            enter   = (key === 'F2') || (key === 'Enter');
            handled = this.handle(key, $ctrl);
        }

        if (debug) {
            const msg = keyFormat(`${func}: key`, key);
            switch (true) {
                case !!tab_fwd: msg.push('LEAVE TO NEXT FOCUSABLE');     break;
                case !!tab_rev: msg.push('LEAVE TO PREV FOCUSABLE');     break;
                case !!enter:   msg.push('ENTER');                       break;
                case !!leave:   msg.push('LEAVE');                       break;
                case !!move:    msg.push('MOVED WITHIN');                break;
                case !!handled: msg.push('WITHIN');                      break;
                case to_entry:  msg.push('to $entry',    $entry,  'in'); break;
                case to_ctrl:   msg.push('to $control',  $control,'in'); break;
                case !!$target: msg.push('unexpected',   $target, 'in'); break;
                default:        msg.push('non-focusable',$tgt,    'in'); break;
            }
            msg.push(active ? 'active' : 'inactive');
            this._debug(...msg, '$group =', $group, 'event =', event);
        }

        if (leave && this.active) {
            this.deactivate();
        } else if (tab_fwd) {
            this._nextNeighbor();
        } else if (tab_rev) {
            this._prevNeighbor();
        }

        if (handled) { event.stopPropagation() }
        if (handled) { event.preventDefault()  }

        !in_modal && debug && this._logGroupEventEnd(event, key, func);
    }

    // ========================================================================
    // Methods - control events
    // ========================================================================

    _controlEventHandlers(controls) {
        const $e = controls ? $(controls) : this.controls;
        //this._debug('_controlEventHandlers:', $e);
        this._handleEvent(  $e, 'focus',   this._controlFocus);
        this._handleEvent(  $e, 'blur',    this._controlBlur);
        this._handleEvent(  $e, 'click',   this._controlClick);
        this._handleCapture($e, 'keydown', this._controlKeydownCapture);
    }

    /**
     * Respond to a control within the group gaining focus.
     *
     * @param {jQuery.Event|FocusEvent} event
     */
    _controlFocus(event) {
        const func     = '_controlFocus';
        const enter    = event.currentTarget;
        const leave    = event.relatedTarget;
        const $group   = this.group;
        const to_group = leave && sameElements($group, leave);
        const in_group = leave && !to_group && isPresent($group.has(leave));

        let entering_group;
        if (leave && !to_group && !in_group) {
            entering_group = true;
        }

        if (this._debugging) {
            const msg = [];
            if (entering_group) {
                msg.push('ENTERING NAV GROUP FROM', leave);
            }
            this._debug(`${func}:`, ...msg, 'event =', event);
        }

        if (entering_group && !this.active) {
            this.activate();
        }
        this._setFocusControl(enter);
    }

    /**
     * Respond to a control within the group losing focus.
     *
     * @param {jQuery.Event|FocusEvent} event
     */
    _controlBlur(event) {
        const func     = '_controlBlur';
        const enter    = event.relatedTarget;
        const $group   = this.group;
        const to_group = enter && sameElements($group, enter);
        const in_group = enter && !to_group && isPresent($group.has(enter));

        let leaving_group;
        if (enter && !to_group && !in_group) {
            leaving_group = true;
        }

        if (this._debugging) {
            const msg = [];
            if (leaving_group) {
                msg.push('LEAVING NAV GROUP TO', enter);
            }
            this._debug(`${func}:`, ...msg, 'event =', event);
        }

        if (leaving_group && this.active) {
            this.deactivate();
        }
        this._clearFocusControl();
    }

    /**
     * Respond to a control within the group receiving a mouse click.
     *
     * @param {jQuery.Event|MouseEvent} event
     *
     * @returns {EventHandlerReturn}
     */
    _controlClick(event) {
        const func     = '_controlClick'; this._debug(`${func}:`, event);
        const $control = $(event.currentTarget || event.target);
        const category = this._controlCategory($control);
        const type     = Object.keys(category).join(',') || 'EMPTY';

        if (!this._updateItem($control)) {
            return this._warn(`${func}: empty control: event =`, event);
        }
        this._debug(`${func}: ${type}:`, $control, 'event =', event);

        let sp; // Stop propagation.
        let pd; // Prevent default.
        if (category.button) {
            sp = pd = this.activate($control);
        } else if (category.select) {
            sp = this.activate($control);
        } else if (category.details) {
            // Allow default click behavior.
        }

        if (sp) { event.stopPropagation() }
        if (pd) { event.preventDefault() }
    }

    // noinspection FunctionTooLongJS
    /**
     * Detect keyboard activity on a control.
     *
     * @param {jQuery.Event|KeyboardEvent} event
     *
     * @returns {EventHandlerReturn}
     */
    _controlKeydownCapture(event) {
        const func  = '_controlKeydownCapture';
        const debug = this.debugging;
        const key   = keyCombo(event);
        if (!key) { return this._warn(`${func}: not a KeyboardEvent`, event) }
        if (modifiersOnly(key)) { return } // Avoid excess console logging.

        const $tgt     = $(event.target);
        const $control = $(event.currentTarget);
        const to_ctrl  = sameElements($tgt, $control);
        const category = to_ctrl ? this._controlCategory($control) : {};

        if (debug) { // TODO: remove; testing
            const msg = keyFormat(`${func}: key`, key);
            this._debug(`*** ${''.padEnd(72,'v')} ***`);
            this._debug(...msg, 'eventPhase       =', phase(event));
            this._debug(...msg, 'cancelable       =', event.cancelable);
            this._debug(...msg, 'defaultPrevented =', event.defaultPrevented);
            this._debug(...msg, 'this     =', this);
            this._debug(...msg, '$tgt     =', $tgt);
            this._debug(...msg, '$control =', $control);
            this._debug(...msg, 'category =', category);
        }

        if (debug) {
            const msg = keyFormat(`${func}: key`, key);
            switch (true) {
                case to_ctrl: msg.push('to $control =', $control);  break;
                default:      msg.push('to unexpected', $tgt);      break;
            }
            this._debug(`${func}:`, ...msg, 'event =', event);
        }

        let tab_fwd; // Leave standalone nav group.
        let tab_rev; // Leave standalone nav group.
        let press;   // Activate button-like control.
        let toggle;  // Toggle `<details>`.
        let stop;    // Stop propagation.
        let prevent; // Prevent default.
        switch (key) {
            case 'Tab':
                tab_fwd = this.standalone;
                break;
            case 'Shift+Tab':
                tab_rev = this.standalone;
                break;
            case ' ':
                stop    = category.check || category.radio;
                toggle  = category.details;
                break;
            case 'Enter':
                press   = category.button || category.select;
                toggle  = category.details;
                break;
            case 'Escape':
                break;
            default:
                stop    = !category.text;
                break;
        }

        if (press) {
            stop = this.activate($control);
            if (category.button) { prevent = stop }
        } else if (toggle) {
            stop = prevent = true;
            $control[0].open = !$control[0].open;
        } else if (tab_fwd) {
            stop = prevent = true;
            this._nextNeighbor();
        } else if (tab_rev) {
            stop = prevent = true;
            this._prevNeighbor();
        }

        if (stop)    { event.stopPropagation() }
        if (prevent) { event.preventDefault() }

        debug && this._logGroupEventEnd(event, key, func);
    }

    // ========================================================================
    // Methods - events
    // ========================================================================

    /**
     * @typedef {object} NavGroupEventProperties
     *
     * @property {jQuery}   $tgt
     * @property {jQuery}   $curr
     * @property {jQuery}   $group
     * @property {jQuery}   [$entry]
     * @property {jQuery}   [$control]
     * @property {jQuery}   [$target]
     * @property {jQuery}   [$focus]
     * @property {boolean}  to_group
     * @property {boolean}  to_entry
     * @property {boolean}  to_ctrl
     * @property {boolean}  in_modal
     * @property {boolean}  in_group
     */

    /** @type {NavGroupEventProperties} */
    static _TEMPLATE = Object.freeze({
        $tgt:       undefined,
        $curr:      undefined,
        $group:     undefined,
        $entry:     undefined,
        $control:   undefined,
        $target:    undefined,
        $focus:     undefined,
        to_group:   undefined,
        to_entry:   undefined,
        to_ctrl:    undefined,
        in_modal:   undefined,
        in_group:   undefined,
    });

    /**
     * The {@link NavGroupEventProperties} keys which represent mutually
     * exclusive identification properties.
     *
     * @type {Set<string>}
     */
    static _FLAGS = Object.freeze(
        new Set(Object.keys(this._TEMPLATE).filter(k => k.match(/^(to_|in_)/)))
    );

    /**
     * Derive values and logical properties from the event which express the
     * relationships between the event target and the group components.
     *
     * @param {string}             func
     * @param {jQuery.Event|Event} event
     * @param {string}             [key]
     * @param {boolean}            [validate]
     *
     * @returns {NavGroupEventProperties}
     */
    _analyzeGroupEvent(func, event, key, validate) {
        /** @type {jQuery} */
        const $tgt     = $(event.target),
              $curr    = $(event.currentTarget);

        const $group   = this.group;
        const to_group = sameElements($tgt, $group);
        const inside   = !to_group;

        const $control = this.testControl($tgt);
        const to_ctrl  = !!$control;
        const $entry   = !$control && this.testEntry($tgt);
        const to_entry = !!$entry;
        const to_other = inside    && !to_ctrl && !to_entry;
        const $target  = to_other  && maybeFocusable($tgt) && $tgt || undefined

        const in_modal = !!$target && !to_ctrl && !to_entry;
        const in_group = !in_modal && to_other && contains($group, $tgt);
        const $focus   = !in_modal && to_other && this.focusControl;

        const result = {
            $tgt,
            $curr,
            $group,
            $entry,
            $control,
            $target,
            $focus,
            to_group,
            to_entry,
            to_ctrl,
            in_modal,
            in_group,
        };
        if (!in_modal && this._debugging) {
            this._logGroupEventAnalysis(result, event, key, func);
        }
        if (validate || this._debugging) {
            this._validateGroupEventAnalysis(result, func);
        }
        return result;
    }

    /**
     * Report on inconsistencies in the event analysis. <p/>
     *
     * (This should never need to be executed under normal circumstances since
     * it reports on programming errors that should be fixed before release.)
     *
     * @param {NavGroupEventProperties} result
     * @param {string}                  [caller]
     *
     * @returns {boolean}                 **true** if there were no problems.
     */
    _validateGroupEventAnalysis(result, caller) {
        const err = [];

        // Verify that exactly one condition flag is true.
        const flags = [];
        for (const [k, v] of Object.entries(result)) {
            if (v && this.constructor._FLAGS.has(k)) { flags.push(k) }
        }
        if (flags.length < 1) {
            err.push(['no condition flag was set']);
        } else if (flags.length > 1) {
            err.push(['only one should be true:', flags]);
        }

        // Verify that `in_modal` is appropriate.
        const { $tgt, in_modal } = result;
        const inside = containedBy($tgt, this.MODAL_ROOT);
        if (in_modal && !inside) {
            err.push(['not in modal as expected:', $tgt]);
        } else if (inside && !in_modal) {
            err.push(['unexpectedly in modal:', $tgt]);
        }

        // Report error(s) to the console.
        if (isPresent(err)) {
            const func = caller || '_validateGroupEventAnalysis';
            err.forEach(line => this._error(`${func}:`, ...line));
            return false;
        }
        return true;
    }

    /**
     * Detailed console output of an event analysis.
     *
     * @param {NavGroupEventProperties} result
     * @param {jQuery.Event|Event}      event
     * @param {string}                  [key]
     * @param {string}                  [caller]
     */
    _logGroupEventAnalysis(result, event, key, caller) {
        const func = caller || '_logGroupEventAnalysis';
        const msg  = key ? keyFormat(`${func}: key`, key) : [`${func}:`];
        const prop = {
            eventPhase:       phase(event),
            cancelable:       event.cancelable,
            defaultPrevented: event.defaultPrevented,
        };
        const log_values = (obj) => {
            const width = Math.max(...Object.keys(obj).map(k => k.length));
            for (const [k, v] of Object.entries(obj)) {
                this._debug(...msg, `${k.padEnd(width)} =`, v);
            }
        }
        this._debug(`*** ${''.padEnd(72,'v')} ***`);
        log_values(prop);
        log_values(result);
    }

    /**
     * Detailed console output for the end of handling of an event.
     *
     * @param {jQuery.Event|Event}  event
     * @param {string}              [key]
     * @param {string}              [caller]
     */
    _logGroupEventEnd(event, key, caller) {
        const func = caller || '_logGroupEventEnd';
        const msg  = key ? keyFormat(`${func}: key`, key) : [`${func}:`];
        this._debug(...msg, 'defaultPrevented ->', event.defaultPrevented);
        this._debug(`*** ${''.padEnd(72,'^')} ***`);
    }

    /**
     * Set a class instance method as an event handler.
     *
     * @param {Selector}           element
     * @param {string}             name         Event name.
     * @param {jQueryEventHandler} method       Event handler method.
     *
     * @returns {jQuery}
     * @protected
     */
    _handleEvent(element, name, method) {
        return handleEvent(element, name, method.bind(this));
    }

    /**
     * Set an event handler for the capturing phase. <p/>
     *
     * If *options* includes "{listen: false}" then the only action is to
     * remove a previous event handler.
     *
     * @param {Selector}                           element
     * @param {string}                             name        Event name.
     * @param {EventListenerOrEventListenerObject} method
     * @param {EventListenerOptionsExt|boolean}    [options]
     *
     * @protected
     */
    _handleCapture(element, name, method, options) {
        handleCapture(element, name, method.bind(this), options);
    }

    // ========================================================================
    // Methods - internal
    // ========================================================================

    _getContainer() {
        return this._container || this._setContainer();
    }

    _setContainer(element) {
        const func     = '_setContainer';
        const $current = this._container;
        const $element = element ? $(element) : this.group;
        if (isEmpty($element)) {
            this._error(`${func}: empty container: no change`);
        } else if ($current && sameElements($element, $current)) {
            this._warn(`${func}: same container: no change`);
        } else {
            this._debug(`${func}:`, $element);
            this._clearInstance();
            this._container = $element;
            this._setInstance(this);
        }
        return this._container;
    }

    _getInstance() {
        return this.container.data(NAV_GROUP_DATA);
    }

    _setInstance(value) {
        if (this._debugging) {
            const func = '_setInstance';
            const curr = this._getInstance();
            if (curr && (curr !== value)) {
                this._error(`set data(${NAV_GROUP_DATA})`, curr, '!==', value);
            } else {
                this._debug(`${func}:`, value);
            }
        }
        this.container.data(NAV_GROUP_DATA, value);
    }

    _clearInstance() {
        if (this._container) {
            this._debug('_clearInstance');
            this._container.removeData(NAV_GROUP_DATA);
        }
    }

    _isGridCell(item) {
        return this.constructor._isGridCell(item);
    }

    _insideGridCell(item) {
        return this.constructor._insideGridCell(item);
    }

    /** @returns {jQuery} */
    _single(item, caller) {
        return this.constructor._single(item, caller);
    }

    /** @returns {jQuery} */
    _selfOrParent(item, match, caller) {
        return this.constructor._selfOrParent(item, match, caller);
    }

    // ========================================================================
    // Methods
    // ========================================================================

    /**
     * Indicate whether *item* is a valid group element.
     *
     * @param {Selector|undefined} item
     *
     * @returns {boolean}
     */
    isGroup(item) {
        return this.constructor.isGroup(item);
    }

    /**
     * Add one or more callbacks for the indicated event type.
     *
     * @param {string}      type
     * @param {...function} callback
     *
     * @returns {NavGroup}
     */
    addCallback(type, ...callback) {
        this._callbacks[type] ||= [];
        this._callbacks[type].push(...callback);
        this._debug(`addCallback: ${type}:`, this._callbacks[type]);
        return this;
    }

    clearCallback(type) {
        if (type) {
            delete this._callbacks[type];
        } else {
            this._callbacks = {};
        }
    }

    clickedInside() {
        this._debug('clickedInside');
        return this.activate(null);
    }

    // ========================================================================
    // Methods - internal
    // ========================================================================

    /**
     * Indicate group navigation is in effect by marking the DOM element.
     *
     * @param {boolean} [announce]    Silent if **false**.
     */
    _enterNavigation(announce) {
        const func = '_enterNavigation';
        const log  = (announce !== false);
        if (log)               { this._debug(func) }
        if (this.SET_TABINDEX) { this._restoreControls() }
        if (this.standalone)   { setFocusable(this.group, false, func) }
        this._active = true;
    }

    /**
     * Indicate group navigation is not in effect by unmarking the DOM element.
     *
     * @param {boolean} [announce]    Silent if **false**.
     */
    _leaveNavigation(announce) {
        const func = '_leaveNavigation';
        const log  = (announce !== false);
        if (log)               { this._debug(func) }
        if (this.SET_TABINDEX) { this._neutralizeControls() }
        if (this.standalone)   { setFocusable(this.group, true, func) }
        this._active = false;
    }

    _neutralizeControls() {
        neutralizeFocusables(this.controls);
    }

    _restoreControls() {
        restoreFocusables(this.controls.filter(':visible'));
    }

    _nextNeighbor() {
        return nextInTabOrder(this.group).focus();
    }

    _prevNeighbor() {
        return prevInTabOrder(this.group).focus();
    }

    // ========================================================================
    // Methods - controls
    // ========================================================================

    /**
     * Indicate whether *item* is a subclass control.
     *
     * @param {Selector|undefined} item
     *
     * @returns {boolean}
     */
    isControl(item) {
        return this.constructor.isControl(item);
    }

    /**
     * The single control element associated with *item*.
     *
     * @param {Selector}     item
     * @param {string|false} [caller]           For diagnostic messages.
     *
     * @returns {jQuery}
     *
     * @see activeControl
     */
    control(item, caller) {
        const log    = (caller !== false);
        const func   = 'control'; //log && this._debug(`${func}:`, item);
        const $ctrls = this.controls;
        const $ctrl  = presence($ctrls.filter(item)) || $ctrls.has(item);
        return this._single($ctrl, (log && (caller || func)));
    }

    /**
     * The single control element associated with *item*.
     *
     * @param {Selector|undefined} item
     *
     * @returns {jQuery|undefined}
     */
    testControl(item) {
        //this._debug('testControl: item =', item);
        return item ? presence(this.control(item, false)) : undefined;
    }

    /**
     * The single focusable control element associated with *item*.
     *
     * @param {Selector|undefined} item
     * @param {string|false}       [caller]     For diagnostic messages.
     *
     * @returns {jQuery|undefined}
     */
    activeControl(item, caller) {
        const func = caller || 'activeControl';
        const log  = (caller !== false) || undefined;
        let $ctrl;
        if (!item) {
            return log && this._warn(`${func}: item is undefined`);
        } else if (isMissing($ctrl = this.control(item))) {
            return log && this._warn(`${func}: invalid item =`, item);
        } else if (isMissing($ctrl = getCurrentFocusables($ctrl))) {
            return log && this._warn(`${func}: not focusable item =`, item);
        }
        log && this._debug(`${func}:`, $ctrl);
        return $ctrl;
    }

    /**
     * Previous focusable relative to *from* that will receive focus if moving
     * backward, wrapping to the last if *wrap* is **true**.
     *
     * @param {Selector} [from]       Default: {@link currentControl}.
     * @param {boolean}  [wrapping]   Default: {@link WRAP_MOVE}.
     *
     * @returns {jQuery|undefined}
     */
    prevControl(from, wrapping) {
        const wrap = isDefined(wrapping) ? wrapping : this.WRAP_MOVE;
        this._debug(`prevControl: wrap = ${wrap}; from =`, from);
        const $old = from ? this.control(from) : this.currentControl;
        const $new = prevInTabOrder($old, { root: this.container });
        return $new || (wrap && this.activeControls.last()) || undefined;
    }

    /**
     * Next focusable relative to *from* that will receive focus if moving
     * forward, wrapping to the first if *wrap* is **true**.
     *
     * @param {Selector} [from]       Default: {@link currentControl}.
     * @param {boolean}  [wrapping]   Default: {@link WRAP_MOVE}.
     *
     * @returns {jQuery|undefined}
     */
    nextControl(from, wrapping) {
        const wrap = isDefined(wrapping) ? wrapping : this.WRAP_MOVE;
        this._debug(`nextControl: wrap = ${wrap}; from =`, from);
        const $old = from ? this.control(from) : this.currentControl;
        const $new = nextInTabOrder($old, { root: this.container });
        return $new || (wrap && this.activeControls.first()) || undefined;
    }

    // ========================================================================
    // Methods - controls - internal
    // ========================================================================

    /**
     * _getControls
     *
     * @param {Selector} [within]     Default: {@link group}.
     *
     * @returns {jQuery}
     * @protected
     */
    _getControls(within) {
        return this.constructor.controls(within || this.group);
    }

    /**
     * The category of the focusable element.
     *
     * @param {Selector} control
     *
     * @returns {NavGroupControlType}
     * @protected
     */
    _controlCategory(control) {
        const $control = $(control);
        if (isEmpty($control))        { return {} }
        if ($control.is('a'))         { return { link:    true } }
        if ($control.is('details'))   { return { details: true } }
        if ($control.is('textarea'))  { return { text:    true } }
        switch ($control.prop('type')) {
            case 'button':              return { button:  true };
            case 'reset':               return { button:  true };
            case 'submit':              return { button:  true };
            case 'checkbox':            return { check:   true };
            case 'radio':               return { radio:   true };
            case 'select':              return { select:  true };
            case 'select-one':          return { select:  true };
            case 'select-multiple':     return { select:  true };
            case 'text':                return { text:    true };
            default:                    return { input:   true };
        }
    }

    _getFocusControl() {
        //this._debug('_getFocusControl');
        return this.container.data(NAV_FOCUS_DATA) || undefined;
    }

    _setFocusControl(control) {
        const $control = this.testControl(control);
        this._debug('_setFocusControl:', $control);
        this.container.data(NAV_FOCUS_DATA, $control);
    }

    _clearFocusControl() {
        this._debug('_clearFocusControl');
        this._container?.data(NAV_FOCUS_DATA, '');
    }

    // ========================================================================
    // Methods - entries
    // ========================================================================

    /**
     * The single entry element associated with *item*.
     *
     * @param {Selector}     item
     * @param {string|false} [caller]           For diagnostic messages.
     *
     * @returns {jQuery}
     *
     * @see activeEntry
     */
    entry(item, caller) {
        const log    = (caller !== false);
        const func   = 'entry'; log && this._debug(`${func}: item =`, item);
        const $items = this.entries;
        const $item  = presence($items.filter(item)) || $items.has(item);
        return this._single($item, (log && (caller || func)));
    }

    /**
     * The single entry element associated with *item*.
     *
     * @param {Selector|undefined} item
     *
     * @returns {jQuery|undefined}
     */
    testEntry(item) {
        //this._debug('testEntry: item =', item);
        return item ? presence(this.entry(item, false)) : undefined;
    }

    /**
     * The single entry element for *item* which is associated with a focusable
     * control.
     *
     * @param {Selector|undefined} item
     * @param {string}             [caller]     For diagnostic messages.
     *
     * @returns {jQuery|undefined}
     */
    activeEntry(item, caller) {
        const func     = caller || 'activeEntry';
        const $control = this.activeControl(item, func);
        return $control && this.entry($control);
    }

    /**
     * Previous focusable relative to *from* that will receive focus if moving
     * backward, wrapping to the last if *wrap* is **true**.
     *
     * @param {Selector} [from]       Default: {@link currentEntry}.
     * @param {boolean}  [wrapping]   Default: {@link WRAP_MOVE}.
     *
     * @returns {jQuery|undefined}
     */
    prevEntry(from, wrapping) {
        this._debug(`prevEntry: wrapping = ${wrapping}; from =`, from);
        return this.entry(this.prevControl(from, wrapping));
    }

    /**
     * Next focusable relative to *from* that will receive focus if moving
     * forward, wrapping to the first if *wrap* is **true**.
     *
     * @param {Selector} [from]       Default: {@link currentEntry}.
     * @param {boolean}  [wrapping]   Default: {@link WRAP_MOVE}.
     *
     * @returns {jQuery|undefined}
     */
    nextEntry(from, wrapping) {
        this._debug(`nextEntry: wrapping = ${wrapping}; from =`, from);
        return this.entry(this.nextControl(from, wrapping));
    }

    // ========================================================================
    // Methods - entries - internal
    // ========================================================================

    /**
     * _getEntries
     *
     * @param {Selector} [within]     Default: {@link group}.
     *
     * @returns {jQuery}
     * @protected
     */
    _getEntries(within) {
        return this.constructor.entries(within || this.group);
    }

    // ========================================================================
    // Methods - navigation
    // ========================================================================

    /**
     * Affect navigation according to the key combination provided. <p/>
     *
     * If returning **true** then the event should be considered handled
     * (_i.e._, should not be propagated); if returning **false** then the
     * event is explicitly expected to be propagated. <p/>
     *
     * @param {string} key            From {@link keyCombo}.
     * @param {jQuery} [$target]      Actual event target.
     *
     * @returns {boolean|undefined}
     */
    handle(key, $target) {
        if (!key)               { return this._warn('handle: empty key') }
        if (modifiersOnly(key)) { return }
        switch (key) {
            case 'Enter':       return this.activate($target, key);
            case 'Escape':      return this.deactivate($target, key);
            case 'Home':        return this.moveToFirst($target, key);
            case 'End':         return this.moveToLast($target, key);
            case 'Tab':         return this.moveForward($target, key);
            case 'ArrowDown':   return this.moveForward($target, key);
            case 'ArrowRight':  return this.moveForward($target, key);
            case 'Shift+Tab':   return this.moveBackward($target, key);
            case 'ArrowUp':     return this.moveBackward($target, key);
            case 'ArrowLeft':   return this.moveBackward($target, key);
            default:            return this.handleDefault($target, key);
        }
    }

    /**
     * Activate the group and/or a control.
     *
     * @param {jQuery|null} [$target]   If missing, {@link _activateGroup}.
     * @param {string}      [key]
     * @param {...*}        args        Passed to {@link _activateControl}.
     *
     * @returns {boolean}               If **true** event is considered handled
     */
    activate($target, key, ...args) {
        const func = 'activate';
        if (notDefined($target)) {
            return this._activateGroup(func, key);
        } else {
            return this._activateControl(func, $target, key, ...args);
        }
    }

    /**
     * Activate the group.
     *
     * @param {string} cb_type        Related {@link _callbacks} entry.
     * @param {string} [key]
     *
     * @returns {boolean}             If **true** event is considered handled.
     */
    _activateGroup(cb_type, key) {
        const func       = '_activateGroup';
        const activating = !this.active;

        if (this._debugging) {
            const msg = key ? keyFormat('key', key, '=> ACTIVATE') : [];
            //this._debug(`${func}:`, ...msg, this.group);
            this._warn(`${func}:`, ...msg, this.group);
        }

        if (!activating) {
            this._warn(`${func}: group already active`);
            return true;
        }
        this._enterNavigation();

        if (isMissing(this.activeControls)) {
            return this._warn(`${func}: no active controls`) || false;
        }
        return this._runCallbacks(undefined, cb_type);
    }

    /**
     * Activate a control.
     *
     * @param {string}      cb_type   Related {@link _callbacks} entry.
     * @param {jQuery|null} $target
     * @param {string}      [key]
     * @param {...*}        args      Passed to {@link _moveTo}
     *
     * @returns {boolean}             If **true** event is considered handled.
     */
    _activateControl(cb_type, $target, key, ...args) {
        const func       = '_activateControl';
        const activating = !this.active;

        if (activating) {
            this._warn(`${func}: should have been active already`);
            this._enterNavigation();
        }

        let tgt, $new_focus, $old_focus = this.focusControl;
        const $control = this.testControl($target);
        if ($control && $old_focus && sameElements($control, $old_focus)) {
            tgt = 'current focus $target';
        } else if (($new_focus = $control)) {
            tgt = 'new focus $target';
        } else if ($old_focus) {
            tgt = 'focusControl';
        } else if (($new_focus = this.activeControls.first())) {
            tgt = 'first control';
        }
        const $focus  = $new_focus || $old_focus;
        const focus   = isPresent($focus);
        const refocus = isPresent($new_focus);

        if (this._debugging) {
            const msg = key ? keyFormat('key', key, '=> ACTIVATE') : [];
            if (focus) {
                msg.push(`from ${tgt} =`, $focus, 'in');
            } else {
                msg.push(`from EMPTY ${tgt} in`);
            }
            //this._debug(`${func}:`, ...msg, this.group);
            this._warn(`${func}:`, ...msg, this.group);
        }

        if (!focus) {
            this._warn(`${func}: no active control in`, this.group);
            return true;
        }
        this._moveTo($focus, refocus, ...args);

        // Only notify via callbacks if there was a discernible change.
        if (!activating && !refocus && !$control) {
            return false;
        }
        return this._runCallbacks(($control || $focus), cb_type);
    }

    /**
     * Respond to ESC by leaving group navigation. <p/>
     *
     * The event is allowed to propagate to allow the enclosing grid cell to
     * manage the deactivation of the instance unless the event has bubbled up
     * from a control.
     *
     * @param {jQuery} [$target]
     * @param {string} [key]
     * @param {...*}   _args          Ignored.
     *
     * @returns {boolean}             If **true** event is considered handled.
     */
    deactivate($target, key, ..._args) {
        const func         = 'deactivate';
        const deactivating = this.active;
        const for_group    = deactivating && !$target;
        const for_control  = deactivating && !!$target;

        if (this._debugging) {
            const msg = key ? keyFormat('key', key) : [];
            switch (true) {
                case for_group:   msg.push('EXIT from');          break;
                case for_control: msg.push('for', $target, 'in'); break;
                default:          msg.push('ignored - inactive'); break;
            }
            this._debug(`${func}:`, ...msg, 'group = ', this.group);
        }

        if (for_group || for_control) {
            this._runCallbacks($target, func);
        }
        if (for_group) {
            this._leaveNavigation();
        }
        return !$target;
    }

    /**
     * Go to the first group entry.
     *
     * @param {jQuery} [$target]      Unused.
     * @param {string} [key]          Unused.
     * @param {...*}   args           Passed to {@link _moveTo}.
     *
     * @returns {boolean}             If **true** event is considered handled.
     */
    moveToFirst($target, key, ...args) {
        const func = 'moveToFirst';
        this._logAction(func, key, $target, 'FIRST_CONTROL');
        const $new = this.activeControls.first();
        this._moveTo($new, ...args);
        const handled = this._runCallbacks($new, func, 'move');
        return (handled !== false);
    }

    /**
     * Go to the last group entry.
     *
     * @param {jQuery} [$target]      Unused.
     * @param {string} [key]          Unused.
     * @param {...*}   args           Passed to {@link _moveTo}.
     *
     * @returns {boolean}             If **true** event is considered handled.
     */
    moveToLast($target, key, ...args) {
        const func = 'moveToLast';
        this._logAction(func, key, $target, 'LAST_CONTROL');
        const $new = this.activeControls.last();
        this._moveTo($new, ...args);
        const handled = this._runCallbacks($new, func, 'move');
        return (handled !== false);
    }

    /**
     * Focus on the previous entry.
     *
     * @param {jQuery} [$target]      Default: {@link currentControl}.
     * @param {string} [key]
     * @param {...*}   args           Passed to {@link _moveTo}
     *
     * @returns {boolean}             If **true** event is considered handled.
     */
    moveBackward($target, key, ...args) {
        const func = 'moveBackward';
        this._logAction(func, key, $target, 'PREV_CONTROL');
        const $new = this.prevControl($target);
        this._moveTo($new, ...args);
        const handled = this._runCallbacks($new, func, 'move');
        return (handled !== false);
    }

    /**
     * Focus on the next entry.
     *
     * @param {jQuery} [$target]      Default: {@link currentControl}.
     * @param {string} [key]
     * @param {...*}   args           Passed to {@link _moveTo}
     *
     * @returns {boolean}             If **true** event is considered handled.
     */
    moveForward($target, key, ...args) {
        const func = 'moveForward';
        this._logAction(func, key, $target, 'NEXT_CONTROL');
        const $new = this.nextControl($target);
        this._moveTo($new, ...args);
        const handled = this._runCallbacks($new, func, 'move');
        return (handled !== false);
    }

    /**
     * Response to a generic keypress.
     *
     * @param {jQuery} [$target]
     * @param {string} [key]
     * @param {...*}   _args          Ignored.
     *
     * @returns {false}               Event should not be considered handled.
     */
    handleDefault($target, key, ..._args) {
        const func = 'handleDefault';
        if (key && this._debugging) {
            const msg = keyFormat(`${func}:`, key);
            let $focus;
            if (this.isControl($target)) {
                msg.push('for $target =', $target);
            } else if (($focus = this.focusControl)) {
                msg.push('for focusControl =', $focus);
            } else {
                msg.push('not handled for', $target);
            }
            //this._debug(...msg, 'in', this.group);
            this._warn(...msg, 'in', this.group);
        }
        if (!this.active) {
            this._warn(`${func}: not active:`, this.group);
        }
        return false;
    }

    // ========================================================================
    // Methods - navigation - internal
    // ========================================================================

    /**
     * Go to the entry associated with *$item*.
     *
     * @param {jQuery}  $item         A group entry or control.
     * @param {boolean} [focus]       Set focus on control unless **false**.
     * @param {...*}    args          Passed to {@link _updateControl}.
     */
    _moveTo($item, focus, ...args) {
        const func = '_moveTo';
        this._debug(`${func}: focus=${focus} args=`, args, '$item =', $item);
        if (!this._updateItem($item, ...args)) {
            this._warn(`${func}: empty $item =`, $item);
        } else if (focus !== false) {
            this.activeControl($item)?.focus();
        }
    }

    /**
     * Update information for the entry associated with *$item*.
     *
     * @param {jQuery}  $item         A group entry or control.
     * @param {...*}    args          Passed to {@link _updateControl}.
     *
     * @returns {boolean}             **false** if *$item* is empty.
     */
    _updateItem($item, ...args) {
        this._debug('_updateItem: args =', args, '$item =', $item);
        if (isMissing($item)) { return false }
        this._updateEntry($item, true);
        this._updateControl($item, ...args);
        return true;
    }

    /**
     * Update the status of the control associated with *$item*.
     *
     * @param {jQuery} $item          NOTE: assumed to be valid.
     * @param {...*}   args           Ignored.
     */
    _updateControl($item, ...args) {
        this._debug('_updateControl:', $item, 'args =', args);
        // No base class functionality.
    }

    /**
     * Update the selection state of the entry associated with *$item*.
     *
     * @param {jQuery} $item          NOTE: assumed to be valid.
     * @param {boolean} [select]
     */
    _updateEntry($item, select) {
        const func = '_updateEntry';
        this._debug(`${func}:`, $item, 'select =', select);
        const selected = !!(isDefined(select) ? select : this.focusEntry);
        if (selected) { this.entries.attr(this.CURRENT_ATTR, false) }
        const $entry = this.activeEntry($item);
        if ($entry) {
            $entry.attr(this.CURRENT_ATTR, selected);
        } else {
            this._warn(`${func}: no entry for`, $item);
        }
    }

    /**
     * Execute any callback(s) registered for *types*.
     *
     * @param {jQuery|undefined} $control
     * @param {string}           type
     * @param {...string}        [more]
     *
     * @returns {boolean}           Always **true** if there were no callbacks.
     * @protected
     */
    _runCallbacks($control, type, ...more) {
        const cbs = [];
        [type, ...more].forEach(t => cbs.push(...(this._callbacks[t] || [])));
        if (isMissing(cbs)) { return true }

        const func = '_runCallbacks'; this._debug(`${func}:`, cbs);
        const opt  = { container: this.container, group: this.group };
        if ($control) { opt.control = $control }

        let handled = false;
        cbs.forEach(cb => (handled = cb(opt) || handled));
        this._debug(`${func}: handled =`, handled);
        return handled;
    }

    _logAction(func, key, $target, action) {
        const grp = this.group;
        if (!this.active)     { this._warn(`${func}: not active:`, grp) }
        if (!this._debugging) { return }
        const msg = key ? keyFormat('key', key, `=> ${action}`) : [];
        if ($target) {
            let tgt;
            switch (true) {
                case !!this.testEntry($target):   tgt = 'entry';   break;
                case !!this.testControl($target): tgt = 'control'; break;
                default:                          tgt = '$target'; break;
            }
            msg.push(`from ${tgt} =`, $target);
        }
        //this._debug(`${func}:`, ...msg, 'in', grp);
        this._warn(`${func}:`, ...msg, 'in', grp);
    }

    // ========================================================================
    // Class properties
    // ========================================================================

    /**
     * A rendering of the class name for descriptive purposes.
     *
     * @returns {string}
     */
    static get typeDesc() {
        return this._type_desc ||=
            underscore(this.CLASS_NAME).replaceAll('_', ' ');
    }

    // ========================================================================
    // Class properties - internal
    // ========================================================================

    static get _current() { return this.currentSelector(true) }

    // ========================================================================
    // Class methods
    // ========================================================================

    /**
     * Indicate whether *item* is a valid group element.
     *
     * @param {Selector|undefined} item
     *
     * @returns {boolean}
     */
    static isGroup(item) {
        const match = this.GROUP;
        //this._debug(`isGroup: match = "${match}"; item =`, item);
        return !!item && $(item).is(match);
    }

    /**
     * Return *item* or the group in which it is contained.
     *
     * @param {Selector} item
     *
     * @returns {jQuery}
     */
    static group(item) {
        const func  = 'group';
        const match = this.GROUP;
        //this._debug(`${func}: match = "${match}"; item =`, item);
        return this._selfOrParent(item, match, func);
    }

    /**
     * Indicate whether *item* should be within a nav group.
     *
     * @param {Selector|undefined} item
     *
     * @returns {boolean}
     */
    static shouldContain(item) {
        return !!item && isPresent($(item).parents(this.GROUP));
    }

    /**
     * The selector for filtering entries which are marked as current.
     *
     * @param {boolean} [setting]     If **false** the selector is negated.
     *
     * @returns {string}
     */
    static currentSelector(setting = true) {
        return `[${this.CURRENT_ATTR}="${setting}"]`;
    }

    /**
     * The class instance associated with *container* (if any).
     *
     * @param {Selector} container
     *
     * @returns {NavGroup|undefined}
     */
    static instanceFor(container) {
        //this._debug('instanceFor: container =', container);
        return $(container).data(NAV_GROUP_DATA);
    }

    /**
     * Find the group characterized by the subclass at or within *root* and
     * create a subclass instance for it which will be attached to the root
     * container element.
     *
     * @param {Selector} root
     * @param {boolean}  [quiet]      Don't report constructor failure.
     *
     * @returns {NavGroup|undefined} Subclass instance if called on subclass.
     */
    static setupFor(root, quiet) {
        const func      = 'setupFor'; //this._debug(`${func}: root =`, root);
        const $root     = $(root);
        let instance    = this.instanceFor($root);
        const container = (instance instanceof this) && instance.container;

        if (container && sameElements(container, $root)) {
            //this._debug(`${func}: already set for`, $root);
            return instance;

        } else if (container) {
            return this._warn(`${func}: already set for`, container);

        } else if (instance) {
            const nav_group = instance.CLASS_NAME;
            return this._warn(`${func}: already set ${nav_group} for`, $root);
        }

        selfOrDescendents($root, this.GROUP).each((_, group) => {
            if (instance) {
                this._warn(`${func}: already set; ignoring`, group);
            } else {
                //this._debug(`${func}: creating for`, group);
                try {
                    instance = new this(group, $root);
                } catch (error) {
                    if (error instanceof ValidationError) {
                        quiet || this._warn(`${func}:`, ...error.messageParts);
                    } else {
                        throw error;
                    }
                }
            }
        });
        return instance;
    }

    // ========================================================================
    // Class methods - internal
    // ========================================================================

    static CELL_ROLE = ['gridcell', 'rowheader', 'columnheader'];
    static GRID_CELL = attributeSelector(this.CELL_ROLE.map(r => ['role', r]));

    static _isGridCell(item) {
        return $(item).is(this.GRID_CELL);
    }

    static _insideGridCell(item) {
        return containedBy(item, this.GRID_CELL);
    }

    static _single(item, caller) {
        let func = this.CLASS_NAME;
        if (caller === false) {
            func = caller;
        } else if (caller) {
            func = `${func}.${caller}`;
        }
        return single(item, func);
    }

    static _selfOrParent(item, match, caller) {
        let func = this.CLASS_NAME;
        if (caller === false) {
            func = caller;
        } else if (caller) {
            func = `${func}.${caller}`;
        }
        return selfOrParent(item, match, func);
    }

    // ========================================================================
    // Class methods - controls
    // ========================================================================

    /**
     * Indicate whether *item* is a subclass control.
     *
     * @param {Selector|undefined} item
     *
     * @returns {boolean}
     */
    static isControl(item) {
        const match = this.CONTROL;
        //this._debug(`isControl: match = "${match}"; item =`, item);
        return $(item).is(match);
    }

    /**
     * The focusable element(s) associated with *item*.
     *
     * @param {Selector} item
     *
     * @returns {jQuery}
     *
     * @see _pruneControlSearch
     */
    static controls(item) {
        const match = this.CONTROL;
        const prune = this._pruneControlSearch();
        //this._debug(`controls: match = "${match}"; item =`, item);
        return selfAndDescendents(item, prune).filter(match);
    }

    /**
     * Returns a selector describing elements which are the roots of subtrees
     * that will not be visited when looking for focusable elements.
     *
     * @returns {string}
     * @protected
     */
    static _pruneControlSearch() {
        return selector(this.PRUNE_AT);
    }

    // ========================================================================
    // Class methods - entries
    // ========================================================================

    /**
     * Subclasses may enclose a control within an "entry" element.
     *
     * In the general case, however, controls are expected to stand on their
     * own -- so "entry(x)" would be the same as "control(x)".
     *
     * @param {Selector} item
     *
     * @returns {jQuery}
     */
    static entries(item) {
        //this._debug('entries: item =', item);
        return this.controls(item);
    }
}

/**
 * The base class for groups which are sets of the same type of control.
 *
 * @abstract
 * @extends NavGroup
 */
export class ListGroup extends NavGroup {

    static CLASS_NAME = 'ListGroup';

    // ========================================================================
    // Constants
    // ========================================================================

    static GROUP       = LIST_GROUP;
    static CONTROL     = LIST_INPUT;
    static SET_CHECKED = false;

    // ========================================================================
    // Constructor
    // ========================================================================

    /**
     * Create a new instance.
     *
     * @param {Selector} group
     * @param {Selector} [container]
     */
    constructor(group, container) {
        super(group, container);
        if (this.SET_CHECKED) {
            this._handleEvent(this.controls, 'change', this._onChecked);
        }
    }

    // ========================================================================
    // Properties
    // ========================================================================

    get SET_CHECKED() { return this.constructor.SET_CHECKED }

    // ========================================================================
    // Methods - events
    // ========================================================================

    /**
     * Handle control checked state change.
     *
     * @param {jQuery.Event|Event} event
     *
     * @returns {EventHandlerReturn}
     */
    _onChecked(event) {
        this._debug('_onChecked', event);
        const $control = this.control(event.currentTarget || event.target);
        this.activate($control);
    }

    // ========================================================================
    // Methods - navigation - internal - NavGroup overrides
    // ========================================================================

    /**
     * Update the status of the entry and control associated with *$item*.
     *
     * @param {jQuery}  $item         NOTE: assumed to be valid.
     * @param {boolean} [check]
     */
    _updateControl($item, check) {
        super._updateControl($item);
        if (this.SET_CHECKED) { this._updateCheck($item, check) }
    }

    // ========================================================================
    // Methods - internal
    // ========================================================================

    /**
     * Update the status of the entry and control associated with *$item*.
     *
     * @param {jQuery}  $item
     * @param {boolean} [check]
     */
    _updateCheck($item, check) {
        const func = '_updateCheck';
        this._debug(`${func}: check =`, check, $item);
        const $control = this.activeControl($item);
        if ($control) {
            if (isDefined(check)) { $control.prop('checked', !!check) }
            const checked = $control.prop('checked') || false;
            this.entry($control).attr('aria-checked', checked);
        } else {
            this._warn(`${func}: no control for`, $item);
        }
    }

    // ========================================================================
    // Class methods - NavGroup overrides
    // ========================================================================

    /**
     * Controls may be enclosed in an "entry", or they may be "bare" (in which
     * case, "entries" are identical to "controls").
     *
     * @param {Selector} item
     *
     * @returns {jQuery}
     */
    static entries(item) {
        //this._debug('entries: item =', item);
        return this.controls(item).parent().not(this.GROUP);
    }
}

/**
 * An object to facilitate keyboard navigation within a group of checkboxes.
 *
 * @extends ListGroup
 */
export class CheckboxGroup extends ListGroup {

    static CLASS_NAME = 'CheckboxGroup';

    // ========================================================================
    // Constants
    // ========================================================================

    static GROUP        = CB_GROUP;
    static CONTROL      = CHECKBOX;
    static WRAP_MOVE    = true;
    static CURRENT_ATTR = 'aria-selected';
    static SET_CHECKED  = true;

    // ========================================================================
    // Methods - group events - NavGroup overrides
    // ========================================================================

    _groupFocus(event) {
        super._groupFocus(event);
        const $focus = this.focusControl || this.activeControls.first();
        this.activate($focus);
    }

    // ========================================================================
    // Methods - entries - NavGroup overrides
    // ========================================================================

    entry(item, caller)  {
        const func  = 'entry';
        const match = CB_ENTRY;
        const log   = (caller !== false);
        log && this._debug(`${func}: match = "${match}"; item =`, item);
        return this._selfOrParent(item, match, (log && (caller || func)));
    }

    // ========================================================================
    // Class methods - entries - NavGroup overrides
    // ========================================================================

    static entries(item) {
        const func  = 'entries';
        const match = CB_ENTRY;
        this._debug(`${func}: match = "${match}"; item =`, item);
        return selfOrDescendents(item, match);
    }
}

/**
 * An object to facilitate keyboard navigation within a group of radio buttons.
 *
 * @note This is not currently in use - implementation has not been validated.
 *
 * @extends ListGroup
 */
export class RadioGroup extends ListGroup {

    static CLASS_NAME = 'RadioGroup';

    // ========================================================================
    // Constants
    // ========================================================================

    static GROUP        = RADIO_GROUP;
    static CONTROL      = RADIO;
    static SET_TABINDEX = false;
    static SET_CHECKED  = true;

    // ========================================================================
    // Methods - navigation - NavGroup overrides
    // ========================================================================

    handle(key, $target) {
        switch (key) {
            case ' ':          return this.activate($target, key);
            case 'ArrowUp':    return this.selectionMoved($target, key);
            case 'ArrowLeft':  return this.selectionMoved($target, key);
            case 'ArrowDown':  return this.selectionMoved($target, key);
            case 'ArrowRight': return this.selectionMoved($target, key);
            default:           return super.handle(key, $target);
        }
    }

    /**
     * Go to the first radio item.
     *
     * @param {jQuery} [$target]
     * @param {string} [key]
     * @param {...*}   _args          Ignored
     *
     * @returns {boolean|undefined}
     */
    moveToFirst($target, key, ..._args) {
        return super.moveToFirst($target, key, true);
    }

    /**
     * Go to the last radio item.
     *
     * @param {jQuery} [$target]
     * @param {string} [key]
     * @param {...*}   _args          Ignored
     *
     * @returns {boolean|undefined}
     */
    moveToLast($target, key, ..._args) {
        return super.moveToLast($target, key, true);
    }

    // ========================================================================
    // Methods - navigation
    // ========================================================================

    /**
     * Bubbled event received indicates that focus has moved to a different
     * radio button.
     *
     * @param {jQuery} $target
     * @param {string} key
     *
     * @returns {boolean|undefined}
     */
    selectionMoved($target, key) {
        let $focus, $control = this.activeControl($target);
        $control ||= ($focus = this.focusControl);
        if (this._debugging) {
            const func = 'selectionMoved';
            const msg  = key ? keyFormat('key', key, '=>') : [];
            if ($focus) {
                msg.push('MOVE_TO focusControl =', $focus);
            } else if ($control) {
                msg.push('MOVE_TO $target =', $target);
            } else {
                msg.push('IGNORED for', $target);
            }
            //this._debug(`${func}:`, ...msg, 'in', this.group);
            this._warn(`${func}:`, ...msg, 'in', this.group);
        }
        return !!$control && this._updateItem($control);
    }
}

/**
 * An object to facilitate keyboard navigation within a group of text inputs.
 *
 * @note This is not currently in use - implementation has not been validated.
 *
 * @extends ListGroup
 */
export class TextInputGroup extends ListGroup {

    static CLASS_NAME = 'TextInputGroup';

    // ========================================================================
    // Constants
    // ========================================================================

    static GROUP     = TEXT_GROUP;
    static CONTROL   = TEXT_INPUT;
    static WRAP_MOVE = true;

}

/**
 * An object to facilitate keyboard navigation within a group of generic
 * focusable elements.
 *
 * @extends NavGroup
 */
export class ControlGroup extends NavGroup {

    static CLASS_NAME = 'ControlGroup';

    // ========================================================================
    // Constants
    // ========================================================================

    static GROUP        = CONTROL_GROUP;
    static CONTROL      = CONTROL_INPUT;
    static WRAP_MOVE    = true;
    static PRUNE_AT     = [this.MODAL_ROOT];

    static MIN_CONTROLS = 2;
    static MAX_CONTROLS = undefined;

    // ========================================================================
    // Properties
    // ========================================================================

    get MIN_CONTROLS() { return this.constructor.MIN_CONTROLS }
    get MAX_CONTROLS() { return this.constructor.MAX_CONTROLS }

    // ========================================================================
    // Methods - validation - NavGroup overrides
    // ========================================================================

    /**
     * Determine whether a valid instance can be created and that the number of
     * controls within the group meets the criteria of the subclass.
     *
     * @param {boolean} [no_throw]
     *
     * @returns {boolean}             **false** if there was an error.
     * @protected
     */
    _validate(no_throw) {
        if (!super._validate(no_throw)) { return false }
        const count     = this.controls.length;
        const min_count = this.MIN_CONTROLS || count;
        const max_count = this.MAX_CONTROLS || count;
        let msg;
        if (count < min_count) {
            msg = [`too few focusables (${count})`];
        } else if (count > max_count) {
            msg = [`too many focusables (${count})`];
        }
        msg?.push('for', this.typeDesc, '=', this.group);
        return !this._validationError(msg, no_throw);
    }

    // ========================================================================
    // Class methods - NavGroup overrides
    // ========================================================================

    static isControl(item) {
        const $item = $(item);
        return super.isControl($item) && maybeFocusable($item);
    }

    static controls(item) {
        const $elements = super.controls(item);
        return getMaybeFocusables($elements).not(this.GROUP);
    }

}

/**
 * An object to facilitate keyboard navigation within a group of generic
 * focusable elements in the context of a grid cell. <p/>
 *
 * (Actually, the behaviors of this subclass might be generally applicable to
 * any arbitrary group of controls whether they're inside a grid cell or not.
 * If so, it would make sense to rename this subclass accordingly and then mark
 * ControlGroup as abstract.)
 *
 * @extends ControlGroup
 */
export class CellControlGroup extends ControlGroup {

    static CLASS_NAME = 'CellControlGroup';

    // ========================================================================
    // Methods - validation - NavGroup overrides
    // ========================================================================

    /**
     * Determine whether a valid instance can be created. <p/>
     *
     * Since this class might actually be useful outside the context of a grid
     * cell, not being inside is only treated as warning for now.
     *
     * @param {boolean} [no_throw]
     *
     * @returns {boolean}             **false** if there was an error.
     * @protected
     */
    _validate(no_throw) {
        if (!super._validate(no_throw)) { return false }
        if (!this._insideGridCell(this.group)) {
            this._warn('not inside grid cell');
        }
        return true;
    }

    // ========================================================================
    // Methods - NavGroup overrides
    // ========================================================================

    /**
     * The first focusable will get focus when clicking inside the cell/group,
     * but it shouldn't be automatically activated.
     *
     * @returns {boolean}
     */
    clickedInside() {
        this._debug('clickedInside');
        return false;
    }

}

/**
 * An object to facilitate keyboard navigation for a group containing a single
 * `<select>` element.
 *
 * @note This is mostly for consistency since there is no attempt to get in the
 *  way of the default behaviors of the `<select>` element.
 *
 * @extends ControlGroup
 */
export class MenuGroup extends ControlGroup {

    static CLASS_NAME = 'MenuGroup';

    // ========================================================================
    // Constants
    // ========================================================================

    static GROUP   = MENU_GROUP;
    static CONTROL = MENU_INPUT;

    static MIN_CONTROLS = 1;
    static MAX_CONTROLS = 1;

    // ========================================================================
    // Methods - navigation - NavGroup overrides
    // ========================================================================

    /**
     * Non group-related click and keypress events are passed directly on to
     * the `<select>` element.
     *
     * @param {string} _key           Ignored.
     * @param {jQuery} [_$target]     Ignored.
     *
     * @returns {false}
     */
    handle(_key, _$target) {
        return false;
    }

}

/**
 * An object to facilitate keyboard navigation for a group containing a single
 * focusable element.
 *
 * @extends ControlGroup
 */
export class SingletonGroup extends ControlGroup {

    static CLASS_NAME = 'SingletonGroup';

    // ========================================================================
    // Constants
    // ========================================================================

    static GROUP        = SINGLETON_GROUP;
    static CONTROL      = SINGLETON_INPUT;
    static WRAP_MOVE    = false;

    static MIN_CONTROLS = 1;
    static MAX_CONTROLS = 1;

    // ========================================================================
    // Methods - controls - NavGroup overrides
    // ========================================================================

    /**
     * The previous control as always the single control in the group.
     *
     * @param {Selector} [_from]      Ignored.
     * @param {boolean}  [_wrap]      Ignored.
     *
     * @returns {jQuery|undefined}
     */
    prevControl(_from, _wrap) {
        this._debug(`prevControl: ignored - wrap = ${_wrap}; from =`, _from);
        return this.currentControl;
    }

    /**
     * The next control as always the single control in the group.
     *
     * @param {Selector} [_from]      Ignored.
     * @param {boolean}  [_wrap]      Ignored.
     *
     * @returns {jQuery|undefined}
     */
    nextControl(_from, _wrap) {
        this._debug(`nextControl: ignored - wrap = ${_wrap}; from =`, _from);
        return this.currentControl;
    }

}
