// app/assets/javascripts/shared/html.js


import { cssClass }  from './css'
import { isDefined } from './definitions'


// ============================================================================
// Type definitions
// ============================================================================

/**
 * @typedef {Window.jQuery} jQuery
 */

/**
 * @typedef {jQuery|HTMLElement|EventTarget|string} Selector
 */

// ============================================================================
// Constants
// ============================================================================

/**
 * When replacing newlines with HTML breaks, it's important to retain the
 * newline itself so that `.text().split("\n")` can be used to reconstitute
 * arrays of values.
 *
 * @readonly
 * @type {string}
 */
export const HTML_BREAK = "<br/>\n";

// ============================================================================
// Functions
// ============================================================================

/**
 * Make a selector out of an array of attributes.
 *
 * @param {string[]} attributes
 *
 * @returns {string}
 */
export function attributeSelector(attributes) {
    const list = attributes.join('], [');
    return `[${list}]`;
}

/**
 * Safely transform HTML-encoded text.
 *
 * @param {string} text
 *
 * @returns {string}
 */
export function htmlDecode(text) {
    let str = text.toString().trim();
    let doc = str && new DOMParser().parseFromString(str, 'text/html');
    return doc?.documentElement?.textContent;
}

/**
 * If necessary scroll the indicated element so that it is within the viewport.
 *
 * @param {Selector} element
 *
 * @returns {jQuery}
 */
export function scrollIntoView(element) {
    const $element = $(element);
    const elem     = $element[0];
    if (elem) {
        const r = elem.getBoundingClientRect();
        const t = 0;
        const b = window.innerHeight || document.documentElement.clientHeight;
        if (r.top < t) {
            elem.scrollIntoView(true);
        } else if (r.bottom > b) {
            elem.scrollIntoView(false);
        }
    } else {
        console.error('scrollIntoView: empty', element);
    }
    return $element;
}

/**
 * For use in situations where actions cause an undesirable scroll.
 *
 * NOTE: This was discovered implementing the floating flash container. Firefox
 *  and MS Edge show it in the middle of the viewport as intended, but Chrome
 *  shifts to the top of the page first.  This locking strategy keeps it from
 *  doing that (whereas simply setting window.scroll() afterwards results in a
 *  "flashing" effect that is more severe as scrollY increases).
 *
 * @param {function} callback
 */
export function noScroll(callback) {
    const [current_x, current_y] = [window.scrollX, window.scrollY];
    const scroll_lock = () => window.scroll(current_x, current_y);
    window.addEventListener('scroll', scroll_lock);
    callback();
    setTimeout(() => window.removeEventListener('scroll', scroll_lock));
}

/**
 * Create an HTML element.
 *
 * @param {string|ElementProperties} element
 * @param {ElementProperties}        [properties]
 *
 * @returns {jQuery}
 */
export function create(element, properties) {
    const obj  = (typeof element === 'object');
    const prop = (obj ? element     : properties) || {};
    const tag  = (obj ? element.tag : element)    || 'div';

    // noinspection HtmlUnknownTag
    let $element = (tag[0] === '<') ? $(tag) : $(`<${tag}>`);
    prop.class   && $element.addClass(cssClass(prop.class));
    prop.type    && $element.attr('type',  prop.type);
    prop.tooltip && $element.attr('title', prop.tooltip);

    if      (typeof prop.html  === 'string') { $element.html(prop.html);  }
    else if (typeof prop.label === 'string') { $element.text(prop.label); }
    else if (typeof prop.text  === 'string') { $element.text(prop.text);  }
    return $element;
}

/**
 * Ensure the indicated element will be included in the tab order, adding a
 * tabindex attribute if necessary.
 *
 * @param {Selector} element
 */
export function ensureTabbable(element) {
    $(element).each(function() {
        let $e         = $(this);
        const link     = isDefined($e.attr('href'));
        const input    = link  || isDefined($e.attr('type'));
        const tabbable = input || isDefined($e.attr('tabindex'));
        if (!tabbable) {
            $e.attr('tabindex', 0);
        }
    });
}

/**
 * Find all elements within *base* (relative to *root*) that can be tabbed to.
 *
 * @param {Selector} [base]
 * @param {Selector} [root]
 * @param {boolean}  [all]            If *true*, count invisible items too.
 *
 * @returns {jQuery}
 */
export function findTabbable(base, root, all) {
    let b = (base !== '*') && base;
    let r, a;
    if (typeof root === 'boolean') {
        r = null;
        a = !!root;
    } else {
        r = (root !== '*') && root;
        a = !!all;
    }
    let selector = a ? '*' : ':visible';
    let $base    = (r && b) ? $(r).find(b) : $(r || b || 'body');
    return $base.find(selector).filter((_, e) => (e.tabIndex >= 0));
}
