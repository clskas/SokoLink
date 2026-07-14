import { SetMetadata } from '@nestjs/common';
import { CompanyRole } from '@prisma/client';

export const COMPANY_ROLES_KEY = 'company_roles';

/** Requires the authenticated company to have at least one of these roles. */
export const RequireCompanyRoles = (...roles: CompanyRole[]) =>
  SetMetadata(COMPANY_ROLES_KEY, roles);
