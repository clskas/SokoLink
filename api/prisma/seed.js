const { PrismaClient, PlatformRole, CompanyRole } = require('@prisma/client');
const bcrypt = require('bcrypt');

const prisma = new PrismaClient();

const AGRO_CATEGORIES = [
  { slug: 'cereales-farines', nameFr: 'Céréales & farines' },
  { slug: 'tubercules', nameFr: 'Tubercules & dérivés' },
  { slug: 'huiles', nameFr: 'Huiles & oléagineux' },
  { slug: 'sucre', nameFr: 'Sucre & édulcorants' },
  { slug: 'cafe-cacao-the', nameFr: 'Café, cacao, thé' },
  { slug: 'proteines', nameFr: 'Protéines (viande, poisson, volaille)' },
  { slug: 'fruits-legumes', nameFr: 'Fruits, légumes & transformés' },
  { slug: 'boissons', nameFr: 'Boissons' },
  { slug: 'laitiers', nameFr: 'Produits laitiers' },
  { slug: 'emballages', nameFr: 'Emballages alimentaires' },
  { slug: 'autres', nameFr: 'Autres agro' },
];

async function main() {
  for (const cat of AGRO_CATEGORIES) {
    await prisma.category.upsert({
      where: { slug: cat.slug },
      update: { nameFr: cat.nameFr },
      create: { slug: cat.slug, nameFr: cat.nameFr },
    });
  }

  const adminEmail = 'admin@sokolink.cd';
  const existing = await prisma.user.findUnique({ where: { email: adminEmail } });
  if (!existing) {
    const passwordHash = await bcrypt.hash('AdminSokoLink!2026', 10);
    await prisma.user.create({
      data: {
        email: adminEmail,
        passwordHash,
        fullName: 'Admin SokoLink',
        phone: '+243800000000',
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

  const demoPhone = '+243900000001';
  const demo = await prisma.user.findUnique({ where: { phone: demoPhone } });
  if (!demo) {
    await prisma.user.create({
      data: {
        phone: demoPhone,
        email: 'demo@sokolink.cd',
        fullName: 'Demo SokoLink',
        passwordHash: null,
        company: {
          create: {
            name: 'Agro Demo Kin',
            province: 'Kinshasa',
            city: 'Kinshasa',
            phone: demoPhone,
            whatsapp: demoPhone,
            roles: [CompanyRole.SUPPLIER_MP, CompanyRole.PROCESSOR],
          },
        },
      },
    });
    console.log('Demo OTP phone: +243900000001 (utiliser POST /auth/otp/request)');
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
