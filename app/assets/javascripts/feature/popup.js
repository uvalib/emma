// app/assets/javascripts/feature/popup.js


import { appSetup }    from '../application/setup'
import { InlinePopup } from '../shared/inline-popup'
import { ModalDialog } from '../shared/modal-dialog'


appSetup('feature/popup', function() {
    InlinePopup.initializeAll();
    ModalDialog.initializeAll();
});
