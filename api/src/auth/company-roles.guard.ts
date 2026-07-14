import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { CompanyRole } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { COMPANY_ROLES_KEY } from './company-roles.decorator';

@Injectable()
export class CompanyRolesGuard implements CanActivate {
  constructor(
    private readonly reflector: Reflector,
    private readonly prisma: PrismaService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const required = this.reflector.getAllAndOverride<CompanyRole[]>(
      COMPANY_ROLES_KEY,
      [context.getHandler(), context.getClass()],
    );
    if (!required?.length) return true;

    const req = context.switchToHttp().getRequest<{
      user?: { companyId?: string | null };
    }>();
    const companyId = req.user?.companyId;
    if (!companyId) {
      throw new ForbiddenException('Entreprise requise');
    }

    const company = await this.prisma.company.findUnique({
      where: { id: companyId },
      select: { roles: true, isSuspended: true },
    });
    if (!company) {
      throw new ForbiddenException('Entreprise introuvable');
    }
    if (company.isSuspended) {
      throw new ForbiddenException('Compte suspendu. Contactez le support.');
    }

    const ok = required.some((role) => company.roles.includes(role));
    if (!ok) {
      throw new ForbiddenException(
        `Accès réservé aux rôles : ${required.join(', ')}`,
      );
    }
    return true;
  }
}
