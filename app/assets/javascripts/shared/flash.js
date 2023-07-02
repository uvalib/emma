// app/assets/javascripts/shared/flash.js
//
// noinspection JSUnusedGlobalSymbols


import { AppDebug }                          from '../application/debug';
import { handleClickAndKeypress }            from './accessibility';
import { arrayWrap }                         from './arrays';
import { selector }                          from './css';
import { isMissing, isPresent }              from './definitions';
import { handleEvent, isEvent, windowEvent } from './events';
import { noScroll, scrollIntoView }          from './html';
import { keyCombo }                          from './keyboard';
import { SECONDS }                           from './time';
import { HEAVY_X }                           from './unicode';


const MODULE = 'Flash';
const DEBUG  = true;

AppDebug.file('shared/flash', MODULE, DEBUG);

/**
 * Console output functions for this module.
 */
const OUT = AppDebug.consoleLogging(MODULE, DEBUG);

// ============================================================================
// Type definitions
// ============================================================================

/**
 * @typedef {object} FlashOptions
 *
 * @property {function} [onClose]   Callback when the flash is closed. <p/>
 * @property {Selector} [refocus]   Element that gets focus after close. <p/>
 * @property {string}   [type]      Override flash type. <p/>
 * @property {string}   [role]      Override ARIA role. <p/>
 * @property {Selector} [fc]        Specify flash container. <p/>
 * @property {jQuery}   [$fc]       Internal use. <p/>
 */

// ============================================================================
// Constants
// ============================================================================

/**
 * If **false**, the flash container is inline.
 * If **true** it appears above the main page content.
 *
 * @type {boolean}
 */
const FLOAT = true;

/**
 * Container element for flash messages.
 *
 * @readonly
 * @type {string}
 */
const CONTAINER_CLASS = 'flash-messages';
const INLINE_CLASS    = 'inline';
const FLOATING_CLASS  = 'floating';
const NO_RESET_CLASS  = 'no-reset';
const VISIBLE_MARKER  = 'visible';
const ITEM_CLASS      = 'flash';
const CLOSER_CLASS    = 'closer';

/**
 * Selector root for flash messages.
 *
 * @readonly
 * @type {Selector}
 */
const CONTAINER  = selector(CONTAINER_CLASS);
const INLINE     = selector(INLINE_CLASS);
const FLOATING   = selector(FLOATING_CLASS);
const NO_RESET   = selector(NO_RESET_CLASS);
const VISIBLE    = selector(VISIBLE_MARKER);
const FLASH_ITEM = selector(ITEM_CLASS);
const CLOSER     = selector(CLOSER_CLASS);

/**
 * Default display of flash messages by type.
 *
 * @type {{messages: boolean, errors: boolean}}
 */
const DEFAULT_SHOW = {
    messages: true,
    errors:   true,
};

// ============================================================================
// Variables
// ============================================================================

/**
 * Control display of flash messages by type.
 *
 * @type {object}
 */
const show_flash = DEFAULT_SHOW;

// ============================================================================
// Functions
// ============================================================================

/**
 * The flash message container.
 *
 * @param {Selector} [selector]       Default: {@link CONTAINER}.
 *
 * @returns {jQuery}
 */
export function flashContainer(selector) {
    if (selector instanceof jQuery) {
        return selector;
    } else if (typeof selector === 'string') {
        return $(selector);
    } else {
        return $(CONTAINER);
    }
}

/**
 * Initialize the flash message container.
 *
 * @param {Selector} [fc]             Default: {@link flashContainer}.
 *
 * @returns {boolean}                 **false** if only inline flash.
 *
 * @see file:app/views/layouts/_flash.html.erb
 */
export function flashInitialize(fc) {
    //OUT.debug('flashInitialize: fc =', fc);
    const $fc    = flashContainer(fc);
    const $items = $fc.find(FLASH_ITEM);
    let $first_closer;
    if (floating($fc)) {
        $items.each((_, item) => {
            const $item = $(item);
            let $closer = $item.find(CLOSER);
            if (isMissing($closer)) {
                $closer = makeCloser();
                const $m = $('<div>').addClass('text').html($item.html());
                $item.empty().append($m, $closer);
            } else {
                initializeCloser($closer);
            }
            $first_closer ||= $closer;
            initializeFlashItem($item);
        });
        $fc.toggleClass(FLOATING_CLASS, true);
    }
    if (isPresent($items)) {
        $first_closer?.focus();
        showFlash($fc, true);
    }
    return !!$first_closer;
}

/**
 * Clear the flash message container on refreshed pages.
 *
 * @param {Selector} [fc]             Default: {@link flashContainer}.
 */
export function flashReset(fc) {
    //OUT.debug('flashReset: fc =', fc);
    const $fc = flashContainer(fc);
    if (!flashEmpty($fc)) {
        if ($fc.is(NO_RESET)) {
            showFlash($fc);
        } else {
            clearFlash($fc);
        }
    }
    if (floating($fc)) {
        $fc.toggleClass(FLOATING_CLASS, true);
    }
}

/**
 * Prevent flash messages from being generated.
 *
 * @param {boolean} [all]
 *
 * @returns {void}
 */
export function suppressFlash(all) {
    //OUT.debug('suppressFlash: all =', all);
    switch (all) {
        case false: enableFlash(true);                                  break;
        case true:  show_flash.messages = show_flash.errors = false;    break;
        default:    show_flash.messages = false;                        break;
    }
}

/**
 * Restore generation of flash messages.
 *
 * @param {boolean} [all]
 *
 * @returns {void}
 */
export function enableFlash(all) {
    //OUT.debug('enableFlash: all =', all);
    switch (all) {
        case false: suppressFlash(true);                                break;
        case true:  show_flash.messages = show_flash.errors = true;     break;
        default:    show_flash.messages = true;                         break;
    }
}

/**
 * Replace all flashes messages with a new one. <p/>
 *
 * If show_flash.messages is not **true** then no actions will be taken.
 *
 * @param {string|string[]} text
 * @param {FlashOptions}    [opt]
 *
 * @returns {jQuery}                  The flash container.
 */
export function flashMessage(text, opt = {}) {
    //OUT.debug('flashMessage:', text, opt);
    const $fc = opt.$fc || flashContainer(opt.fc);
    if (show_flash.messages) {
        $fc.empty();
        addFlashMessage(text, { ...opt, $fc: $fc });
    }
    return $fc;
}

/**
 * Replace all flashes messages with a new flash error message. <p/>
 *
 * If show_flash.errors is not **true** then no actions will be taken.
 *
 * @param {string|string[]} text
 * @param {FlashOptions}    [opt]
 *
 * @returns {jQuery}                  The flash container.
 */
export function flashError(text, opt = {}) {
    //OUT.debug('flashError:', text, opt);
    const $fc = opt.$fc || flashContainer(opt.fc);
    if (show_flash.errors) {
        $fc.empty();
        addFlashError(text, { ...opt, $fc: $fc });
    }
    return $fc;
}

/**
 * Remove all flash messages and hide the flash message container.
 *
 * @param {Selector} [fc]             Default: {@link flashContainer}.
 *
 * @returns {jQuery}                  The flash container.
 */
export function clearFlash(fc) {
    //OUT.debug('clearFlash: fc =', fc);
    return hideFlash(fc).empty();
}

/**
 * Indicate whether no flash message(s) are present.
 *
 * @param {Selector} [fc]             Default: {@link flashContainer}.
 *
 * @returns {boolean}
 */
export function flashEmpty(fc) {
    const $fc    = flashContainer(fc);
    const $items = $fc.find(FLASH_ITEM);
    return isMissing($items);
}

/**
 * Indicate whether flashes are hidden.
 *
 * @param {Selector} [fc]             Default: {@link flashContainer}.
 *
 * @returns {boolean}
 */
export function flashHidden(fc) {
    return !flashContainer(fc).is(VISIBLE);
}

// ============================================================================
// Functions - internal
// ============================================================================

/**
 * Indicate whether the flash containing is a floating container.
 *
 * @param {Selector} [fc]             Default: {@link flashContainer}.
 *
 * @returns {boolean}
 */
function floating(fc) {
    const $fc = flashContainer(fc);
    return FLOAT && !$fc.is(INLINE) || $fc.is(FLOATING);
}

/**
 * Display flash message container.
 *
 * @param {Selector} [fc]             Default: {@link flashContainer}.
 * @param {boolean}  [force]          Don't check {@link flashHidden}
 *
 * @returns {jQuery}                  The flash container.
 */
function showFlash(fc, force) {
    //OUT.debug('showFlash: fc =', fc, force);
    const $fc   = flashContainer(fc);
    const show  = force || flashHidden($fc);
    const float = floating($fc);
    if (show && float) {
        noScroll(() => toggleFlashContainer($fc, true));
        monitorWindowEvents(true);
    } else if (show) {
        toggleFlashContainer($fc, true);
    }
    if (!float) {
        scrollIntoView($fc);
    }
    return $fc;
}

/**
 * Hide flash message container.
 *
 * @param {Selector} [fc]             Default: {@link flashContainer}.
 * @param {boolean}  [force]          Don't check {@link flashHidden}
 *
 * @returns {jQuery}                  The flash container.
 */
function hideFlash(fc, force) {
    //OUT.debug('hideFlash: fc =', fc, force);
    const $fc = flashContainer(fc);
    if (force || !flashHidden($fc)) {
        if (floating($fc)) {
            monitorWindowEvents(false);
        }
        toggleFlashContainer($fc, false);
        const option = getOptionsData($fc);
        if (option) {
            option.onClose?.();
            option.refocus?.focus();
            clearOptionsData($fc);
        }
    }
    return $fc;
}

/**
 * Show/hide the flash container. <p/>
 *
 * (Only for use within {@link showFlash} and {@link hideFlash}.
 *
 * @param {jQuery}  $fc
 * @param {boolean} show
 *
 * @return {jQuery}
 */
function toggleFlashContainer($fc, show) {
    //OUT.debug('toggleFlashContainer: fc =', fc, show);
    if (show) {
        $fc.removeAttr('aria-hidden');
    } else {
        $fc.attr('aria-hidden', true);
    }
    return $fc.toggleClass(VISIBLE_MARKER, show);
}

// ============================================================================
// Functions - flash items
// ============================================================================

/**
 * Display a new flash message.
 *
 * @param {string|string[]} text
 * @param {FlashOptions}    [opt]
 *
 * @returns {jQuery}                  The flash container.
 */
export function addFlashMessage(text, opt) {
    //OUT.debug('addFlashMessage:', text, opt);
    return addFlashItem(text, { type: 'notice', ...opt });
}

/**
 * Display a new flash error message.
 *
 * @param {string|string[]} text
 * @param {FlashOptions}    [opt]
 *
 * @returns {jQuery}                  The flash container.
 */
export function addFlashError(text, opt) {
    //OUT.debug('addFlashError:', text, opt);
    return addFlashItem(text, { type: 'alert', ...opt });
}

// ============================================================================
// Functions - flash items - internal
// ============================================================================

/**
 * Add a flash item, un-hiding the flash message container if needed.
 *
 * @param {string|string[]} text
 * @param {FlashOptions}    [opt]
 *
 * @returns {jQuery}                  The flash container.
 */
function addFlashItem(text, opt = {}) {
    //OUT.debug('addFlashItem:', text, opt);
    const css_class = `${ITEM_CLASS} ${opt.type}`.trim();
    const aria_role = opt.role || 'alert';
    const plain     = (typeof text === 'string') && !text.startsWith('<');
    const lines     = plain ? text.split(/<br\/?>|\n/) : arrayWrap(text);
    const message   = lines.map(v => v?.toString ? v?.toString() : '???');
    const $message  = $('<div>').html(message.join('<br/>'));

    let $item, $closer;
    const $fc = opt.$fc || flashContainer(opt.fc);
    if (floating($fc)) {
        $message.addClass('text');
        $closer = makeCloser();
        $item   = $('<div>').append($message, $closer);
    } else {
        $item   = $message;
    }
    initializeFlashItem($item).addClass(css_class).attr('role', aria_role);

    setOptionsData($fc, opt);
    showFlash($fc).append($item);
    $closer?.focus();
    return $fc;
}

/**
 * Setup event handlers a flash item.
 *
 * @param {jQuery} $item
 *
 * @returns {jQuery}
 */
function initializeFlashItem($item) {
    //OUT.debug('initializeFlashItem:', $item);
    handleEvent($item, 'keyup',     onKeyUpFlashItem);
    handleEvent($item, 'mousedown', onMouseDownFlashItem);
    return $item;
}

/**
 * Return the flash item associated with the argument.
 *
 * @param {jQuery.Event|Event|Selector} arg
 *
 * @returns {jQuery}
 */
function flashItem(arg) {
    const $elem = isEvent(arg) ? $(arg.currentTarget || arg.target) : $(arg);
    return $elem.is(FLASH_ITEM) ? $elem : $elem.parents(FLASH_ITEM).first();
}

/**
 * Callback invoked to remove a flash item from view.
 *
 * @param {jQuery.Event} event
 */
function closeFlashItem(event) {
    OUT.debug('closeFlashItem: event =', event);
    flashItem(event).remove();
    const $fc = flashContainer();
    if (flashEmpty($fc)) {
        hideFlash($fc, true);
    }
}

/**
 * Allow the **Escape** key to close a specific flash item.
 *
 * @param {jQuery.Event|KeyboardEvent} event
 */
function onKeyUpFlashItem(event) {
    const key = keyCombo(event);
    OUT.debug(`onKeyUpFlashItem: "${key}"; event =`, event);
    if (key === 'Escape') {
        event.stopImmediatePropagation();
        closeFlashItem(event);
    }
}

/**
 * Allow mouse down inside a flash item to avoid closing any flash item by
 * preventing {@link onMouseDownWindow} from being invoked.
 *
 * @param {jQuery.Event|KeyboardEvent} event
 */
function onMouseDownFlashItem(event) {
    OUT.debug('onMouseDownFlashItem: event =', event);
    event.stopPropagation();
}

// ============================================================================
// Functions - closer control - internal
// ============================================================================

const OPTIONS_DATA  = 'flashOptions';

/**
 * Get the options for this flash occurrence.
 *
 * @param {jQuery} [$fc]
 *
 * @returns {FlashOptions|undefined}
 */
function getOptionsData($fc) {
    return flashContainer($fc).data(OPTIONS_DATA);
}

/**
 * Set the options for this flash occurrence.
 *
 * @param {jQuery}       [$fc]
 * @param {FlashOptions} [opt]        If missing the data is cleared.
 *
 * @returns {function|undefined}
 */
function setOptionsData($fc, opt) {
    if (opt) {
        $fc.data(OPTIONS_DATA, { ...opt });
    } else {
        $fc.removeData(OPTIONS_DATA);
    }
}

/**
 * Clear the options for this flash occurrence.
 *
 * @param {jQuery} [$fc]
 */
function clearOptionsData($fc) {
    setOptionsData($fc, undefined);
}

/**
 * Generate a flash closer control.
 *
 * @returns {jQuery}
 */
function makeCloser() {
    //OUT.debug('makeCloser');
    const $closer = $('<button>').addClass('closer').text(HEAVY_X);
    return initializeCloser($closer);
}

/**
 * Setup event handlers for a flash closer control.
 *
 * @param {jQuery} $closer
 *
 * @returns {jQuery}
 */
function initializeCloser($closer) {
    //OUT.debug('initializeCloser: closer =', $closer);
    handleClickAndKeypress($closer, closeFlashItem);
    return $closer;
}

// ============================================================================
// Functions - window events - internal
// ============================================================================

/**
 * Window events that could result in clearing all flash messages.
 *
 * @type {Object.<string,function(jQuery.Event)>}
 */
const WINDOW_EVENTS = {
    'keyup':     onKeyUpWindow,
    'mousedown': onMouseDownWindow,
};

/**
 * Begin monitoring for window events that could result in removing all flash
 * messages from the display.
 *
 * @param {boolean} [on]
 */
function monitorWindowEvents(on = true) {
    OUT.debug('monitorWindowEvents: on =', on);
    for (const [type, callback] of Object.entries(WINDOW_EVENTS)) {
        windowEvent(type, callback, { listen: on });
    }
}

/**
 * Allow the **Escape** key to close all flash items.
 *
 * @param {jQuery.Event|KeyboardEvent} event
 */
function onKeyUpWindow(event) {
    const key = keyCombo(event);
    OUT.debug(`onKeyUpWindow: "${key}"; event =`, event);
    if (key === 'Escape') {
        event.stopImmediatePropagation();
        clearFlash();
    }
}

/**
 * Allow mouse down outside of a flash item to close all flash items.
 *
 * @param {jQuery.Event|MouseEvent} event
 */
function onMouseDownWindow(event) {
    OUT.debug('onMouseDownWindow: event =', event);
    clearFlash();
}

// ============================================================================
// Functions - server flash messages
// ============================================================================

/**
 * Get the message(s) to display which are passed back from the server via the
 * "X-Flash-Message" header.
 *
 * @param {XMLHttpRequest} xhr
 *
 * @returns {string[]}
 *
 * @see "UploadController#post_response"
 */
export function extractFlashMessage(xhr) {
    const func  = 'extractFlashMessage'; OUT.debug(`${func}: xhr =`, xhr);
    const lines = [];
    let text    = xhr?.getResponseHeader('X-Flash-Message') || '';
    text = text.startsWith('http') ? fetchFlashMessage(text) : xhrDecode(text);
    if (text.startsWith('{') || text.startsWith('[')) {
        try {
            const messages = JSON.parse(text);
            if (Array.isArray(messages)) {
                messages.forEach(msg => lines.push(`${msg}`));
            } else if (typeof messages === 'object') {
                $.each(messages, (k, v) => lines.push(`${k}: ${v}`));
            } else {
                lines.push(`${messages}`);
            }
        } catch (error) {
            OUT.warn(`${func}:`, error);
        }
    }
    return isPresent(lines) ? lines : text.split("\n");
}

/**
 * Decode a string used in HTTP message headers to transmit flash messages.
 *
 * @param {*} data
 *
 * @returns {string}
 *
 * @see "EncodingHelper#xhr_encode"
 */
export function xhrDecode(data) {
    //OUT.debug('xhrDecode: data =', data);
    if (isMissing(data)) { return '' }
    const string  = data.toString();
    const encoded = !!string.match(/%[0-9A-F][0-9A-F]/i);
    return (encoded ? decodeURIComponent(string) : string).trim();
}

/**
 * Synchronously fetch message content specified from a URL (specified via
 * "X-Flash-Message").
 *
 * @param {string} url
 *
 * @returns {string}
 */
export function fetchFlashMessage(url) {
    const func = 'fetchFlash'; //OUT.debug(`${func}: url =`, url);
    let error  = 'could not fetch message'; // TODO: I18n
    let content;

    function onSuccess(data) {
        if (isMissing(data)) {
            error = 'no data for message'; // TODO: I18n
        } else if (typeof(data) !== 'string') {
            error = `unexpected data type ${typeof data}`; // TODO: I18n
        } else {
            content = data;
        }
    }

    function onError(xhr, status, message) {
        error = `${status}: ${xhr.status} ${message}`;
        OUT.warn(`${func}:`, error);
    }

    $.ajax({
        url:      url,
        type:     'GET',
        dataType: 'text',
        async:    false,
        timeout:  3 * SECONDS,
        success:  onSuccess,
        error:    onError
    });
    return content || `[[ ${error} ]]`;
}
