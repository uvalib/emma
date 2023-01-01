// app/assets/javascripts/feature/session.js


import { AppDebug }              from '../application/debug';
import { appSetup }              from '../application/setup';
import { focusable }             from '../shared/accessibility';
import { isInternetExplorer }    from '../shared/browser';
import { isPresent, notDefined } from '../shared/definitions';
import { documentEvent }         from '../shared/events';
import { SearchInProgress }      from '../shared/search-in-progress';
import { urlFrom }               from '../shared/url';


const MODULE = 'feature/session';

AppDebug.file(MODULE);

appSetup(MODULE, function() {

    /**
     * @readonly
     * @type {number}
     */
    const FOCUS_DELAY = 100;

    // ========================================================================
    // Event handlers
    // ========================================================================

    // Ignore Turbolinks on anchor links.
    documentEvent('turbolinks:click', checkInPageAnchor);

    // Monitor page visibility.
    documentEvent('visibilitychange', pageVisibility);

    // ========================================================================
    // Actions
    // ========================================================================

/*
    // Accommodate Firefox anchor focus bug.
    window.onhashchange = focusAnchor;

    // Begin with focus set appropriately.
    focusAnchor();
*/

    // Display an alert if running from MS Internet Explorer.
    if (isInternetExplorer()) {
        window.document.body.style.display = 'none';
        alert(
            'EMMA does not support Microsoft Internet Explorer.' + "\n\n" +
            'Please view this site in Chrome, Firefox, Safari, ' +
            'Microsoft Edge or other modern web browser.'
        );
    }

    // ========================================================================
    // Functions
    // ========================================================================

    /**
     * Return an anchor name based on the provided full or partial URL as long
     * as it represents an in-page transition from the current location.
     *
     * **Usage Notes**
     * Local URLs are assumedly to be relative.
     *
     * @param {Event|Location|string} [arg]       Def.: `window.location.hash`.
     * @param {boolean}               [add_hash]  Def.: *true*.
     *
     * @returns {string}
     */
    function getInPageAnchor(arg, add_hash) {
        if (notDefined(arg)) { return window.location.hash }
        if ((typeof arg === 'string') && arg.startsWith('#')) { return arg }
        let path = urlFrom(arg);
        if (path.startsWith('http')) {
            let in_page = false;
            if (path.includes('#')) {
                const curr_url = window.location.href.replace(/#.*$/, '');
                const new_url  = path.replace(/#.*$/, '');
                in_page = (new_url === curr_url);
            }
            path = in_page && path.replace(/^.*#/, '');
        }
        path &&= path.split('#').pop();
        const hash = path && (add_hash !== false);
        return hash && `#${path}` || path || '';
    }

    /**
     * Updates the URL and Turbolinks page cache without navigating.
     *
     * @param {string} url
     *
     * @see http://www.modernmpa.com/turbolinks.html
     */
    function updatePageUrl(url) {
        // noinspection JSVoidFunctionReturnValueUsed
        Turbolinks.controller.pushHistoryWithLocationAndRestorationIdentifier(
            url,
            Turbolinks.uuid()
        );
    }

    // ========================================================================
    // Functions - event handlers
    // ========================================================================

    /**
     * When the browser moves to a named location on the page, focus on the
     * element there (if it is focusable).
     *
     * This is done automatically in Webkit-based browsers (Chrome and even
     * MS Edge and MS IE 11) but not in Firefox (61.0.2).  When this function
     * is assigned to `//window.onhashchange` it forces the behavior in Firefox
     * while essentially having no effect on browsers where the anchor target
     * already has the focus.
     *
     * NOTE: The combination of Turbolinks and Firefox is still problematic.
     * Because I couldn't get a "hashchange" event to fire in a way that
     * Firefox would respond consistently, this function is not being used as
     * event handler but is being invoked "manually" from checkInPageAnchor().
     *
     * @param {Event|Location|string} [event]  Default: `window.location.hash`.
     *
     */
    function focusAnchor(event) {
        const anchor  = getInPageAnchor(event);
        const $anchor = anchor && $(anchor);
        console.log('focusAnchor', $anchor);
        if (isPresent($anchor) && focusable($anchor)) {
            $anchor.first().focus();
        }
    }

    /**
     * Per https://github.com/turbolinks/turbolinks/issues/75 in-page anchor
     * links require special handling in order to avoid extraneous Turbolinks
     * activity when all that is needed is to scroll to the anchor location.
     *
     * In addition, this triggers a delayed action to focus on the anchor; this
     * is needed for Firefox but should be harmless for other browser families.
     *
     * @param {Event} event
     */
    function checkInPageAnchor(event) {
        const func   = 'checkInPageAnchor';
        const anchor = getInPageAnchor(event);
        if (anchor) {
            console.log(`${func}: anchor "${anchor}" for`, event);
            // noinspection JSUnresolvedVariable
            updatePageUrl(event.data.url);
            event.preventDefault();
            setTimeout(function() {
                focusAnchor(anchor);
                SearchInProgress.hide();
            }, FOCUS_DELAY);
        } else {
            console.log(`${func}: no anchor for`, event);
        }
    }

    /**
     * Monitor the visibility of the browser tab containing the current page.
     *
     * If the browser in minimized or a different browser tab gets focus then
     * the page is not visible.
     *
     * @param {Event} event
     */
    function pageVisibility(event) {
        const state  = document.visibilityState;
        const change = (state === 'visible') ? 'VISIBLE NOW' : 'NOT VISIBLE';
        const target = event.target.URL;
        console.warn(`PAGE ${change} ${target}`);
    }

});
