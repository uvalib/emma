// app/assets/javascripts/feature/popup.js


import { InlinePopup } from '../shared/inline-popup'
import { ModalDialog } from '../shared/modal-dialog'


$(document).on('turbolinks:load', function() {
    InlinePopup.initializeAll();
    ModalDialog.initializeAll();
});
