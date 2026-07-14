import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

/** Bloque les comptes suspendus et les JWT orphelins. */
@Injectable()
export class ActiveCompanyGuard implements CanActivate {
  constructor(private readonly prisma: PrismaService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const req = context.switchToHttp().getRequest<{
      user?: { userId?: string; companyId?: string | null };
    }>();
    const userId = req.user?.userId;
    if (!userId) {
      throw new UnauthorizedException();
    }

    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: { company: { select: { isSuspended: true } } },
    });
    if (!user) {
      throw new UnauthorizedException('Session invalide');
    }
    if (user.company?.isSuspended) {
      throw new ForbiddenException('Compte suspendu. Contactez le support.');
    }
    return true;
  }
}
