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
      const [stats, companies, documents, proRequests] = await Promise.all([
        this.admin.stats(token),
        this.admin.companies(token),
        this.admin.documents(token),
        this.admin.proRequests(token),
      ]);
      return res.render('dashboard', {
        title: 'Admin SokoLink',
        stats,
        companies,
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
}
