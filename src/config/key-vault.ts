import { DefaultAzureCredential } from '@azure/identity';
import { SecretClient } from '@azure/keyvault-secrets';
import { config as loadDotenv } from 'dotenv';

const DEFAULT_SECRET_ENV_NAMES = [
  'DATABASE_URL',
  'AZURE_STORAGE_CONNECTION_STRING',
];
const SECRET_LIST_ENV = 'KEY_VAULT_SECRETS';
const SECRET_NAME_PREFIX = 'KEY_VAULT_SECRET_NAME_';

export async function loadKeyVaultSecrets(): Promise<void> {
  loadDotenv({ quiet: true });

  const vaultUrl = process.env.KEY_VAULT_URL;
  if (!vaultUrl) {
    return;
  }

  const client = new SecretClient(vaultUrl, new DefaultAzureCredential());

  for (const envName of getSecretEnvNames()) {
    if (process.env[envName]) {
      continue;
    }

    const secretName = getSecretName(envName);
    const secret = await client.getSecret(secretName);

    if (!secret.value) {
      throw new Error(`Key Vault secret "${secretName}" is empty`);
    }

    process.env[envName] = secret.value;
  }
}

function getSecretEnvNames(): string[] {
  const configuredSecrets = process.env[SECRET_LIST_ENV];
  const secretEnvNames = configuredSecrets
    ? configuredSecrets.split(',')
    : DEFAULT_SECRET_ENV_NAMES;

  return secretEnvNames.map((envName) => envName.trim()).filter(Boolean);
}

function getSecretName(envName: string): string {
  return (
    process.env[`${SECRET_NAME_PREFIX}${envName}`] ?? envName.replace(/_/g, '-')
  );
}
