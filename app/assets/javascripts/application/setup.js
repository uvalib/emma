// app/assets/javascripts/application/setup.js
//
// This module should be the first import of application.js in order to prepare
// for Turbolinks setup/teardown.
//
// noinspection JSUnusedGlobalSymbols


import { AppDebug }  from './debug';
import { BaseClass } from '../shared/base-class';
import { isEmpty }   from '../shared/definitions';
import { hasKey }    from '../shared/objects';


const MODULE = 'Setup';
const DEBUG  = true;

AppDebug.file('application/setup', MODULE, DEBUG);

/**
 * Console output functions for this module.
 */
const OUT = AppDebug.consoleLogging(MODULE, DEBUG);

// ============================================================================
// Type definitions
// ============================================================================

/**
 * @typedef {AddEventListenerOptions|{listen: boolean}} EventListenerOptionsExt
 */

/**
 * @typedef {boolean|AddEventListenerOptions} EventOptions
 *
 * - **true** is equivalent to "{capture: true}" -- listening in the capture
 *      phase before the event is passed on to `event.target` (if it is
 *      different than `event.currentTarget`).
 *
 * - **false** is equivalent to "{capture: false}" -- the default behavior of
 *      listening in the bubbling phase.
 */

/**
 * @typedef {Map<EventOptions,EventOptions>} EventOptionsMap
 */

/**
 * @typedef {Map<function,EventOptionsMap>} EventCallbackMap
 */

/**
 * @typedef {Map<string,EventCallbackMap>} EventTypeMap
 */

/**
 * @typedef {Map<(string|EventTarget),EventTypeMap>} AppEventMap
 */

/**
 * @typedef {string|BaseClass} ModuleKey
 */

/**
 * @typedef {function|BaseClass} ModuleFunction
 */

/**
 * @typedef {Map<ModuleKey,ModuleFunction>} AppModuleMap
 */

/**
 * A globally available collection of mappings which control setup and teardown
 * on the current page.
 *
 * @typedef ApplicationMaps
 *
 * @property {AppEventMap} Event
 *
 *  Hierarchy of {@link addEventListener} parameters stored by
 *  {@link appEventListener} to allow {@link pageTeardown} to remove event
 *  handlers attached to {@link window} and {@link document}. <p/>
 *
 * @property {AppModuleMap} Setup
 *
 *  Mapping of module name to setup function executed in sequence by
 *  {@link pageSetup}. <p/>
 *
 * @property {AppModuleMap} Teardown
 *
 *  Mapping of module name to teardown function executed in sequence by
 *  {@link pageTeardown}. <p/>
 */

// ============================================================================
// Global value
// ============================================================================

/** @type {ApplicationMaps} */
window.APP_PAGE ||= {
    Event:    new Map(),
    Setup:    new Map(),
    Teardown: new Map(),
};

// ============================================================================
// Constants
// ============================================================================

/**
 * The {@link window.APP_PAGE.Event} key for {@link document} events.
 *
 * @type {string}
 */
export const DOC_KEY = '(DOCUMENT)';

/**
 * The {@link window.APP_PAGE.Event} key for {@link window} events.
 *
 * @type {string}
 */
export const WIN_KEY = '(WINDOW)';

/**
 * If no options are given, this default is applied so that event handlers are
 * consistently assigned in {@link window.APP_PAGE.Event}.
 *
 * @type {EventOptions}
 */
export const DEF_OPTIONS = false;

// ============================================================================
// Functions
// ============================================================================

/**
 * Execute module setup functions in the order that they were inserted into
 * {@link window.APP_PAGE.Setup}.
 */
export function pageSetup() {
    console.warn('*** PAGE SETUP ***');
    runActions(window.APP_PAGE.Setup, 'pageSetup');
}

/**
 * Execute module teardown functions and remove any remaining event handlers
 * from {@link window} and {@link document}.
 */
export function pageTeardown() {
    console.warn('*** PAGE TEARDOWN ***');
    runActions(window.APP_PAGE.Teardown, 'pageTeardown');
    removeEvents();
}

// ============================================================================
// Functions - modules
// ============================================================================

/**
 * Include a setup action in the page setup sequence.
 *
 * @param {ModuleKey}      name
 * @param {ModuleFunction} setup_action
 * @param {ModuleFunction} [teardown_action]
 */
export function appSetup(name, setup_action, teardown_action) {
    storeAction(true, name, setup_action);
    if (teardown_action) {
        storeAction(false, name, teardown_action);
    }
}

/**
 * Include a teardown action in the page teardown sequence.
 *
 * @param {ModuleKey}      name
 * @param {ModuleFunction} teardown_action
 */
export function appTeardown(name, teardown_action) {
    storeAction(false, name, teardown_action);
}

/**
 * Include a setup/teardown action in the appropriate sequence.
 *
 * @param {boolean}        setup
 * @param {ModuleKey}      name
 * @param {ModuleFunction} action
 *
 * @returns {undefined}
 */
function storeAction(setup, name, action) {
    const func = 'storeAction';
    if (!name) {
        return OUT.error(`${func}: no name`);
    }
    const entry = setup ? 'Setup' : 'Teardown';
    if (window.APP_PAGE[entry].has(name)) {
        OUT.warn(`${func}:`, name, `already in window.APP_PAGE.${entry}`);
    }
    let fn, klass;
    if (typeof action === 'function') {
        fn    = action;
    } else if (action instanceof BaseClass) {
        klass = action;
    } else if (name instanceof BaseClass) {
        klass = name;
    }
    if (fn ||= setup ? klass?.setup : klass?.teardown) {
        window.APP_PAGE[entry].set(name, fn);
    } else if (klass) {
        OUT.error(`${func}:`, name, `missing ${entry.toLowerCase()} function`);
    } else {
        OUT.error(`${func}:`, name, 'action not a function');
    }
}

/**
 * Execute all stored functions.
 *
 * @param {AppModuleMap} store
 * @param {string}       [caller]
 *
 * @returns {undefined}
 */
function runActions(store, caller) {
    const func = caller || 'runActions';
    if (isEmpty(store)) {
        return OUT.debug(`${func}: empty store`);
    }
    OUT.debug(`${func}: BEGIN`);
    if (OUT.debugging()) {
        store.forEach((action, key) => OUT.debug(func, key) || action());
    } else {
        store.forEach(action => action());
    }
    OUT.debug(`${func}: END`);
}

// ============================================================================
// Functions - events
// ============================================================================

/**
 * Set an event handler on a global target, including it in the set of event
 * handlers that will be removed on page teardown. <p/>
 *
 * If *options* includes "{listen: false}" then the only action is to remove a
 * previous event handler.
 *
 * @param {EventTarget|string}                      target
 * @param {string}                                  type
 * @param {EventListenerOrEventListenerObject|null} callback
 * @param {EventListenerOptionsExt|boolean}         [options]
 */
export function appEventListener(target, type, callback, options) {
    const func = 'appEventListener';
    const obj  = (typeof options === 'object') && { ...options };
    let listen = true;
    if (hasKey(obj, 'listen')) {
        listen = obj.listen;
        delete obj.listen;
    }
    const ev_options     = appEventOptions(obj || options);
    const [ev_key, node] = appEventTarget(target, func);
    if (appEventTestOrSet(ev_key, type, callback, ev_options, func)) {
        _debugEvent(func, 'remove', type, ev_key, callback, node);
        node.removeEventListener(type, callback, ev_options);
    }
    if (listen) {
        _debugEvent(func, 'listen', type, ev_key, callback, node);
        node.addEventListener(type, callback, ev_options);
    }
}

/**
 * Indicate whether the given event handler (as identified by the target, event
 * type, callback and options) is present in {@link window.APP_PAGE.Event}.
 * If not, the entry is created.
 *
 * @param {EventTarget|string}                      target
 * @param {string}                                  type
 * @param {EventListenerOrEventListenerObject|null} callback
 * @param {EventListenerOptionsExt|boolean}         [options]
 * @param {string}                                  [caller]
 *
 * @returns {boolean}       **false** if the entry had to be created.
 */
export function appEventTestOrSet(target, type, callback, options, caller) {
    const [ev_key, _]  = appEventTarget(target, caller);
    const ev_options   = appEventOptions(options);
    let target_entry   = window.APP_PAGE.Event.get(ev_key);
    let type_entry     = target_entry?.get(type);
    let callback_entry = type_entry?.get(callback);
    if (callback_entry?.has(ev_options)) { return true }

    _debugEvent(caller, 'remember', type, ev_key, callback);
    (callback_entry ||= new Map()).set(ev_options, ev_options);
    (type_entry     ||= new Map()).set(callback, callback_entry);
    (target_entry   ||= new Map()).set(type, type_entry);
    window.APP_PAGE.Event.set(ev_key, target_entry);
    return false;
}

/**
 * Return default event options if none were provided.
 *
 * @param {EventListenerOptionsExt|boolean} [options]
 *
 * @returns {AddEventListenerOptions|boolean}
 */
export function appEventOptions(options) {
    return isEmpty(options) ? DEF_OPTIONS : options;
}

/**
 * Given an event target return the {@link window.APP_PAGE.Event} key and
 * the node that it references.
 *
 * @param {EventTarget|string} k            {@link DOC_KEY} or {@link WIN_KEY}.
 * @param {string}             [caller]     For diagnostics.
 *
 * @returns {[(string|EventTarget|undefined),(EventTarget|undefined)]}
 */
export function appEventTarget(k, caller) {
    const func = caller || 'appEventTarget'; //OUT.debug(func);
    switch (true) {
        case (k instanceof EventTarget):            return [k, k];
        case (k === DOC_KEY) || (k === document):   return [DOC_KEY, document];
        case (k === WIN_KEY) || (k === window):     return [WIN_KEY, window];
        default: OUT.error(`${func}: "${k}" invalid`); return [undefined, k];
    }
}

/**
 * Remove all window/document event listeners registered with
 * {@link window.APP_PAGE.Event}.
 */
function removeEvents() {
    const func   = 'removeEvents';
    const ev_map = window.APP_PAGE.Event;
    if (isEmpty(ev_map)) { return OUT.debug(`${func}: no events`) }
    OUT.debug(`${func}: BEGIN`);
    for (const [ev_key, ev_target] of ev_map) {
        const [_, node] = appEventTarget(ev_key, func);
        OUT.debug(`${func}: target =`, ev_key, 'node =', node);
        for (const [type, ev_type] of ev_target) {
            for (const [callback, ev_callback] of ev_type) {
                for (const [_options, ev_options] of ev_callback) {
                    _debugEvent(func, 'remove', type, ev_key, callback);
                    node.removeEventListener(type, callback, ev_options);
                }
            }
        }
    }
    OUT.debug(`${func}: END`);
    ev_map.clear();
}

// ============================================================================
// Functions - internal
// ============================================================================

/**
 * Log an occurrence of an action on an event.
 *
 * @param {string}             caller
 * @param {string}             action       "remember", "remove", or "listen".
 * @param {string}             type         Event type.
 * @param {string|EventTarget} [target]
 * @param {function|EventListenerOrEventListenerObject} [callback]
 * @param {EventTarget}        [node]
 */
function _debugEvent(caller, action, type, target, callback, node) {
    const args  = { target: target, callback: callback, node: node };
    const parts = [];
    Object.entries(args).forEach(([k, v]) => v && parts.push(`; ${k} =`, v));
    OUT.debug(`${caller}: ${action} event '${type}'`, ...parts);
}
