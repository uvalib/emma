// app/assets/javascripts/shared/browser.js
//
// noinspection JSUnusedGlobalSymbols


import { AppDebug } from '../application/debug';


AppDebug.file('shared/browser');

// ============================================================================
// Functions
// ============================================================================

/**
 * The reason the current page was loaded.
 *
 * @note This will be unreliable on any page which is managed by Turbolinks.
 *
 * @returns {NavigationTimingType}
 */
export function pageLoadType() {
    // noinspection JSValidateTypes
    /** @type {PerformanceNavigationTiming} */
    const timing = window.performance.getEntries()[0];
    return timing.type;
}

/**
 * Indicate whether the current page load was due to navigation via
 * `history.back()` or `history.forward()`.
 *
 * @note This will never be true on any page which is managed by Turbolinks.
 *
 * @returns {boolean}
 */
/*
export function pageLoadFromHistory() {
    return pageLoadType() === 'back_forward';
}
*/

/**
 * Indicate whether the current page load was due to the page being reloaded.
 *
 * @note Once a reload has occurred on a page managed by Turbolinks, this will
 *  return **true** for all subsequent pages.
 *
 * @returns {boolean}
 */
/*
export function pageLoadFromReload() {
    return pageLoadType() === 'reload';
}
*/

/**
 * Indicate whether the current page load was due to normal page navigation.
 *
 * @note This will be unreliable on any page which is managed by Turbolinks.
 *
 * @returns {boolean}
 */
/*
export function pageLoadNormal() {
    return !['back_forward', 'reload'].includes(pageLoadType());
}
*/

// ============================================================================
// Functions
// ============================================================================

/**
 * Indicate whether the client browser is MS Internet Explorer.
 *
 * @returns {boolean}
 */
export function isInternetExplorer() {
    // If NavigatorUAData is present then no actual check is required.
    // noinspection JSUnresolvedVariable, PlatformDetectionJS
    const ua = navigator.userAgentData ? undefined : navigator.userAgent;
    return ua?.includes('MSIE ') || ua?.includes('Trident/') || false;
}
