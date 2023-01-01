// app/assets/javascripts/application/start.js
//
// This module should be the last import of application.js in order to cause
// the page setup functions defined in imported modules to be run when the page
// is ready.


import { AppDebug }                from './debug';
import { pageSetup, pageTeardown } from './setup';
import '../vendor/turbolinks';


AppDebug.file('application/start');

document.addEventListener('turbolinks:load',          pageSetup);
document.addEventListener('turbolinks:before-render', pageTeardown);
