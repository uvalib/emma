// app/assets/javascripts/vendor/turbolinks.js
//
// Turbolinks is loaded last in application.js to ensure that 'turbolinks:*'
// event handlers set up in earlier modules do not fire until all handlers are
// in place.


import { handleEvent } from '../shared/events'


const DEBUG_TURBOLINKS  = true;
const TURBOLINKS_EVENTS = [
    'click',
    'before-visit',
    'visit',
    'request-start',
    'request-end',
    'before-cache',
    'before-render',
    'render',
    'load',
];

if (DEBUG_TURBOLINKS) {
    TURBOLINKS_EVENTS.forEach(function(name) {
        const event  = `turbolinks:${name}`;
        const notice = `========== ${event} ==========`;
        handleEvent($(document), event, () => { console.warn(notice) });
    });
}

// noinspection JSUnresolvedFunction
require('turbolinks').start();
