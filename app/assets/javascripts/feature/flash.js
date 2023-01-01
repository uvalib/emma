// app/assets/javascripts/feature/flash.js


import { AppDebug }                    from '../application/debug';
import { appSetup }                    from '../application/setup';
import { flashInitialize, clearFlash } from '../shared/flash';


const MODULE = 'feature/flash';

AppDebug.file(MODULE);

appSetup(MODULE, () => flashInitialize(), () => clearFlash());
