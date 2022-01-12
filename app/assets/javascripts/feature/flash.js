// app/assets/javascripts/feature/flash.js


import { flashContainer } from '../shared/flash'


$(document).on('turbolinks:before-cache', function() {
    flashContainer().remove();
});
