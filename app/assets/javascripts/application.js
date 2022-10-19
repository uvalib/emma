// app/assets/javascripts/application.js
//
// Entry point for the JavaScript build designated in package.json.

import './tool/debug'
import './vendor'
import './shared'
import './feature'
import './controllers'
import './vendor/turbolinks'

// NOTE: './channels' are not imported here to avoid unneeded setup activity on
//  general pages.  Pages that make use of ActionCable should import the
//  appropriate channel module(s) dynamically.
