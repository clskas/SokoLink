import {
  BadRequestException,
  ConflictException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { CompanyRole } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { DRC_PROVINCES } from '../common/constants';
import {
  LoginDto,
  RegisterDto,
  RequestOtpDto,
  VerifyOtpDto,
} from './dto/auth.dto';

function normalizePhone(phone: string): string {
  const digits = phone.replace(/[^\d+]/g, '');
  if (digits.startsWith('+')) return digits;
  if (digits.startsWith('243')) return `+${digits}`;
  if (digits.startsWith('0')) return `+243${digits.slice(1)}`;
  return `+243${digits}`;
}

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwt: JwtService,
    private readonly config: ConfigService,
  ) {}

  async requestOtp(dto: RequestOtpDto) {
    const phone = normalizePhone(dto.phone);
    const code = String(Math.floor(100000 + Math.random() * 900000));
    const codeHash = await bcrypt.hash(code, 8);
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000);

    await this.prisma.otpChallenge.create({
      data: { phone, codeHash, expiresAt },
    });

    // MVP: pas de passerelle SMS payante — log serveur.
    // Brancher Twilio / SMS local plus tard via OTP_PROVIDER.
    console.log(`[SokoLink OTP] ${phone} => ${code}`);

    const payload: {
      phone: string;
      expiresInSeconds: number;
      message: string;
      devCode?: string;
    } = {
      phone,
      expiresInSeconds: 600,
      message: 'Code OTP envoyé. Valable 10 minutes.',
    };

    if (this.config.get('OTP_DEV_EXPOSE') === 'true') {
      payload.devCode = code;
    }

    return payload;
  }

  async verifyOtp(dto: VerifyOtpDto) {
    const phone = normalizePhone(dto.phone);
    const challenge = await this.prisma.otpChallenge.findFirst({
      where: { phone, consumedAt: null },
      orderBy: { createdAt: 'desc' },
    });

    if (!challenge || challenge.expiresAt.getTime() < Date.now()) {
      throw new UnauthorizedException('OTP expiré ou introuvable');
    }
    if (challenge.attempts >= 5) {
      throw new UnauthorizedException('Trop de tentatives. Redemandez un OTP.');
    }

    const ok = await bcrypt.compare(dto.code, challenge.codeHash);
    await this.prisma.otpChallenge.update({
      where: { id: challenge.id },
      data: { attempts: { increment: 1 } },
    });
    if (!ok) {
      throw new UnauthorizedException('Code OTP incorrect');
    }

    let user = await this.prisma.user.findUnique({
      where: { phone },
      include: { company: true },
    });

    if (user?.company?.isSuspended) {
      throw new UnauthorizedException('Compte suspendu');
    }

    let isNewUser = false;
    if (!user) {
      isNewUser = true;
      if (!dto.companyName || !dto.province || !dto.roles?.length) {
        // Ne pas consommer l'OTP : le client renvoie le même code avec le profil.
        return {
          needsProfile: true,
          phone,
          message:
            'Compte nouveau : complétez le profil entreprise avec le même code OTP.',
        };
      }
      if (!(DRC_PROVINCES as readonly string[]).includes(dto.province)) {
        throw new BadRequestException('Province invalide');
      }
      user = await this.prisma.user.create({
        data: {
          phone,
          fullName: dto.fullName,
          email: null,
          passwordHash: null,
          company: {
            create: {
              name: dto.companyName,
              province: dto.province,
              city: dto.city,
              phone,
              whatsapp: phone,
              roles: dto.roles as CompanyRole[],
            },
          },
        },
        include: { company: true },
      });
    }

    await this.prisma.otpChallenge.update({
      where: { id: challenge.id },
      data: { consumedAt: new Date() },
    });

    const auth = await this.buildAuthResponse(user);
    return { ...auth, isNewUser, needsProfile: false };
  }

  async register(dto: RegisterDto) {
    const phone = normalizePhone(dto.phone);
    if (dto.email) {
      const existingEmail = await this.prisma.user.findUnique({
        where: { email: dto.email.toLowerCase() },
      });
      if (existingEmail) {
        throw new ConflictException('Cet email est déjà utilisé');
      }
    }
    const existingPhone = await this.prisma.user.findUnique({
      where: { phone },
    });
    if (existingPhone) {
      throw new ConflictException('Ce téléphone est déjà utilisé');
    }

    if (!(DRC_PROVINCES as readonly string[]).includes(dto.province)) {
      throw new BadRequestException('Province invalide');
    }

    const passwordHash = dto.password
      ? await bcrypt.hash(dto.password, 10)
      : null;

    const user = await this.prisma.user.create({
      data: {
        email: dto.email?.toLowerCase() ?? null,
        passwordHash,
        fullName: dto.fullName,
        phone,
        company: {
          create: {
            name: dto.companyName,
            province: dto.province,
            city: dto.city,
            phone,
            whatsapp: dto.whatsapp ?? phone,
            email: dto.email?.toLowerCase(),
            roles: dto.roles,
          },
        },
      },
      include: { company: true },
    });

    return this.buildAuthResponse(user);
  }

  async login(dto: LoginDto) {
    const user = await this.prisma.user.findUnique({
      where: { email: dto.email.toLowerCase() },
      include: { company: true },
    });
    if (!user?.passwordHash) {
      throw new UnauthorizedException('Email ou mot de passe incorrect');
    }

    const ok = await bcrypt.compare(dto.password, user.passwordHash);
    if (!ok) {
      throw new UnauthorizedException('Email ou mot de passe incorrect');
    }

    if (user.company?.isSuspended) {
      throw new UnauthorizedException('Compte suspendu');
    }

    return this.buildAuthResponse(user);
  }

  async refresh(refreshToken: string) {
    try {
      const payload = await this.jwt.verifyAsync<{ sub: string }>(
        refreshToken,
        { secret: this.config.getOrThrow<string>('JWT_REFRESH_SECRET') },
      );
      const user = await this.prisma.user.findUnique({
        where: { id: payload.sub },
        include: { company: true },
      });
      if (!user) throw new UnauthorizedException('Refresh token invalide');
      if (user.company?.isSuspended) {
        throw new UnauthorizedException('Compte suspendu');
      }
      return this.buildAuthResponse(user);
    } catch (err) {
      if (err instanceof UnauthorizedException) throw err;
      throw new UnauthorizedException('Refresh token invalide');
    }
  }

  async me(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: { company: { include: { documents: true } } },
    });
    if (!user) {
      throw new UnauthorizedException();
    }
    if (user.company?.isSuspended) {
      throw new UnauthorizedException('Compte suspendu');
    }
    return this.sanitizeUser(user);
  }

  private async buildAuthResponse(user: {
    id: string;
    email: string | null;
    fullName: string | null;
    phone: string | null;
    role: string;
    companyId: string | null;
    company?: unknown;
  }) {
    const payload = {
      sub: user.id,
      email: user.email,
      role: user.role,
      companyId: user.companyId,
    };

    const accessToken = await this.jwt.signAsync(payload, {
      secret: this.config.getOrThrow<string>('JWT_ACCESS_SECRET'),
      expiresIn: this.config.get('JWT_ACCESS_EXPIRES', '90d'),
    });

    const refreshToken = await this.jwt.signAsync(
      { sub: user.id },
      {
        secret: this.config.getOrThrow<string>('JWT_REFRESH_SECRET'),
        expiresIn: this.config.get('JWT_REFRESH_EXPIRES', '365d'),
      },
    );

    return {
      accessToken,
      refreshToken,
      user: this.sanitizeUser(user),
    };
  }

  private sanitizeUser(user: {
    id: string;
    email: string | null;
    fullName: string | null;
    phone: string | null;
    role: string;
    companyId: string | null;
    company?: unknown;
  }) {
    return {
      id: user.id,
      email: user.email,
      fullName: user.fullName,
      phone: user.phone,
      role: user.role,
      companyId: user.companyId,
      company: user.company ?? null,
    };
  }
}
