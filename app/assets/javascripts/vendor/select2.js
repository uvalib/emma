// app/assets/javascripts/vendor/select2.js
//
// Load jQuery in a module to be included in the 'application.js' manifest so
// that the required initialization is in place to respond to 'turbolinks:load'


import select2 from 'select2'


$(document).on('turbolinks:load', function() {
    select2($);
});
