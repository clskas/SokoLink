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
      const other = map[otherId] ?? null;
      return {
        ...c,
        otherCompany: other,
        company: other,
        lastMessage: c.messages[0] ?? null,
      };
    });
  }

  async start(
    companyId: string,
    userId: string,
    input: {
      otherCompanyId?: string;
      productId?: string;
      rfqId?: string;
      message?: string;
    },
  ) {
    // Le destinataire peut être fourni directement, ou déduit du produit / RFQ
    // (ex. « Contacter » depuis une fiche produit qui ne connaît pas l'entreprise).
    let targetId = input.otherCompanyId;
    if (!targetId && input.productId) {
      const product = await this.prisma.product.findUnique({
        where: { id: input.productId },
        select: { companyId: true },
      });
      targetId = product?.companyId;
    }
    if (!targetId && input.rfqId) {
      const rfq = await this.prisma.rfq.findUnique({
        where: { id: input.rfqId },
        select: { issuerCompanyId: true },
      });
      targetId = rfq?.issuerCompanyId;
    }
    if (!targetId) {
      throw new BadRequestException('Destinataire introuvable');
    }
    if (companyId === targetId) {
      throw new BadRequestException(
        'Vous ne pouvez pas démarrer une conversation avec votre propre entreprise',
      );
    }

    let conversation = await this.prisma.conversation.findFirst({
      where: {
        OR: [
          { companyAId: companyId, companyBId: targetId },
          { companyAId: targetId, companyBId: companyId },
        ],
        productId: input.productId ?? null,
        rfqId: input.rfqId ?? null,
      },
    });
    conversation ??= await this.prisma.conversation.create({
      data: {
        companyAId: companyId,
        companyBId: targetId,
        productId: input.productId,
        rfqId: input.rfqId,
      },
    });

    const firstMessage = input.message?.trim();
    if (firstMessage) {
      await this.prisma.message.create({
        data: {
          conversationId: conversation.id,
          senderUserId: userId,
          body: firstMessage,
        },
      });
      await this.prisma.conversation.update({
        where: { id: conversation.id },
        data: { updatedAt: new Date() },
      });
    }

    return this.get(companyId, conversation.id);
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

    const otherId =
      conversation.companyAId === companyId
        ? conversation.companyBId
        : conversation.companyAId;
    const otherCompany = await this.prisma.company.findUnique({
      where: { id: otherId },
      select: { id: true, name: true, phone: true, whatsapp: true },
    });

    const myUsers = await this.prisma.user.findMany({
      where: { companyId },
      select: { id: true },
    });
    const myUserIds = new Set(myUsers.map((u) => u.id));

    return {
      ...conversation,
      otherCompany,
      company: otherCompany,
      messages: conversation.messages.map((m) => ({
        ...m,
        isMine: myUserIds.has(m.senderUserId),
      })),
    };
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
