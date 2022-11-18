// app/assets/javascripts/shared/session.js


import { focusable }             from './accessibility'
import { isInternetExplorer }    from './browser'
import { isPresent, notDefined } from './definitions'
import { SearchInProgress }      from './search-in-progress'
import { urlFrom }               from './url'


$(document).on('turbolinks:load', function() {

    /**
     * @readonly
     * @type {number}
     */
    const FOCUS_DELAY = 100;

    // ========================================================================
    // Event handlers
    // ========================================================================

    // Ignore Turbolinks on anchor links.
    document.addEventListener('turbolinks:click', clickInPageAnchor);

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
     * event handler but is being invoked "manually" from clickInPageAnchor().
     *
     * @param {Event|Location|string} [event]  Default: `window.location.hash`.
     *
     */
    function focusAnchor(event) {
        const anchor  = getInPageAnchor(event);
        const $anchor = anchor && $(anchor);
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
    function clickInPageAnchor(event) {
        console.warn('clickInPageAnchor', event);
        const anchor = getInPageAnchor(event);
        if (anchor) {
            // noinspection JSUnresolvedVariable
            updatePageUrl(event.data.url);
            event.preventDefault();
            setTimeout(function() {
                focusAnchor(anchor);
                SearchInProgress.hide();
            }, FOCUS_DELAY);
        }
    }

});
