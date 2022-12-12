// app/assets/javascripts/shared/html.js
//
// noinspection JSUnusedGlobalSymbols


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

/**
 * Conversion of character to HTML entity.
 *
 * @readonly
 * @type {StringTable}
 */
export const HTML_ENTITY = {
    "'": '&apos;',
    '"': '&quot;',
    '&': '&amp;',
    '<': '&lt;',
    '>': '&gt;',
};

// ============================================================================
// Functions
// ============================================================================

/**
 * Transform a string into one that can be used wherever HTML is expected.
 *
 * @param {string} text
 *
 * @returns {string}
 */
export function htmlEncode(text) {
    const str = text.toString().trim();
    return [...str].map(c => HTML_ENTITY[c] || c).join('');
}

/**
 * Safely transform HTML-encoded text.
 *
 * @param {string} text
 *
 * @returns {string}
 */
export function htmlDecode(text) {
    const str = text.toString().trim();
    const doc = str && new DOMParser().parseFromString(str, 'text/html');
    return doc?.documentElement?.textContent;
}

// ============================================================================
// Functions
// ============================================================================

/**
 * Return all elements and descendents which match.
 *
 * @param {Selector} target
 * @param {Selector} match
 *
 * @returns {jQuery}
 */
export function allMatching(target, match) {
    //console.log(`allMatching: match = "${match}"; target =`, target);
    const $target = $(target);
    return $target.filter(match).add($target.find(match));
}

/**
 * Return the target if it matches or all descendents that match.
 *
 * @param {Selector} target
 * @param {Selector} match
 *
 * @returns {jQuery}
 */
export function selfOrDescendents(target, match) {
    //console.log(`selfOrDescendents: match = "${match}"; target =`, target);
    const $target = $(target);
    return $target.is(match) ? $target : $target.find(match);
}

/**
 * Return the target if it matches or the first parent that matches.
 *
 * @param {Selector} target
 * @param {Selector} match
 * @param {string}   [caller]     Name of caller (for diagnostics).
 *
 * @returns {jQuery}
 */
export function selfOrParent(target, match, caller) {
    //console.log(`selfOrParent: match = "${match}"; target =`, target);
    const func = caller || 'selfOrParent';
    const $t   = $(target);
    return $t.is(match) ? single($t, func) : $t.parents(match).first();
}

/**
 * Ensure that the target resolves to exactly one element.
 *
 * @param {Selector} target
 * @param {string}   [caller]     Name of caller (for diagnostics).
 *
 * @returns {jQuery}
 */
export function single(target, caller) {
    const $element = $(target);
    const count    = $element.length;
    if (count === 1) {
        return $element;
    } else {
        console.warn(`${caller}: ${count} results; 1 expected`);
        return $element.first();
    }
}

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
    const $element = (tag[0] === '<') ? $(tag) : $(`<${tag}>`);
    prop.class   && $element.addClass(cssClass(prop.class));
    prop.type    && $element.attr('type',  prop.type);
    prop.tooltip && $element.attr('title', prop.tooltip);

    if      (typeof prop.html  === 'string') { $element.html(prop.html)  }
    else if (typeof prop.label === 'string') { $element.text(prop.label) }
    else if (typeof prop.text  === 'string') { $element.text(prop.text)  }
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
        const $element = $(this);
        const link     = isDefined($element.attr('href'));
        const input    = link  || isDefined($element.attr('type'));
        const tabbable = input || isDefined($element.attr('tabindex'));
        if (!tabbable) {
            $element.attr('tabindex', 0);
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
    const b = (base !== '*') && base;
    let r, a;
    if (typeof root === 'boolean') {
        r = null;
        a = !!root;
    } else {
        r = (root !== '*') && root;
        a = !!all;
    }
    const selector = a ? '*' : ':visible';
    const $base    = (r && b) ? $(r).find(b) : $(r || b || 'body');
    return $base.find(selector).filter((_, e) => (e.tabIndex >= 0));
}

// ============================================================================
// Functions - attributes
// ============================================================================

/**
 * HTML attributes which should be made unique.
 *
 * @see https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input [input]
 * @see https://developer.mozilla.org/en-US/docs/Web/HTML/Element/label [label]
 * @see https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA/Attributes#relationship_attributes [aria]
 *
 * @type {string[]}
 */
export const ID_ATTRIBUTES = [
    'aria-activedescendant',
    'aria-controls',
    'aria-describedby',
    'aria-details',
    'aria-errormessage',
    'aria-flowto',
    'aria-labelledby',
    'aria-owns',
    'for',                      // @see [label]#attr-for
    'form',                     // @see [input]#form
    'id',                       // @see [input]#id
    'list',                     // @see [input]#list
  //'name',                     // @note Must *not* be included.
];

/**
 * Make attributes unique within an element.
 *
 * @param {Selector}      element
 * @param {string|number} unique
 * @param {string[]}      [attributes]  Default: {@link ID_ATTRIBUTES}
 * @param {boolean}       [append_only]
 */
export function uniqAttrs(element, unique, attributes, append_only) {
    const $element = $(element);
    const attrs    = attributes || ID_ATTRIBUTES;
    attrs.forEach(name => {
        const old_attr = $element.attr(name);
        if (isDefined(old_attr)) {
            const new_attr = uniqAttr(old_attr, unique, append_only);
            $element.attr(name, new_attr);
        }
    });
}

/**
 * Make an attribute value unique.
 *
 * @param {string}        value
 * @param {string|number} unique
 * @param {boolean}       [append_only]
 *
 * @returns {string}
 */
export function uniqAttr(value, unique, append_only) {
    if (!append_only && (/-0$/.test(value) || /-\d+-\d+$/.test(value))) {
        return value.replace(/-\d+$/, `-${unique}`);
    } else {
        return `${value}-${unique}`;
    }
}
