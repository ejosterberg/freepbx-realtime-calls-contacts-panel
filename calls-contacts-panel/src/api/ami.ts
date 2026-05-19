import AMI from 'yana';
import { getConfig } from '../config';
import ini from 'ini';
import { readFile } from 'fs/promises';

const TAG = '[AMI]';
let ami: AMI;

interface AmiConfig {
  port: number,
  user: string,
  secret: string,
}

export function parseManagerConf(raw: string): AmiConfig {
  const obj = ini.parse(raw);
  const port = parseInt(obj['general']?.['port'] ?? '');
  // FreePBX 16+ generates a hashed manager username (not "admin"). Find the
  // first non-general section that has a `secret` field — that's the AMI user.
  const userSection = Object.keys(obj).find(
    section => section !== 'general' && obj[section]?.['secret']
  );
  if (!port || !userSection)
    throw new Error(`${TAG} asterisk manager config does not include required values: general->port, <user>->secret`);
  return {
    port,
    user: userSection,
    secret: obj[userSection]['secret'],
  };
}

export async function initAmi() {
  const managerConfigRaw = await readFile(getConfig().managerConfFile, 'utf-8');
  const managerConfig = parseManagerConf(managerConfigRaw);

  ami = new AMI({
    port: managerConfig.port,
    host: '127.0.0.1',
    login: managerConfig.user,
    password: managerConfig.secret,
    events: 'on',
    reconnect: true
  });

  await ami.connect();
  console.log(TAG, `asterisk manager interface connected as ${managerConfig.user}`);
}

export function getAmi() {
  if (!ami)
    throw new Error('asterisk manager interface was not initialized')
  return ami;
}
