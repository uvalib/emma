// app/assets/javascripts/shared/assets.js
//
// Re-export the definitions values which are maintained in assets.js.erb,
// which is processed into "/app/assets/builds/javascripts-shared-assets.js"
// by the "emma:assets:erb" Rake task.


import { AppDebug } from "../application/debug";
export { Emma }     from "../../builds/javascripts-shared-assets";


AppDebug.file("shared/assets");
