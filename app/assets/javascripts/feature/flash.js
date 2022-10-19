// app/assets/javascripts/feature/flash.js


import { pageLoadNormal }              from '../shared/browser'
import { flashInitialize, flashReset } from '../shared/flash'


$(document).on('turbolinks:load', function() {

    // Initialize all flash message container(s) on the page, or clear the
    // flash if this page load is due to reload, or history back/forward.
    //
    // The flash container starts out hidden and only made visible for a normal
    // page load.
    //
    if (pageLoadNormal()) {
        flashInitialize();
    } else {
        flashReset();
    }

});
