// app/assets/javascripts/application/types.js
//
// Global JSDoc type definitions.
//
// NOTE: This should be imported in every JavaScript source file (particularly
//  ones that have JSDoc definitions referencing "jQuery" or "Selector").


/**
 * @typedef {Window.jQuery} jQuery
 */

/**
 * @typedef {string|jQuery|HTMLElement|HTMLElement[]} Selector
 */

/**
 * @typedef {Selector|Event|jQuery.Event} SelectorOrEvent
 */


// ============================================================================
// Document events
// ============================================================================


/**
 * For composition with an Event type to specify that the target is an element.
 *
 * @typedef DocumentTarget
 *
 * @property {Document} currentTarget
 * @property {Document} target
 */

/**
 * @typedef {(Event|jQuery.Event) & DocumentTarget} DocumentEvt
 */


// ============================================================================
// Link events
// ============================================================================


/**
 * For composition with an Event type to specify that the target is an `<a>`.
 *
 * @typedef AnchorTarget
 *
 * @property {HTMLAnchorElement} currentTarget
 * @property {HTMLAnchorElement} target
 */

/**
 * @typedef {(Event|jQuery.Event) & AnchorTarget} AnchorEvt
 */


// ============================================================================
// Input events
// ============================================================================


/**
 * For composition with an Event type to specify that the target is a element.
 *
 * @typedef InputTarget
 *
 * @property {HTMLInputElement} currentTarget
 * @property {HTMLInputElement} target
 */

/**
 * @typedef {(InputEvent|jQuery.Event) & InputTarget} InputEvt
 */

/** @typedef {InputEvt} CheckboxEvt */
/** @typedef {InputEvt} RadioEvt */


// ============================================================================
// Element events
// ============================================================================


/**
 * For composition with an Event type to specify that the target is a element.
 *
 * @typedef ElementTarget
 *
 * @property {HTMLElement} currentTarget
 * @property {HTMLElement} target
 */

/** @typedef {(Event        |jQuery.Event) & ElementTarget} TargetEvt   */
/** @typedef {(FocusEvent   |jQuery.Event) & ElementTarget} FocusEvt    */
/** @typedef {(KeyboardEvent|jQuery.Event) & ElementTarget} KeyboardEvt */
/** @typedef {(MouseEvent   |jQuery.Event) & ElementTarget} MouseEvt    */

/**
 * @typedef {
 *     TargetEvt |
 *     FocusEvt |
 *     KeyboardEvt |
 *     MouseEvt |
 *     AnchorEvt |
 *     InputEvt
 * } ElementEvt
 */
