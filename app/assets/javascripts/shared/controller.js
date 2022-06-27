// app/assets/javascripts/shared/controller.js
//
// noinspection JSUnusedGlobalSymbols


// ============================================================================
// Functions - Controller/Action
// ============================================================================

/**
 * Return the controller indicated by the given path.
 *
 * @param {string} [path]             Default: `window.location.pathname`.
 *
 * @returns {string}
 */
export function pageController(path) {
    return pageControllerAction(path).controller;
}

/**
 * Return the action indicated by the given path.
 *
 * @param {string} [path]             Default: `window.location.pathname`.
 *
 * @returns {string}
 */
export function pageAction(path) {
    return pageControllerAction(path).action;
}

/**
 * Return the controller/action indicated by the given path.
 *
 * @param {string} [path]             Default: `window.location.pathname`.
 *
 * @returns {{controller: string, action: string}}
 */
export function pageControllerAction(path) {
    let ctrlr, action;
    if (typeof path === 'object') {
        // noinspection JSUnresolvedVariable
        [ctrlr, action] = [path.controller, path.action];
    } else {
        let url = (typeof path === 'string') ? path : undefined;
        url &&= url.replace(/^https?:/, '').replace(/^\/\//, '');
        url &&= url.replace(/#.*$/, '').replace(/\?.*$/, '').trim();
        url ||= window.location.pathname.replace(/^\//, '');
        [ctrlr, action] = url.split('/')
    }
    return { controller: ctrlr, action: (action || 'index') };
}
