// app/assets/javascripts/vendor/turbolinks.js
//
// Turbolinks is loaded last in application.js to ensure that 'turbolinks:*'
// event handlers set up in earlier modules do not fire until all handlers are
// in place.


import { pageLoadType } from '../shared/browser'


const DEBUG  = true;
const EVENTS = [
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

if (DEBUG) {
    const show = (event) => {
        const tag  = `========== ${event.type} ==========`;
        const load = pageLoadType();
        console.warn(`${tag} [${load}]`, window.location);
    };
    EVENTS.forEach(ev => document.addEventListener(`turbolinks:${ev}`, show));
}

// noinspection JSUnresolvedFunction
require('turbolinks').start();
