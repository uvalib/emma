// app/assets/javascripts/application.js
//
// Entry point for the JavaScript build designated in package.json.

import './vendor'
import './shared'
import './feature'
import './controllers'

// Turbolinks is loaded last to ensure that 'turbolinks:*' event handlers set
// up in earlier modules do not fire until all handlers are in place.
// noinspection JSUnresolvedFunction
require('turbolinks').start();
