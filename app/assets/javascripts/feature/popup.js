// app/assets/javascripts/feature/popup.js


import { AppDebug }    from '../application/debug';
import { appSetup }    from '../application/setup';
import { InlinePopup } from '../shared/inline-popup';
import { ModalDialog } from '../shared/modal-dialog';


const MODULE = 'feature/popup';

AppDebug.file(MODULE);

appSetup(MODULE, function() {
    InlinePopup.initializeAll();
    ModalDialog.initializeAll();
});
