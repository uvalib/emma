// app/assets/javascripts/feature/download.js
//
// This module involves displaying the inline message that indicates sign-in is
// required on download links in an anonymous session.


import { AppDebug }               from '../application/debug';
import { appSetup }               from '../application/setup';
import { handleClickAndKeypress } from '../shared/accessibility';
import { Emma }                   from '../shared/assets';
import { selector, toggleHidden } from '../shared/css';
import { isMissing }              from '../shared/definitions';
import { SearchInProgress }       from '../shared/search-in-progress';


const MODULE = 'Download';
const DEBUG  = true;

AppDebug.file('feature/download', MODULE, DEBUG);

appSetup(MODULE, function() {

    /**
     * Selector for links which are not currently enabled.
     *
     * @type {string}
     */
    const UNAUTHORIZED = '.sign-in-required';

    /** @type {jQuery} */
    const $download_links = $('.artifact').children('.link, .download');
    const $no_auth_links  = $download_links.filter(UNAUTHORIZED);
    const $artifact_links = $download_links.not(`.download, ${UNAUTHORIZED}`);

    // Only perform these actions on the appropriate pages.
    if (isMissing($artifact_links) && isMissing($no_auth_links)) { return }

    // noinspection JSUnusedLocalSymbols
    /**
     * Console output functions for this module.
     */
    const OUT = AppDebug.consoleLogging(MODULE, DEBUG);

    // ========================================================================
    // Constants
    // ========================================================================

    /**
     * Failure message element selector.
     *
     * @readonly
     * @type {string}
     */
    const FAILURE = selector(Emma.Download.failure.class);

    // ========================================================================
    // Functions
    // ========================================================================

    /**
     * Display a failure message for an unauthorized link.
     *
     * @param {jQuery.Event|Event} event
     */
    function showNotAuthorized(event) {
        //OUT.debug('showNotAuthorized: event =', event);
        event.preventDefault();
        const $link = $(event.currentTarget || event.target);
        showFailureMessage($link, Emma.Download.failure.sign_in);
    }

    /**
     * Display a download failure message after the download link.
     *
     * @param {jQuery} $link
     * @param {string} [error]
     */
    function showFailureMessage($link, error) {
        //OUT.debug(`showFailureMessage: error = "${error}"; $link =`, $link);
        const message  = error || Emma.Download.failure.unknown;
        const $failure = $link.siblings(FAILURE);
        $failure.text(message);
        $failure.attr('title', message);
        toggleHidden($failure, false);
    }

    // ========================================================================
    // Event handlers
    // ========================================================================

    // Display failure message if not authorized.
    handleClickAndKeypress($no_auth_links, showNotAuthorized);

    // Clicking on the download link causes a page navigation, which is set up
    // to cause a SearchInProgress overlay to display.  This is a problem
    // because it's not really a page transition so it just causes the page to
    // be unusable.
    //
    // TODO: Determine how to restore after the download is complete.
    //
    handleClickAndKeypress($artifact_links.siblings('.button'), () => {
        SearchInProgress.suppressed = true;
    });

});
