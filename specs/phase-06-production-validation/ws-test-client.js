#!/usr/bin/env node
// End-to-end test of the panel's WebSocket API.
// Usage: node ws-test-client.js [host] [username] [password]
// Connects, authenticates, subscribes to activeCalls + callLogs + phonebook,
// prints events for 30 seconds, exits.

const { io } = require('socket.io-client');

const host = process.argv[2] || 'http://localhost:4848';
const username = process.argv[3] || 'testadmin';
const password = process.argv[4] || 'TestAdmin1234!';

console.log(`[client] connecting to ${host}/callpanel/socket.io as ${username}`);

const socket = io(host, {
  path: '/callpanel/socket.io',
  auth: { username, password },
  reconnection: false,
});

let activeCallsSeen = 0;
let callLogsSeen = 0;
let phonebookSeen = 0;
let userExtensionSeen = false;

socket.on('connect', () => {
  console.log('[client] CONNECTED, sid =', socket.id);
  console.log('[client] subscribing...');
  socket.emit('subscribeActiveCalls');
  socket.emit('subscribeCallLogs');
  socket.emit('subscribePhonebook');
});

socket.on('connect_error', (err) => {
  console.error('[client] CONNECT_ERROR:', err.message);
  process.exit(2);
});

socket.on('disconnect', (reason) => {
  console.log('[client] DISCONNECT:', reason);
});

socket.on('activeCalls', (calls) => {
  activeCallsSeen++;
  console.log(`[event] activeCalls (count=${calls.length}):`);
  calls.forEach((c, i) => {
    console.log(`  [${i}] id=${c.id} status=${c.status}`);
    console.log(`      from=${c.from?.phoneNumber} (${c.from?.displayName || 'unknown'})`);
    console.log(`      to=${c.to?.phoneNumber} (${c.to?.displayName || 'unknown'})`);
    console.log(`      via=${c.via} established=${c.establishedAt}`);
  });
});

socket.on('callLogs', (logs) => {
  callLogsSeen++;
  console.log(`[event] callLogs (count=${logs.length})`);
  // Don't dump all — just count
});

socket.on('phonebook', (entries) => {
  phonebookSeen++;
  console.log(`[event] phonebook (entries=${entries.length})`);
});

socket.on('userExtension', (ext) => {
  userExtensionSeen = true;
  console.log(`[event] userExtension: ${ext}`);
});

setTimeout(() => {
  console.log('\n[client] ============== summary ==============');
  console.log(`  activeCalls events:  ${activeCallsSeen}`);
  console.log(`  callLogs events:     ${callLogsSeen}`);
  console.log(`  phonebook events:    ${phonebookSeen}`);
  console.log(`  userExtension event: ${userExtensionSeen}`);
  console.log('[client] disconnecting');
  socket.disconnect();
  process.exit(0);
}, 30000);

setTimeout(() => {
  if (!socket.connected) {
    console.error('[client] TIMEOUT — never connected');
    process.exit(3);
  }
}, 5000);
