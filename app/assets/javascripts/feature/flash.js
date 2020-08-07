// app/assets/javascripts/feature/flash.js

// ============================================================================
// Constants
// ============================================================================

/**
 * Container element for flash messages.
 *
 * @constant {string}
 */
var FLASH_CONTAINER_CSS = 'flash-messages';

/**
 * Selector root for flash messages.
 *
 * @constant {string}
 */
var FLASH_ROOT_SELECTOR = '.' + FLASH_CONTAINER_CSS;

// ============================================================================
// Variables
// ============================================================================

/**
 * Control  display of flash messages by type.
 *
 * @type {object}
 */
var show_flash = {
    messages: true,
    errors:   true
};

// ============================================================================
// Functions
// ============================================================================

/**
 * The flash message container.
 *
 * @return {jQuery}
 */
function flashContainer() {
    return $(FLASH_ROOT_SELECTOR);
}

/**
 * Prevent flash messages from being generated.
 *
 * @param {boolean} [all]
 */
function suppressFlash(all) {
    // noinspection AssignmentResultUsedJS, NestedAssignmentJS
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
 */
function enableFlash(all) {
    // noinspection AssignmentResultUsedJS, NestedAssignmentJS
    switch (all) {
        case false: suppressFlash(true);                                break;
        case true:  show_flash.messages = show_flash.errors = true;     break;
        default:    show_flash.messages = true;                         break;
    }
}

/**
 * Replace all flashes messages with a new one.
 *
 * If show_flash.messages is not *true* then no actions will be taken.
 *
 * @param {string} text
 * @param {string} [type]
 * @param {string} [role]
 * @param {jQuery} [fc]               Default: `{@link flashContainer}()`
 */
function flashMessage(text, type, role, fc) {
    if (show_flash.messages) {
        var $fc = clearFlash(fc);
        addFlashMessage(text, type, role, $fc);
    }
}

/**
 * Replace all flashes messages with a new flash error message.
 *
 * If show_flash.errors is not *true* then no actions will be taken.
 *
 * @param {string} text
 * @param {string} [type]
 * @param {string} [role]
 * @param {jQuery} [fc]               Default: `{@link flashContainer}()`
 */
function flashError(text, type, role, fc) {
    if (show_flash.errors) {
        var $fc = clearFlash(fc);
        addFlashError(text, type, role, $fc);
    }
}

/**
 * Display flash message container.
 *
 * @param {jQuery} [fc]               Default: `{@link flashContainer}()`
 *
 * @return {jQuery}
 */
function showFlash(fc) {
    var $fc = fc || flashContainer();
    return $fc.removeClass('hidden').removeClass('invisible');
}

/**
 * Hide flash message container.
 *
 * @param {jQuery} [fc]               Default: `{@link flashContainer}()`
 *
 * @return {jQuery}
 */
function hideFlash(fc) {
    var $fc = fc || flashContainer();
    return $fc.addClass('hidden');
}

/**
 * Remove all flash messages and hide the flash message container.
 *
 * @param {jQuery} [fc]               Default: `{@link flashContainer}()`
 *
 * @return {jQuery}
 */
function clearFlash(fc) {
    var $fc = hideFlash(fc);
    $fc.children().remove();
    return $fc;
}

/**
 * Indicate whether no flash message(s) are present.
 *
 * @param {jQuery} [fc]               Default: `{@link flashContainer}()`
 *
 * @return {boolean}
 */
function flashEmpty(fc) {
    var $fc = fc || flashContainer();
    return $fc.is(':empty');
}

/**
 * Indicate whether flashes are hidden.
 *
 * @param {jQuery} [fc]               Default: `{@link flashContainer}()`
 *
 * @return {boolean}
 */
function flashHidden(fc) {
    var $fc = fc || flashContainer();
    return $fc.hasClass('hidden') || $fc.hasClass('invisible')
}

// noinspection JSUnusedGlobalSymbols
/**
 * Indicate whether flash message(s) are being displayed.
 *
 * @param {jQuery} [fc]               Default: `{@link flashContainer}()`
 *
 * @return {boolean}
 */
function flashDisplayed(fc) {
    var $fc = fc || flashContainer();
    return !flashHidden($fc) && !flashEmpty($fc);
}

/**
 * Add a flash message, un-hiding the flash message container if needed.
 *
 * @param {string} text
 * @param {string} [type]
 * @param {string} [role]
 * @param {jQuery} [fc]               Default: `{@link flashContainer}()`
 */
function addFlashMessage(text, type, role, fc) {
    var css_class = type || 'notice';
    var aria_role = role || 'alert';
    var msg  = text ? text.replace("\n", '<br/>') : '???';
    var $msg = $('<p>').addClass(css_class).attr('role', aria_role).html(msg);
    showFlash(fc).append($msg);
}

/**
 * Add a flash error message, un-hiding the flash message container if needed.
 *
 * @param {string} text
 * @param {string} [type]
 * @param {string} [role]
 * @param {jQuery} [fc]               Default: `{@link flashContainer}()`
 */
function addFlashError(text, type, role, fc) {
    var css_class = type || 'alert';
    var aria_role = role || 'alert';
    addFlashMessage(text, css_class, aria_role, fc);
}

// ============================================================================
// Functions - server flash messages
// ============================================================================

/**
 * Get the message(s) to display which are passed back from the server via the
 * 'X-Flash-Message' header.
 *
 * @param {XMLHttpRequest} xhr
 *
 * @return {array}
 *
 * @see "UploadController#post_response"
 */
function extractFlashMessage(xhr) {
    var lines = [];
    var flash_data = xhr && xhr.getResponseHeader('X-Flash-Message');
    if (flash_data) {
        try {
            var messages = JSON.parse(flash_data);
            if (messages instanceof Array) {
                messages.forEach(function(msg) {
                    lines.push(msg.toString());
                });
            } else if (typeof messages === 'object') {
                $.each(messages, function(k, v) {
                    lines.push('' + k + ': ' + v);
                });
            } else {
                lines.push(messages.toString());
            }
        }
        catch (err) {
            console.warn('extractFlashMessage:', err);
            lines.push(flash_data.toString());
        }
    }
    return lines;
}
