// app/assets/javascripts/shared/accessibility.js


import { isDefined, isPresent, notDefined }    from './definitions'
import { handleClickAndKeypress, handleEvent } from './events'
import { attributeSelector }                   from './html'
import { deepFreeze }                          from './objects'


// ============================================================================
// Constants
// ============================================================================

/**
 * Tags of elements that can receive focus.
 *
 * @readonly
 * @type {string[]}
 */
const FOCUS_ELEMENTS =
    deepFreeze(['a', 'area', 'button', 'input', 'select', 'textarea']);

/**
 * Selector for FOCUS_ELEMENTS elements.
 *
 * @readonly
 * @type {string}
 */
const FOCUS_ELEMENTS_SELECTOR = FOCUS_ELEMENTS.join(', ');

/**
 * Attributes indicating that an element should receive focus.
 *
 * @readonly
 * @type {string[]}
 */
const FOCUS_ATTRIBUTES =
    deepFreeze(['href', 'controls', 'data-path', 'draggable', 'tabindex']);

/**
 * Selector for FOCUS_ATTRIBUTES elements.
 *
 * @readonly
 * @type {string}
 */
const FOCUS_ATTRIBUTES_SELECTOR = attributeSelector(FOCUS_ATTRIBUTES);

/**
 * Selector for focusable elements.
 *
 * @readonly
 * @type {string}
 */
const FOCUS_SELECTOR =
    FOCUS_ELEMENTS_SELECTOR + ', ' + FOCUS_ATTRIBUTES_SELECTOR;

/**
 * Attributes indicating that an element should NOT receive focus.
 *
 * @readonly
 * @type {string[]}
 */
const NO_FOCUS_ATTRIBUTES = deepFreeze(['tabindex="-1"']);

/**
 * Selector for focusable elements that should not receive focus.
 *
 * @readonly
 * @type {string}
 */
const NO_FOCUS_SELECTOR = attributeSelector(NO_FOCUS_ATTRIBUTES);

// ============================================================================
// Functions
// ============================================================================

/**
 * For "buttons" or "links" which are not <a> tags (or otherwise don't
 * respond by default to a carriage return as an equivalent to a click).
 *
 * @param {Selector}       selector  Specification of node(s) containing
 *                                     elements which must respond to a
 *                                     carriage return like a mouse click.
 *
 * @param {boolean}        [direct]  If *true* then the target is the nodes
 *                                     indicated by *selector* and not the
 *                                     descendents of those nodes.
 *
 * @param {string|boolean} [match]   If *false* then $(selector) specifies
 *                                     the target elements directly; if
 *                                     *true* or missing then all focusable
 *                                     elements at or below $(selector) are
 *                                     chosen; if a string then it is used
 *                                     instead of FOCUS_ATTRIBUTES_SELECTOR
 *
 * @param {string|boolean} [except]  If *false* then all matches are
 *                                     chosen; otherwise elements matching
 *                                     FOCUS_ELEMENTS_SELECTOR are
 *                                     eliminated.  In either case,
 *                                     elements with tabindex == -1 are
 *                                     skipped. Default: elements like <a>.
 *
 * @returns {jQuery}
 */
export function handleKeypressAsClick(selector, direct, match, except) {

    /**
     * Determine the target(s) based on the *direct* argument.
     *
     * @type {jQuery}
     */
    let $elements = (typeof selector === 'number') ? $(this) : $(selector);

    // Apply match criteria to select all elements that would be expected to
    // receive a keypress based on their attributes.
    const criteria = [];
    if (match && (typeof match === 'string')) {
        criteria.push(match);
    } else if (direct || (match === true) || notDefined(match)) {
        criteria.push(FOCUS_ATTRIBUTES_SELECTOR);
    }
    if (isPresent(criteria)) {
        const sel = criteria.join(', ');
        $elements = direct ? $elements.filter(sel) : $elements.find(sel);
    }

    // Ignore elements that won't be reached by tabbing to them.
    const exceptions = [NO_FOCUS_SELECTOR];
    if (except && (typeof except === 'string')) {
        exceptions.push(except);
    }
    if (isPresent(exceptions)) {
        $elements = $elements.not(exceptions.join(', '));
    }

    // Attach the handler to any remaining elements, ensuring that the
    // handler is not added twice.
    return handleEvent($elements, 'keydown', handleKeypress);
}

/**
 * Translate a carriage return to a click.
 *
 * Not intended for links (where the key press will be handled by the browser
 * itself).
 *
 * @param {jQuery.Event|KeyboardEvent} event
 *
 * @returns {boolean|undefined}
 */
function handleKeypress(event) {
    const key = event.key;
    if (key === 'Enter') {
        const $target = $(event.target);
        const href    = $target.attr('href');
        if (!href || (href === '#')) {
            $target.click();
            $target.focusin();
            return false;
        }
    }
}

/**
 * Allow a click anywhere within the element holding a label/button pair
 * to be delegated to the enclosed input.  This broadens the "click target"
 * and allows clicks in the "void" between the input and the label to be
 * associated with the input element that the user intended to click.
 *
 * @param {Selector} element
 */
export function delegateInputClick(element) {

    const func     = 'delegateInputClick';
    const $element = $(element);
    const $input   = $element.find('[type="radio"],[type="checkbox"]');
    const count    = $input.length;

    if (count < 1) {
        console.error(`${func}: no targets within:`);
        console.log(element);
        return;
    } else if (count > 1) {
        console.warn(`${func}: ${count} targets`);
    }

    handleClickAndKeypress($element, function(event) {
        if (event.target !== $input[0]) {
            event.preventDefault();
            $input.click();
        }
    });
}

/**
 * Indicate whether the element referenced by the selector can have tab focus.
 *
 * @param {Selector} element
 *
 * @returns {boolean}
 */
export function focusable(element) {
    return isPresent($(element).filter(FOCUS_SELECTOR).not(NO_FOCUS_SELECTOR));
}

/**
 * The focusable elements contained within *element*.
 *
 * @param {Selector} element
 *
 * @returns {jQuery}
 */
/*
export function focusableIn(element) {
    return $(element).find(FOCUS_SELECTOR).not(NO_FOCUS_SELECTOR);
}
*/

/**
 * Hide/show elements by adding/removing the CSS "invisible" class.
 *
 * If *visible* is not given then visibility is toggled to the opposite state.
 *
 * @param {Selector} element
 * @param {boolean}  [visible]
 *
 * @returns {boolean} If *true* then *element* is becoming visible.
 */
export function toggleVisibility(element, visible) {
    const invisibility_marker = 'invisible';
    const $element = $(element);
    let make_visible, hidden, visibility;
    if (isDefined(visible)) {
        make_visible = visible;
    } else if (isDefined((hidden = $element.attr('aria-hidden')))) {
        make_visible = hidden && (hidden !== 'false');
    } else if (isDefined((visibility = $element.css('visibility')))) {
        make_visible = (visibility === 'hidden');
    } else {
        make_visible = $element.hasClass(invisibility_marker);
    }
    $element.toggleClass(invisibility_marker, !make_visible);
    $element.attr('aria-hidden', !make_visible);
    return make_visible;
}
