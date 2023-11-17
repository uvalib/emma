// app/assets/javascripts/controllers/generic.js
//
// Setup that is appropriate for any controller page.
//
// NOTE: This is intended to come last in ./index.js.


import { AppDebug }                  from '../application/debug';
import { appSetup }                  from '../application/setup';
import { Analytics }                 from '../shared/analytics';
import { isPresent }                 from '../shared/definitions';
import { initializeTableNavigation } from '../shared/grids';
import { InlinePopup }               from '../shared/inline-popup';
import { ModalDialog }               from '../shared/modal-dialog';


const MODULE = 'Generic';

AppDebug.file('controllers/generic', MODULE);

appSetup(MODULE, function() {

    // Initialize any non-grid tables.
    const $table = $('[role="table"]');
    if (isPresent($table)) {
        initializeTableNavigation($table);
    }

    // Initialize any modals that have not already been initialized by an
    // earlier "../controllers/*" module.
    InlinePopup.initializeAll();
    ModalDialog.initializeAll();

    // Update links for analytics as the final step in case earlier actions
    // create additional link targets on the page.
    Analytics.updatePage();

});
