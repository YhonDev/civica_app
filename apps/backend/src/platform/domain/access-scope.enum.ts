export enum AccessScope {
  PLATFORM = 'PLATFORM',
  TENANT = 'TENANT',
  PROJECT = 'PROJECT',
  STAGE = 'STAGE',
  OWN_RESOURCE = 'OWN_RESOURCE',
}

export type PlatformRole = 'SUPERADMIN';
export type MfaLevel = 'WEBAUTHN' | 'PASSKEY' | 'NONE';

export interface PlatformPrincipal {
  sub: string;
  scope: AccessScope.PLATFORM;
  platformRole: PlatformRole;
  mfaLevel: MfaLevel;
}
