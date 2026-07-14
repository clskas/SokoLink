import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class MessagesService {
  constructor(private readonly prisma: PrismaService) {}

  async list(companyId: string) {
    const rows = await this.prisma.conversation.findMany({
      where: {
        OR: [{ companyAId: companyId }, { companyBId: companyId }],
      },
      include: {
        messages: { orderBy: { createdAt: 'desc' }, take: 1 },
      },
      orderBy: { updatedAt: 'desc' },
    });

    const otherIds = rows.map((c) =>
      c.companyAId === companyId ? c.companyBId : c.companyAId,
    );
    const companies = await this.prisma.company.findMany({
      where: { id: { in: otherIds } },
      select: { id: true, name: true, whatsapp: true, phone: true },
    });
    const map = Object.fromEntries(companies.map((c) => [c.id, c]));

    return rows.map((c) => {
      const otherId = c.companyAId === companyId ? c.companyBId : c.companyAId;
      return {
        ...c,
        otherCompany: map[otherId] ?? null,
        lastMessage: c.messages[0] ?? null,
      };
    });
  }

  async start(
    companyId: string,
    otherCompanyId: string,
    productId?: string,
    rfqId?: string,
  ) {
    if (companyId === otherCompanyId) {
      throw new BadRequestException('Conversation invalide');
    }
    const existing = await this.prisma.conversation.findFirst({
      where: {
        OR: [
          { companyAId: companyId, companyBId: otherCompanyId },
          { companyAId: otherCompanyId, companyBId: companyId },
        ],
        productId: productId ?? null,
        rfqId: rfqId ?? null,
      },
    });
    if (existing) return existing;

    return this.prisma.conversation.create({
      data: {
        companyAId: companyId,
        companyBId: otherCompanyId,
        productId,
        rfqId,
      },
    });
  }

  async get(companyId: string, id: string) {
    const conversation = await this.prisma.conversation.findUnique({
      where: { id },
      include: {
        messages: { orderBy: { createdAt: 'asc' } },
      },
    });
    if (!conversation) throw new NotFoundException();
    if (
      conversation.companyAId !== companyId &&
      conversation.companyBId !== companyId
    ) {
      throw new ForbiddenException();
    }
    return conversation;
  }

  async postMessage(
    companyId: string,
    userId: string,
    conversationId: string,
    body: string,
  ) {
    await this.get(companyId, conversationId);
    const message = await this.prisma.message.create({
      data: {
        conversationId,
        senderUserId: userId,
        body,
      },
    });
    await this.prisma.conversation.update({
      where: { id: conversationId },
      data: { updatedAt: new Date() },
    });
    return message;
  }
}
