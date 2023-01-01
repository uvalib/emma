// app/assets/javascripts/vendor/rails.js
//
// Load Rails UJS.


import { AppDebug }                   from '../application/debug';
import { appEventListener }           from '../application/setup';
import { documentEvent, windowEvent } from '../shared/events';
import Rails                          from '@rails/ujs';

export { Rails };


const MODULE = 'Rails';
const DEBUG  = true;

AppDebug.file('vendor/rails', MODULE, DEBUG);

// ============================================================================
// Functions - Rails UJS overrides
// ============================================================================

/**
 * Overrides the Rails UJS *delegate* function so that events are not
 * repeatedly attached with each Turbolinks page load.
 *
 * (For all observed uses of this function, the element parameter is always
 * {@link document}.)
 *
 * @param {EventTarget}                             element
 * @param {string|{selector:string,exclude:string}} selector
 * @param {string}                                  eventType
 * @param {function(Event)}                         handler
 */
function railsDelegate(element, selector, eventType, handler) {
    _debug(`DELEGATE '${eventType}' for`, selector, 'handler =', handler);

    function handlerDelegate(event) {
        const e = `DOCUMENT '${event.type}'`;
        let tgt = event.target;
        while (!(!(tgt instanceof Element) || Rails.matches(tgt, selector))) {
            tgt = tgt.parentNode;
        }
        let sel = selector;
        if (typeof sel === 'object') { sel = sel.selector }
        if (tgt instanceof Element) {
            if (handler.call(tgt, event) === false) {
                event.preventDefault();
                event.stopPropagation();
                _debug(e, 'STOPPED for', sel, '; event =', event);
            } else {
                _debug(e, 'CAUGHT for',  sel, '; event =', event);
            }
        } else {
            const len = sel.length;
            const max = 80;
            const etc = '...';
            if (len > max) { sel = sel.slice(0, (max - etc.length)) + etc }
            _debug(e, 'IGNORED for', sel);
        }
    }

    appEventListener(element, eventType, handlerDelegate);
}

/**
 * Overrides the Rails UJS *start* function so that window and document events
 * are not repeatedly attached with each Turbolinks page load.
 *
 * @returns {boolean}
 */
function railsStart() {
    _debug('START');
    if (window._rails_loaded) {
        throw new Error('rails-ujs has already been loaded!');
    }
    const delegate = (selector, eventType, handler) => {
        Rails.delegate(document, selector, eventType, handler);
    };

    delegate(Rails.linkDisableSelector,    'ajax:complete', Rails.enableElement);
    delegate(Rails.linkDisableSelector,    'ajax:stopped',  Rails.enableElement);

    delegate(Rails.buttonDisableSelector,  'ajax:complete', Rails.enableElement);
    delegate(Rails.buttonDisableSelector,  'ajax:stopped',  Rails.enableElement);

    delegate(Rails.linkClickSelector,      'click',         Rails.preventInsignificantClick);
    delegate(Rails.linkClickSelector,      'click',         Rails.handleDisabledElement);
    delegate(Rails.linkClickSelector,      'click',         Rails.handleConfirm);
    delegate(Rails.linkClickSelector,      'click',         Rails.disableElement);
    delegate(Rails.linkClickSelector,      'click',         Rails.handleRemote);
    delegate(Rails.linkClickSelector,      'click',         Rails.handleMethod);

    delegate(Rails.buttonClickSelector,    'click',         Rails.preventInsignificantClick);
    delegate(Rails.buttonClickSelector,    'click',         Rails.handleDisabledElement);
    delegate(Rails.buttonClickSelector,    'click',         Rails.handleConfirm);
    delegate(Rails.buttonClickSelector,    'click',         Rails.disableElement);
    delegate(Rails.buttonClickSelector,    'click',         Rails.handleRemote);

    delegate(Rails.inputChangeSelector,    'change',        Rails.handleDisabledElement);
    delegate(Rails.inputChangeSelector,    'change',        Rails.handleConfirm);
    delegate(Rails.inputChangeSelector,    'change',        Rails.handleRemote);

    delegate(Rails.formSubmitSelector,     'submit',        Rails.handleDisabledElement);
    delegate(Rails.formSubmitSelector,     'submit',        Rails.handleConfirm);
    delegate(Rails.formSubmitSelector,     'submit',        Rails.handleRemote);
    delegate(Rails.formSubmitSelector,     'submit',        function(e) {
        return setTimeout((function() {
            return Rails.disableElement(e);
        }), 13);
    });
    delegate(Rails.formSubmitSelector,     'ajax:send',     Rails.disableElement);
    delegate(Rails.formSubmitSelector,     'ajax:complete', Rails.enableElement);

    delegate(Rails.formInputClickSelector, 'click',         Rails.preventInsignificantClick);
    delegate(Rails.formInputClickSelector, 'click',         Rails.handleDisabledElement);
    delegate(Rails.formInputClickSelector, 'click',         Rails.handleConfirm);
    delegate(Rails.formInputClickSelector, 'click',         Rails.formSubmitButtonClick);

    documentEvent('DOMContentLoaded', Rails.refreshCSRFTokens);
    documentEvent('DOMContentLoaded', Rails.loadCSPNonce);

    windowEvent('pageshow', function() {
        _debug('window pageshow');
        // noinspection FunctionWithInconsistentReturnsJS
        const enable = (el) => {
            if (Rails.getData(el, 'ujs:disabled')) {
                _debug('ENABLE', el);
                return Rails.enableElement(el);
            }
        };
        Rails.$(Rails.formEnableSelector).forEach(el => enable(el));
        Rails.$(Rails.linkDisableSelector).forEach(el => enable(el));
    });

    return window._rails_loaded = true;
}

// ============================================================================
// Functions - other
// ============================================================================

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

// ============================================================================
// Rails UJS initialization
// ============================================================================

if (!window._rails_loaded) {
    _debug('LOAD');
    Rails.delegate = railsDelegate;
    Rails.start    = railsStart;
    Rails.start();
}
