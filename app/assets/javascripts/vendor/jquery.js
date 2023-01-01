// app/assets/javascripts/vendor/jquery.js
//
// Load jQuery.
//
// NOTE: This must be included near the start of the 'application.js' load
//  sequence so that 'jQuery' and '$' are available to all subsequent modules.


import { AppDebug } from '../application/debug';
import jquery       from 'jquery';


AppDebug.file('vendor/jquery');

window.jQuery = jquery;
window.$      = jquery;
