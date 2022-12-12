// app/assets/javascripts/feature/flash.js


import { appSetup }                    from '../application/setup'
import { flashInitialize, clearFlash } from '../shared/flash'


appSetup('feature/flash', () => flashInitialize(), () => clearFlash());
