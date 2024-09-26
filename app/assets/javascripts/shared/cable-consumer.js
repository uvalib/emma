// app/assets/javascripts/shared/cable-consumer.js
//
// noinspection JSUnusedGlobalSymbols


import { AppDebug }                         from "../application/debug";
import { appTeardown }                      from "../application/setup";
import { Emma }                             from "./assets";
import { camelCase }                        from "./strings";
import { Consumer, createConsumer, logger } from "@rails/actioncable";


const MODULE   = "WebSocket";
const DEBUG    = Emma.Debug.JS_DEBUG_CABLE_CONSUMER;
logger.enabled = DEBUG;

AppDebug.file("shared/cable-consumer", MODULE, DEBUG);

// ============================================================================
// Functions - internal
// ============================================================================

/**
 * Console output functions for this module.
 */
const OUT = AppDebug.consoleLogging(MODULE, DEBUG);

/** @type {Consumer} */
let instance;

/**
 * WebSocket consumer instance attached to the server "/cable" endpoint.
 *
 * @returns {Consumer}
 */
function consumer() {
    return instance ||= new_consumer();
}

/**
 * WebSocket consumer instance with a disconnect on app teardown.
 *
 * @returns {Consumer}
 */
function new_consumer() {
    const new_instance = createConsumer();
    OUT.debug("new_consumer:", new_instance);
    appTeardown(MODULE, () => disconnect());
    return new_instance;
}

// ============================================================================
// Functions
// ============================================================================

/** @returns {undefined} */
export function disconnect() {
    const func = "disconnect";
    if (!instance) {
        return OUT.warn(`${MODULE}: ${func}: not connected`);
    }
    OUT.debug(`${func}: consumer:`, instance);
    const subs = instance.subscriptions;
    const list = [...subs.subscriptions];
    OUT.debug(`${func}: remove subscriptions`, list);
    list.forEach(s => subs.remove(s));
    OUT.debug(`${func}: terminate connection`);
    instance.disconnect();
    instance = null;
}

// ============================================================================
// Functions - channel
// ============================================================================

/**
 * Open a channel.
 *
 * @param {string|object}            stream
 * @param {Object.<string,function>} [functions]
 *
 * @returns {Subscription}
 *
 * @see "ApplicationCable::Channel#subscribed"
 */
export function createChannel(stream, functions) {
    OUT.debug("createChannel: stream =", stream);
    let params;
    if ((typeof stream === "string") && !stream.endsWith("Channel")) {
        params = camelCase(stream) + "Channel";
    } else {
        params = stream;
    }
    return consumer().subscriptions.create(params, functions);
}

/**
 * Close a channel (same as `channel.unsubscribe()`).
 *
 * @param {Subscription} channel
 *
 * @returns {Subscription}
 */
export function closeChannel(channel) {
    OUT.debug("closeChannel: channel =", channel);
    return consumer().subscriptions.remove(channel);
}
