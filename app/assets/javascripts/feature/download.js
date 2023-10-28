// app/assets/javascripts/feature/download.js
//
// This module involves displaying the inline message that indicates sign-in is
// required on download links in an anonymous session.


import { AppDebug }               from '../application/debug';
import { appSetup }               from '../application/setup';
import { handleClickAndKeypress } from '../shared/accessibility';
import { isMissing }              from '../shared/definitions';
import { SearchInProgress }       from '../shared/search-in-progress';


const MODULE = 'Download';
const DEBUG  = true;

AppDebug.file('feature/download', MODULE, DEBUG);

appSetup(MODULE, function() {

    /** @type {jQuery} */
    const $download_links = $('.artifact').children('.link, .download');

    // Only perform these actions on the appropriate pages.
    if (isMissing($download_links)) { return }

    // noinspection JSUnusedLocalSymbols
    /**
     * Console output functions for this module.
     */
    const OUT = AppDebug.consoleLogging(MODULE, DEBUG);

    // ========================================================================
    // Event handlers
    // ========================================================================

    // Clicking on the download link causes a page navigation, which is set up
    // to cause a SearchInProgress overlay to display.  This is a problem
    // because it's not really a page transition so it just causes the page to
    // be unusable.
    //
    // TODO: Determine how to restore after the download is complete.
    //
    // NOTE: This may no longer be relevant if it is only applicable to
    //  mediated downloads of Bookshare items.
    //
    handleClickAndKeypress($download_links.siblings('.button'), () => {
        SearchInProgress.suppressed = true;
    });

});
