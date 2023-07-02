// app/assets/javascripts/feature/iframe.js


import { AppDebug }               from '../application/debug';
import { appSetup }               from '../application/setup';
import { handleClickAndKeypress } from '../shared/accessibility';
import { isMissing }              from '../shared/definitions';


const MODULE = 'Iframe';
const DEBUG  = true;

AppDebug.file('feature/iframe', MODULE, DEBUG);

appSetup(MODULE, function() {

    const $iframe_body = $('body.modal');

    // Only proceed if this is being run from within an `<iframe>`.
    if (isMissing($iframe_body)) {
        return;
    }

    /**
     * Console output functions for this module.
     */
    const OUT = AppDebug.consoleLogging(MODULE, DEBUG);

    // ========================================================================
    // Variables
    // ========================================================================

    /**
     * Clickable elements within the `<iframe>` contents.
     *
     * @type {jQuery}
     */
    const $iframe_links = $iframe_body.find('[href]');

    /**
     * Clickable elements within `<iframe>` contents which are in-page links.
     *
     * @type {jQuery}
     */
    const $anchor_links = $iframe_links.filter((_, link) => link.hash);

    // ========================================================================
    // Functions
    // ========================================================================

    // noinspection FunctionWithInconsistentReturnsJS
    /**
     * Intercept anchor links to scroll to the element on the page inside the
     * `<iframe>`.
     *
     * @param {jQuery.Event|UIEvent} [event]
     *
     * @returns {boolean}   False to indicate that the event has been handled.
     */
    function scrollToAnchor(event) {
        const func    = 'IFRAME scrollToAnchor';
        const $link   = $(event ? event.target : this);
        const anchor  = $link[0].hash;
        const $anchor = anchor && $(anchor);
        if ($anchor) {
            event.preventDefault();
            const top = $anchor.offset().top;
            OUT.debug(`${func}: ${anchor} AT y =`, top);
            window.scrollTo(0, top);
            return false;
        } else {
            OUT.error(`${func}: NON ANCHOR LINK`, $link);
        }
    }

    // ========================================================================
    // Event handlers
    // ========================================================================

    handleClickAndKeypress($anchor_links, scrollToAnchor);
});
