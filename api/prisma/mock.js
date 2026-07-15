/**
 * Données mock SokoLink pour tests manuels / démo.
 *
 * Chaque entreprise a un téléphone : connectez-vous par OTP
 * (POST /v1/auth/otp/request) avec ce numéro. En dev, le code OTP
 * s'affiche dans la réponse (OTP_DEV_EXPOSE=true) et dans les logs API.
 *
 * Lancement : npm run prisma:mock   (ré-exécutable : réinitialise le mock)
 */
const { PrismaClient, CompanyRole, ProductType, DocumentType, DocumentStatus, RfqStatus, DealStatus } = require('@prisma/client');

const prisma = new PrismaClient();

const MOCK_TAG = '[MOCK]';

const COMPANIES = [
  {
    phone: '+243810000001',
    fullName: 'Céline Mbayo',
    name: 'Minoterie du Fleuve',
    province: 'Kinshasa',
    city: 'Kinshasa',
    roles: [CompanyRole.PROCESSOR],
    plan: 'PRO',
    description: 'Transformation de céréales : farines de maïs et de blé.',
    documents: [
      { type: DocumentType.RCCM, status: DocumentStatus.ACCEPTED },
      { type: DocumentType.NIF, status: DocumentStatus.ACCEPTED },
    ],
    products: [
      { cat: 'cereales-farines', type: ProductType.FINISHED, name: 'Farine de maïs 25kg', unit: 'sac', price: '38500', moq: '20 sacs', capacity: '15 000 sacs' },
      { cat: 'cereales-farines', type: ProductType.FINISHED, name: 'Farine de blé T55 50kg', unit: 'sac', price: '72000', moq: '10 sacs', capacity: '8 000 sacs' },
    ],
  },
  {
    phone: '+243810000002',
    fullName: 'Jean-Pierre Kalonji',
    name: 'Coopérative Maïs Kwilu',
    province: 'Kwilu',
    city: 'Bandundu',
    roles: [CompanyRole.SUPPLIER_MP],
    plan: 'FREE',
    description: 'Coopérative agricole : maïs grain et manioc en gros.',
    documents: [{ type: DocumentType.RCCM, status: DocumentStatus.IN_REVIEW }],
    products: [
      { cat: 'cereales-farines', type: ProductType.MP, name: 'Maïs grain jaune', unit: 'kg', price: '900', moq: '500 kg', capacity: '80 t' },
      { cat: 'tubercules', type: ProductType.MP, name: 'Cossettes de manioc', unit: 'kg', price: '700', moq: '300 kg', capacity: '40 t' },
    ],
  },
  {
    phone: '+243810000003',
    fullName: 'Aline Bahati',
    name: 'Huilerie Sud-Kivu',
    province: 'Sud-Kivu',
    city: 'Bukavu',
    roles: [CompanyRole.SUPPLIER_MP, CompanyRole.PROCESSOR],
    plan: 'PRO',
    description: 'Production d’huile de palme brute et raffinée.',
    documents: [
      { type: DocumentType.RCCM, status: DocumentStatus.ACCEPTED },
      { type: DocumentType.ID_CARD, status: DocumentStatus.ACCEPTED },
    ],
    products: [
      { cat: 'huiles', type: ProductType.MP, name: 'Huile de palme brute', unit: 'L', price: '2600', moq: '200 L', capacity: '25 000 L' },
      { cat: 'huiles', type: ProductType.FINISHED, name: 'Huile végétale raffinée 1L', unit: 'bouteille', price: '3800', moq: '120 u', capacity: '30 000 u' },
    ],
  },
  {
    phone: '+243810000004',
    fullName: 'Patrick Ilunga',
    name: 'Distribution Katanga B2B',
    province: 'Haut-Katanga',
    city: 'Lubumbashi',
    roles: [CompanyRole.BUYER],
    plan: 'FREE',
    description: 'Centrale d’achat pour supermarchés du Katanga.',
    documents: [{ type: DocumentType.NIF, status: DocumentStatus.ACCEPTED }],
    products: [],
  },
  {
    phone: '+243810000005',
    fullName: 'Grace Nsimba',
    name: 'Grossiste Kin Alimentaire',
    province: 'Kinshasa',
    city: 'Kinshasa',
    roles: [CompanyRole.BUYER],
    plan: 'PRO',
    description: 'Grossiste B2B, approvisionnement HORECA à Kinshasa.',
    documents: [
      { type: DocumentType.RCCM, status: DocumentStatus.ACCEPTED },
      { type: DocumentType.NIF, status: DocumentStatus.ACCEPTED },
    ],
    products: [],
  },
  {
    phone: '+243810000006',
    fullName: 'Emmanuel Kambale',
    name: 'Cacao Beni Export',
    province: 'Nord-Kivu',
    city: 'Beni',
    roles: [CompanyRole.SUPPLIER_MP],
    plan: 'FREE',
    description: 'Fèves de cacao et café vert de qualité export.',
    documents: [{ type: DocumentType.RCCM, status: DocumentStatus.REJECTED, rejectReason: 'Document illisible, renvoyer un scan net.' }],
    products: [
      { cat: 'cafe-cacao-the', type: ProductType.MP, name: 'Fèves de cacao séchées', unit: 'kg', price: '4200', moq: '250 kg', capacity: '12 t' },
      { cat: 'cafe-cacao-the', type: ProductType.MP, name: 'Café vert arabica', unit: 'kg', price: '5100', moq: '200 kg', capacity: '9 t' },
    ],
  },
  {
    phone: '+243810000007',
    fullName: 'Sylvie Mavinga',
    name: 'Boissons Congo SARL',
    province: 'Kongo-Central',
    city: 'Matadi',
    roles: [CompanyRole.PROCESSOR],
    plan: 'FREE',
    description: 'Jus de fruits locaux et boissons embouteillées.',
    documents: [{ type: DocumentType.RCCM, status: DocumentStatus.IN_REVIEW }],
    products: [
      { cat: 'boissons', type: ProductType.FINISHED, name: 'Jus d’ananas 33cl', unit: 'bouteille', price: '1500', moq: '240 u', capacity: '50 000 u' },
      { cat: 'fruits-legumes', type: ProductType.FINISHED, name: 'Purée de mangue 1kg', unit: 'pot', price: '4300', moq: '60 u', capacity: '10 000 u' },
    ],
  },
];

// Numéros clés rappelés à la fin (déjà créés par seed.js pour le compte demo).
const DEMO_PHONE = '+243900000001';

async function categoryMap() {
  const cats = await prisma.category.findMany();
  const map = {};
  for (const c of cats) map[c.slug] = c.id;
  return map;
}

async function resetMock() {
  const mockPhones = COMPANIES.map((c) => c.phone);
  const users = await prisma.user.findMany({
    where: { phone: { in: mockPhones } },
    select: { id: true, companyId: true },
  });
  const companyIds = users.map((u) => u.companyId).filter(Boolean);
  if (companyIds.length === 0) return;

  const rfqs = await prisma.rfq.findMany({
    where: { issuerCompanyId: { in: companyIds } },
    select: { id: true },
  });
  const rfqIds = rfqs.map((r) => r.id);

  // Conversations/messages liées à ces entreprises (pas de FK -> nettoyage manuel).
  const convs = await prisma.conversation.findMany({
    where: {
      OR: [
        { companyAId: { in: companyIds } },
        { companyBId: { in: companyIds } },
      ],
    },
    select: { id: true },
  });
  const convIds = convs.map((c) => c.id);

  await prisma.message.deleteMany({ where: { conversationId: { in: convIds } } });
  await prisma.conversation.deleteMany({ where: { id: { in: convIds } } });
  await prisma.rfqResponse.deleteMany({
    where: {
      OR: [
        { companyId: { in: companyIds } },
        { rfqId: { in: rfqIds } },
      ],
    },
  });
  await prisma.rfq.deleteMany({ where: { issuerCompanyId: { in: companyIds } } });
  await prisma.proRequest.deleteMany({ where: { companyId: { in: companyIds } } });
  await prisma.user.deleteMany({ where: { phone: { in: mockPhones } } });
  await prisma.company.deleteMany({ where: { id: { in: companyIds } } }); // cascade products + documents
}

async function main() {
  const cats = await categoryMap();
  if (Object.keys(cats).length === 0) {
    throw new Error('Aucune catégorie. Lancez d’abord `npm run prisma:seed`.');
  }

  await resetMock();

  const created = {};
  for (const c of COMPANIES) {
    const user = await prisma.user.create({
      data: {
        phone: c.phone,
        fullName: c.fullName,
        company: {
          create: {
            name: c.name,
            description: c.description,
            province: c.province,
            city: c.city,
            phone: c.phone,
            whatsapp: c.phone,
            roles: c.roles,
            plan: c.plan,
            documents: {
              create: c.documents.map((d) => ({
                type: d.type,
                status: d.status,
                rejectReason: d.rejectReason,
                fileUrl: `/uploads/mock-${d.type.toLowerCase()}.pdf`,
              })),
            },
            products: {
              create: c.products.map((p, i) => ({
                categoryId: cats[p.cat],
                type: p.type,
                name: p.name,
                description: `${p.name} — ${MOCK_TAG} produit de démonstration.`,
                unit: p.unit,
                indicativePrice: p.price,
                currency: 'CDF',
                moq: p.moq,
                capacityPerMonth: p.capacity,
                originProvince: c.province,
                isFeatured: c.plan === 'PRO' && i === 0,
              })),
            },
          },
        },
      },
      include: { company: { include: { products: true } } },
    });
    created[c.phone] = user;
  }

  // RFQ : les acheteurs publient des demandes.
  const buyerKatanga = created['+243810000004'].company;
  const buyerKin = created['+243810000005'].company;
  const minoterie = created['+243810000001'].company;
  const coopMais = created['+243810000002'].company;
  const huilerie = created['+243810000003'].company;
  const cacao = created['+243810000006'].company;

  const rfq1 = await prisma.rfq.create({
    data: {
      issuerCompanyId: buyerKin.id,
      title: 'Farine de maïs 25kg — 500 sacs / mois',
      type: ProductType.FINISHED,
      categoryId: cats['cereales-farines'],
      quantity: '500',
      unit: 'sac',
      budgetHint: '37 000 - 39 000 CDF/sac',
      targetProvinces: ['Kinshasa', 'Kongo-Central'],
      details: `Approvisionnement récurrent pour réseau HORECA. ${MOCK_TAG}`,
      status: RfqStatus.PUBLISHED,
      isOpen: true,
      dealStatus: DealStatus.IN_DISCUSSION,
    },
  });

  const rfq2 = await prisma.rfq.create({
    data: {
      issuerCompanyId: buyerKatanga.id,
      title: 'Maïs grain jaune — 20 tonnes',
      type: ProductType.MP,
      categoryId: cats['cereales-farines'],
      quantity: '20000',
      unit: 'kg',
      budgetHint: '850 - 950 CDF/kg',
      targetProvinces: ['Kwilu', 'Kinshasa'],
      details: `Livraison Lubumbashi souhaitée sous 3 semaines. ${MOCK_TAG}`,
      status: RfqStatus.PUBLISHED,
      isOpen: true,
    },
  });

  const rfq3 = await prisma.rfq.create({
    data: {
      issuerCompanyId: buyerKin.id,
      title: 'Huile végétale raffinée 1L — 3 000 unités',
      type: ProductType.FINISHED,
      categoryId: cats['huiles'],
      quantity: '3000',
      unit: 'bouteille',
      budgetHint: '3 500 - 4 000 CDF/u',
      targetProvinces: ['Sud-Kivu', 'Kinshasa'],
      details: `Marque distributeur possible. ${MOCK_TAG}`,
      status: RfqStatus.PUBLISHED,
      isOpen: true,
    },
  });

  // Réponses de fournisseurs aux RFQ.
  await prisma.rfqResponse.createMany({
    data: [
      { rfqId: rfq1.id, companyId: minoterie.id, price: '38 000 CDF/sac', leadTime: '7 jours', comment: `Capacité confirmée. ${MOCK_TAG}` },
      { rfqId: rfq2.id, companyId: coopMais.id, price: '900 CDF/kg', leadTime: '15 jours', comment: `Transport en sus. ${MOCK_TAG}` },
      { rfqId: rfq3.id, companyId: huilerie.id, price: '3 800 CDF/u', leadTime: '10 jours', comment: `MDD acceptée dès 5 000 u. ${MOCK_TAG}` },
    ],
  });

  // Conversations + messages.
  const conv1 = await prisma.conversation.create({
    data: {
      companyAId: buyerKin.id,
      companyBId: minoterie.id,
      rfqId: rfq1.id,
      messages: {
        create: [
          { senderUserId: created['+243810000005'].id, body: `Bonjour, votre farine 25kg est-elle disponible en volume ? ${MOCK_TAG}` },
          { senderUserId: created['+243810000001'].id, body: 'Bonjour, oui 15 000 sacs/mois. Je peux livrer sous 7 jours.' },
          { senderUserId: created['+243810000005'].id, body: 'Parfait, envoyez une proforma pour 500 sacs.' },
        ],
      },
    },
  });

  const conv2 = await prisma.conversation.create({
    data: {
      companyAId: buyerKatanga.id,
      companyBId: cacao.id,
      messages: {
        create: [
          { senderUserId: created['+243810000004'].id, body: `Quel est votre prix cacao pour 1 tonne ? ${MOCK_TAG}` },
          { senderUserId: created['+243810000006'].id, body: 'Bonjour, 4 200 CDF/kg départ Beni. Qualité export.' },
        ],
      },
    },
  });

  // Une demande Pro en attente (pour tester l'admin).
  await prisma.proRequest.create({
    data: {
      companyId: coopMais.id,
      proofUrl: '/uploads/mock-proof-pro.png',
      note: `Demande de passage au plan Pro. ${MOCK_TAG}`,
      status: 'PENDING',
    },
  });

  const productCount = await prisma.product.count();
  console.log('\n=== Données mock SokoLink créées ===');
  console.log(`Entreprises mock : ${COMPANIES.length}`);
  console.log('RFQ : 3 | Réponses : 3 | Conversations : 2 | Pro request : 1');
  console.log(`Produits totaux en base : ${productCount}`);
  console.log('\nConnexion par OTP (le code s’affiche en dev) :');
  for (const c of COMPANIES) {
    console.log(`  ${c.phone}  ${c.name}  [${c.roles.join(', ')}] ${c.plan}`);
  }
  console.log(`  ${DEMO_PHONE}  Compte démo (seed)`);
  console.log('\nAdmin web : admin@sokolink.cd / AdminSokoLink!2026');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
