import {
  Body,
  Controller,
  Get,
  Param,
  Post,
  Query,
  Req,
  Res,
} from '@nestjs/common';
import type { Request, Response } from 'express';
import { AdminWebService } from './admin-web.service';

const PURPOSE_LABELS: Record<string, string> = {
  SUBSCRIPTION: 'Abonnement PRO',
  BOOST: 'Boost produit',
  VERIFICATION: 'Badge Vérifié',
  LEAD: 'Crédits mise en relation',
};

function fmtDate(value: unknown): string {
  if (!value) return '—';
  const d = new Date(value as string);
  if (Number.isNaN(d.getTime())) return '—';
  return d.toLocaleDateString('fr-FR', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
  });
}

function fmtMoney(amount: unknown, currency?: unknown): string {
  const n = Number(amount ?? 0);
  const cur = (currency as string) || 'CDF';
  return `${n.toLocaleString('fr-FR')} ${cur}`;
}

@Controller()
export class AdminWebController {
  constructor(private readonly admin: AdminWebService) {}

  private token(req: Request): string | undefined {
    return req.cookies?.['sokolink_admin_token'] as string | undefined;
  }

  @Get()
  root(@Res() res: Response) {
    return res.redirect('/dashboard');
  }

  @Get('login')
  loginPage(@Query('error') error: string | undefined, @Res() res: Response) {
    return res.render('login', {
      title: 'Connexion Admin — SokoLink',
      error: error ? 'Identifiants invalides ou compte non admin' : null,
    });
  }

  @Post('login')
  async login(
    @Body() body: { email?: string; password?: string },
    @Res() res: Response,
  ) {
    try {
      const data = await this.admin.login(body.email ?? '', body.password ?? '');
      res.cookie('sokolink_admin_token', data.accessToken, {
        httpOnly: true,
        sameSite: 'lax',
      });
      return res.redirect('/dashboard');
    } catch {
      return res.redirect('/login?error=1');
    }
  }

  @Get('logout')
  logout(@Res() res: Response) {
    res.clearCookie('sokolink_admin_token');
    return res.redirect('/login');
  }

  @Get('dashboard')
  async dashboard(@Req() req: Request, @Res() res: Response) {
    const token = this.token(req);
    if (!token) return res.redirect('/login');
    try {
      const [stats, companies, documents, proRequests, revenue, payments] =
        await Promise.all([
          this.admin.stats(token),
          this.admin.companies(token),
          this.admin.documents(token),
          this.admin.proRequests(token),
          this.admin.revenue(token),
          this.admin.payments(token),
        ]);
      const companiesView = (companies as Array<Record<string, unknown>>).map(
        (c) => {
          const roles = Array.isArray(c.roles) ? (c.roles as string[]) : [];
          return {
            ...c,
            hasMp: roles.includes('SUPPLIER_MP'),
            hasProcessor: roles.includes('PROCESSOR'),
            hasBuyer: roles.includes('BUYER'),
            isPro: c.plan === 'PRO',
            renewsAt: fmtDate(c.planRenewsAt),
            leadCredits: c.leadCredits ?? 0,
          };
        },
      );

      const paymentRows = (payments as Array<Record<string, unknown>>).map(
        (p) => {
          const company = p.company as { name?: string } | undefined;
          return {
            ...p,
            companyName: company?.name ?? (p.companyId as string),
            purposeLabel: PURPOSE_LABELS[p.purpose as string] ?? p.purpose,
            amountLabel: fmtMoney(p.amount, p.currency),
            createdLabel: fmtDate(p.createdAt),
            isPending: p.status === 'PENDING',
          };
        },
      );
      const pendingPayments = paymentRows.filter((p) => p.isPending);
      const recentPayments = paymentRows.slice(0, 15);

      const rev = (revenue as Record<string, unknown>) ?? {};
      const revenueView = {
        totalLabel: fmtMoney(rev.total, rev.currency),
        monthLabel: fmtMoney(rev.month, rev.currency),
        mrrLabel: fmtMoney(rev.mrr, rev.currency),
        activePro: rev.activePro ?? 0,
        verifiedCount: rev.verifiedCount ?? 0,
        expiringSoon: rev.expiringSoon ?? 0,
        pendingCount: rev.pendingCount ?? 0,
      };

      return res.render('dashboard', {
        title: 'Admin SokoLink',
        stats,
        revenue: revenueView,
        pendingPayments,
        recentPayments,
        companies: companiesView,
        documents,
        proRequests,
      });
    } catch {
      res.clearCookie('sokolink_admin_token');
      return res.redirect('/login?error=1');
    }
  }

  @Post('documents/:id/accept')
  async acceptDoc(
    @Param('id') id: string,
    @Req() req: Request,
    @Res() res: Response,
  ) {
    const token = this.token(req);
    if (!token) return res.redirect('/login');
    await this.admin.reviewDoc(token, id, 'ACCEPTED');
    return res.redirect('/dashboard');
  }

  @Post('documents/:id/reject')
  async rejectDoc(
    @Param('id') id: string,
    @Req() req: Request,
    @Res() res: Response,
  ) {
    const token = this.token(req);
    if (!token) return res.redirect('/login');
    await this.admin.reviewDoc(token, id, 'REJECTED', 'Document non conforme');
    return res.redirect('/dashboard');
  }

  @Post('pro/:id/activate')
  async activate(
    @Param('id') id: string,
    @Req() req: Request,
    @Res() res: Response,
  ) {
    const token = this.token(req);
    if (!token) return res.redirect('/login');
    await this.admin.activatePro(token, id);
    return res.redirect('/dashboard');
  }

  @Post('companies/:id/suspend')
  async suspend(
    @Param('id') id: string,
    @Req() req: Request,
    @Res() res: Response,
  ) {
    const token = this.token(req);
    if (!token) return res.redirect('/login');
    await this.admin.suspend(token, id, true);
    return res.redirect('/dashboard');
  }

  @Post('companies/:id/reactivate')
  async reactivate(
    @Param('id') id: string,
    @Req() req: Request,
    @Res() res: Response,
  ) {
    const token = this.token(req);
    if (!token) return res.redirect('/login');
    await this.admin.suspend(token, id, false);
    return res.redirect('/dashboard');
  }

  @Post('companies/:id/roles')
  async setRoles(
    @Param('id') id: string,
    @Body() body: { roles?: string | string[] },
    @Req() req: Request,
    @Res() res: Response,
  ) {
    const token = this.token(req);
    if (!token) return res.redirect('/login');
    // Les cases à cocher HTML arrivent en string (une seule) ou string[] (plusieurs).
    const roles = Array.isArray(body.roles)
      ? body.roles
      : body.roles
        ? [body.roles]
        : [];
    if (roles.length > 0) {
      try {
        await this.admin.setRoles(token, id, roles);
      } catch {
        /* au moins un rôle est requis côté API : on ignore l'échec et on recharge */
      }
    }
    return res.redirect('/dashboard');
  }

  @Post('payments/:id/confirm')
  async confirmPayment(
    @Param('id') id: string,
    @Req() req: Request,
    @Res() res: Response,
  ) {
    const token = this.token(req);
    if (!token) return res.redirect('/login');
    try {
      await this.admin.confirmPayment(token, id);
    } catch {
      /* recharge le tableau de bord même en cas d'échec */
    }
    return res.redirect('/dashboard');
  }

  @Post('payments/:id/reject')
  async rejectPayment(
    @Param('id') id: string,
    @Req() req: Request,
    @Res() res: Response,
  ) {
    const token = this.token(req);
    if (!token) return res.redirect('/login');
    try {
      await this.admin.rejectPayment(token, id);
    } catch {
      /* idem */
    }
    return res.redirect('/dashboard');
  }

  @Post('payments')
  async recordPayment(
    @Body()
    body: {
      companyId?: string;
      purpose?: string;
      amount?: string;
      currency?: string;
      method?: string;
      provider?: string;
      reference?: string;
      periodMonths?: string;
      quantity?: string;
      productId?: string;
      note?: string;
    },
    @Req() req: Request,
    @Res() res: Response,
  ) {
    const token = this.token(req);
    if (!token) return res.redirect('/login');
    if (body.companyId && body.purpose && body.amount) {
      const payload: Record<string, unknown> = {
        companyId: body.companyId,
        purpose: body.purpose,
        amount: Number(body.amount),
      };
      if (body.currency) payload.currency = body.currency;
      if (body.method) payload.method = body.method;
      if (body.provider) payload.provider = body.provider;
      if (body.reference) payload.reference = body.reference;
      if (body.periodMonths) payload.periodMonths = Number(body.periodMonths);
      if (body.quantity) payload.quantity = Number(body.quantity);
      if (body.productId) payload.productId = body.productId;
      if (body.note) payload.note = body.note;
      try {
        await this.admin.recordPayment(token, payload);
      } catch {
        /* recharge */
      }
    }
    return res.redirect('/dashboard');
  }

  @Post('companies/:id/subscription')
  async subscription(
    @Param('id') id: string,
    @Body()
    body: {
      action?: string;
      months?: string;
      credits?: string;
    },
    @Req() req: Request,
    @Res() res: Response,
  ) {
    const token = this.token(req);
    if (!token) return res.redirect('/login');
    const payload: Record<string, unknown> = {};
    switch (body.action) {
      case 'extend':
        payload.extendMonths = Number(body.months) || 1;
        break;
      case 'downgrade':
        payload.downgrade = true;
        break;
      case 'verify':
        payload.verifyMonths = Number(body.months) || 12;
        break;
      case 'unverify':
        payload.unverify = true;
        break;
      case 'credits':
        payload.leadCredits = Number(body.credits) || 0;
        break;
    }
    if (Object.keys(payload).length > 0) {
      try {
        await this.admin.updateSubscription(token, id, payload);
      } catch {
        /* recharge */
      }
    }
    return res.redirect('/dashboard');
  }
}
