// app/assets/javascripts/shared/browser.js


// ============================================================================
// Functions
// ============================================================================

/**
 * Indicate whether the client browser is MS Internet Explorer.
 *
 * @returns {boolean}
 */
export function isInternetExplorer() {
    // noinspection PlatformDetectionJS
    const ua = navigator.userAgent || '';
    return ua.includes('MSIE ') || ua.includes('Trident/');
}
