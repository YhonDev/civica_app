import { SetMetadata } from '@nestjs/common';
import { AccessScope } from '../domain/access-scope.enum';

export const REQUIRED_SCOPE_KEY = 'requiredScope';

export const RequireScope = (scope: AccessScope) =>
  SetMetadata(REQUIRED_SCOPE_KEY, scope);
