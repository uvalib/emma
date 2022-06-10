// app/assets/javascripts/feature/popup.js


import { InlinePopup } from '../shared/inline_popup'
import { ModalDialog } from '../shared/modal_dialog'


$(document).on('turbolinks:load', function() {
    InlinePopup.initializeAll();
    ModalDialog.initializeAll();
});
