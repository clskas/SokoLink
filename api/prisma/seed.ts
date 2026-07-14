import { PrismaClient, PlatformRole, CompanyRole } from '@prisma/client';
import * as bcrypt from 'bcrypt';
import { AGRO_CATEGORIES } from '../src/common/constants';

const prisma = new PrismaClient();

async function main() {
  for (const cat of AGRO_CATEGORIES) {
    await prisma.category.upsert({
      where: { slug: cat.slug },
      update: { nameFr: cat.nameFr },
      create: { slug: cat.slug, nameFr: cat.nameFr },
    });
  }

  const passwordHash = await bcrypt.hash('AdminSokoLink!2026', 10);
  const adminEmail = 'admin@sokolink.cd';

  const existing = await prisma.user.findUnique({ where: { email: adminEmail } });
  if (!existing) {
    await prisma.user.create({
      data: {
        email: adminEmail,
        passwordHash,
        fullName: 'Admin SokoLink',
        role: PlatformRole.ADMIN,
        company: {
          create: {
            name: 'SokoLink Ops',
            province: 'Kinshasa',
            city: 'Kinshasa',
            phone: '+243800000000',
            roles: [CompanyRole.BUYER],
          },
        },
      },
    });
    console.log('Admin créé: admin@sokolink.cd / AdminSokoLink!2026');
  }

  // Demo supplier products if category exists
  const category = await prisma.category.findFirst();
  const demo = await prisma.user.findUnique({
    where: { email: 'demo@sokolink.cd' },
    include: { company: true },
  });
  if (demo?.company && category) {
    const count = await prisma.product.count({
      where: { companyId: demo.company.id },
    });
    if (count === 0) {
      await prisma.product.create({
        data: {
          companyId: demo.company.id,
          categoryId: category.id,
          type: 'FINISHED',
          name: 'Huile de palme raffinée 20L',
          description:
            'Huile de palme alimentaire conditionnée, adaptée grossistes et Horeca.',
          unit: 'bidon 20L',
          indicativePrice: 45000,
          currency: 'CDF',
          moq: '10 bidons',
          originProvince: 'Kinshasa',
          isFeatured: true,
        },
      });
      await prisma.product.create({
        data: {
          companyId: demo.company.id,
          categoryId: category.id,
          type: 'MP',
          name: 'Noix de palme brutes',
          description: 'Matière première pour huileries, disponibilité mensuelle.',
          unit: 'tonne',
          indicativePrice: 800,
          currency: 'USD',
          capacityPerMonth: '50 tonnes',
          originProvince: 'Équateur',
        },
      });
      console.log('Produits démo ajoutés pour demo@sokolink.cd');
    }
  }

  console.log(`Seeded ${AGRO_CATEGORIES.length} categories`);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
