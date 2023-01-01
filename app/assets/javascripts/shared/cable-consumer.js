// app/assets/javascripts/shared/cable-consumer.js


import { AppDebug }                         from '../application/debug';
import { appTeardown }                      from '../application/setup';
import { camelCase }                        from './strings';
import { Consumer, createConsumer, logger } from '@rails/actioncable';


// ============================================================================
// Functions - internal
// ============================================================================

const MODULE   = 'WebSocket';
const DEBUG    = true;
logger.enabled = DEBUG;

AppDebug.file('shared/cable-consumer', MODULE, DEBUG);

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
    _debug('new_consumer:', new_instance);
    appTeardown(MODULE, () => disconnect());
    return new_instance;
}

// ============================================================================
// Functions
// ============================================================================

export function disconnect() {
    const func = 'disconnect';
    if (!instance) {
        console.warn(`${MODULE}: ${func}: not connected`);
        return;
    }
    _debug(`${func}: consumer:`, instance);
    const subs = instance.subscriptions;
    const list = [...subs.subscriptions];
    _debug(`${func}: remove subscriptions`, list);
    list.forEach(s => subs.remove(s));
    _debug(`${func}: terminate connection`);
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
    _debug('createChannel: stream =', stream);
    let params;
    if ((typeof stream === 'string') && !stream.endsWith('Channel')) {
        params = camelCase(stream) + 'Channel';
    } else {
        params = stream;
    }
    return consumer().subscriptions.create(params, functions);
}

// noinspection JSUnusedGlobalSymbols
/**
 * Close a channel (same as `channel.unsubscribe()`).
 *
 * @param {Subscription} channel
 *
 * @returns {Subscription}
 */
export function closeChannel(channel) {
    _debug('closeChannel: channel =', channel);
    return consumer().subscriptions.remove(channel);
}

// ============================================================================
// Functions - internal
// ============================================================================

/**
 * Indicate whether console debugging is active.
 *
 * @returns {boolean}
 */
function _debugging() {
    return AppDebug.activeFor(MODULE, DEBUG);
}

/**
 * Emit a console message if debugging.
 *
 * @param {...*} args
 */
function _debug(...args) {
    _debugging() && console.log(`${MODULE}:`, ...args);
}
