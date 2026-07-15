import { Injectable, NotFoundException } from '@nestjs/common';
import { NotificationType } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

export interface NotifyInput {
  type: NotificationType;
  title: string;
  body: string;
  link?: string;
}

@Injectable()
export class NotificationsService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Crée une notification pour une entreprise. Ne lève jamais d'erreur : une
   * notification manquée ne doit pas casser l'action métier qui l'a déclenchée.
   */
  async notify(companyId: string | null | undefined, input: NotifyInput) {
    if (!companyId) return null;
    try {
      return await this.prisma.notification.create({
        data: {
          companyId,
          type: input.type,
          title: input.title,
          body: input.body,
          link: input.link,
        },
      });
    } catch {
      return null;
    }
  }

  list(companyId: string) {
    return this.prisma.notification.findMany({
      where: { companyId },
      orderBy: { createdAt: 'desc' },
      take: 100,
    });
  }

  async unreadCount(companyId: string) {
    const count = await this.prisma.notification.count({
      where: { companyId, isRead: false },
    });
    return { count };
  }

  async markRead(companyId: string, id: string) {
    const notif = await this.prisma.notification.findUnique({ where: { id } });
    if (!notif || notif.companyId !== companyId) {
      throw new NotFoundException('Notification introuvable');
    }
    return this.prisma.notification.update({
      where: { id },
      data: { isRead: true },
    });
  }

  async markAllRead(companyId: string) {
    await this.prisma.notification.updateMany({
      where: { companyId, isRead: false },
      data: { isRead: true },
    });
    return { ok: true };
  }
}
