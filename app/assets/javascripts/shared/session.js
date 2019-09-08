// app/assets/javascripts/shared/session.js

//= require shared/definitions

$(document).on('turbolinks:load', function() {

    /**
     * @constant {number}
     */
    var FOCUS_DELAY = 100;

    // ========================================================================
    // Function definitions
    // ========================================================================

    /**
     * Return an anchor name based on the provided full or partial URL as long
     * as it represents an in-page transition from the current location.
     *
     * @param {Event|Location|string} arg
     * @param {boolean}               [add_hash]    Default: *true*.
     *
     * @returns {string}
     *
     * == Usage Notes
     * Local URLs are assumedly to be relative.
     */
    function getInPageAnchor(arg, add_hash) {
        var path = extractUrl(arg);
        if (path && (path.indexOf('http') === 0)) {
            var in_page = false;
            if (path.indexOf('#') > 0) {
                var curr_url = window.location.href.replace(/#.*$/, '');
                var new_url  = path.replace(/#.*$/, '');
                in_page      = (new_url === curr_url);
            }
            path = in_page && path.replace(/^.*#/, '');
        }
        path = path && path.split('#').pop();
        // noinspection NegatedIfStatementJS
        if (!path) {
            path = '';
        } else if (add_hash || notDefined(add_hash)) {
            path = '#' + path;
        }
        return path;
    }

    /**
     * Updates the URL and Turbolinks page cache without navigating.
     *
     * @param {string} url
     *
     * @see http://www.modernmpa.com/turbolinks.html
     */
    function updatePageUrl(url) {
        Turbolinks.controller.pushHistoryWithLocationAndRestorationIdentifier(
            url,
            Turbolinks.uuid()
        );
    }

    // ========================================================================
    // Handler functions
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
        var anchor = event ? getInPageAnchor(event) : window.location.hash;
        if (anchor && focusable(anchor)) {
            $(anchor).first().focus();
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
        if (getInPageAnchor(event)) {
            // noinspection JSUnresolvedVariable
            updatePageUrl(event.data.url);
            event.preventDefault();
            setTimeout(function() { focusAnchor(); }, FOCUS_DELAY);
        }
    }

    // ========================================================================
    // Event handlers
    // ========================================================================

    // Ignore Turbolinks on anchor links.
    document.addEventListener('turbolinks:click', clickInPageAnchor);

/*
    // Accommodate Firefox anchor focus bug.
    window.onhashchange = focusAnchor;

    // Begin with focus set appropriately.
    focusAnchor();
*/

});