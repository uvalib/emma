// app/assets/javascripts/shared/browser.js


// ============================================================================
// Functions
// ============================================================================

/**
 * The reason the current page was loaded.
 *
 * @returns {NavigationTimingType}
 */
export function pageLoadType() {
    // noinspection JSValidateTypes
    /** @type {PerformanceNavigationTiming} */
    const timing = window.performance.getEntries()[0];
    return timing.type;
}

// noinspection JSUnusedGlobalSymbols
/**
 * Indicate whether the current page load was due to navigation via
 * 'history.back()' or 'history.forward()'.
 *
 * @returns {boolean}
 */
export function pageLoadFromHistory() {
    return pageLoadType() === 'back_forward';
}

// noinspection JSUnusedGlobalSymbols
/**
 * Indicate whether the current page load was due to the page being reloaded.
 *
 * @returns {boolean}
 */
export function pageLoadFromReload() {
    return pageLoadType() === 'reload';
}

/**
 * Indicate whether the current page load was due to normal page navigation.
 *
 * @returns {boolean}
 */
export function pageLoadNormal() {
    return !['back_forward', 'reload'].includes(pageLoadType());
}

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
