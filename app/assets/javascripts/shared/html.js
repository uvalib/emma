// app/assets/javascripts/shared/html.js


import { isDefined } from '../shared/definitions'
import { cssClass }  from '../shared/css'


// ============================================================================
// JSDoc type definitions
// ============================================================================

/**
 * @typedef {Window.jQuery} jQuery
 */

/**
 * @typedef {jQuery|HTMLElement|EventTarget|string} Selector
 */

// ============================================================================
// Functions - HTML
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
    let $element = $(element);
    const rect   = $element[0].getBoundingClientRect();
    const top    = 0;
    const bottom = window.innerHeight || document.documentElement.clientHeight;
    if (rect.top < top) {
        $element[0].scrollIntoView(true);
    } else if (rect.bottom > bottom) {
        $element[0].scrollIntoView(false);
    }
    return $element;
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
