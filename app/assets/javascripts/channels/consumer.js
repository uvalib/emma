// app/assets/javascripts/channels/consumer.js


import { camelCase }      from '../shared/strings'
import { createConsumer } from '@rails/actioncable'


let instance;
let consumer = () => (instance ||= createConsumer());

/**
 * Open a channel.
 *
 * @param {string|object}    identity
 * @param {Object<function>} [functions]
 *
 * @returns {Subscription}
 *
 * @see "ApplicationCable::Channel#subscribed"
 */
export function createChannel(identity, functions) {
    let params;
    if ((typeof identity === 'string') && !identity.endsWith('Channel')) {
        params = camelCase(identity) + 'Channel';
    } else {
        params = identity;
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
    return consumer().subscriptions.remove(channel);
}
