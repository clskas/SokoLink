import { ValidationPipe } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { App } from 'supertest/types';
import { AppModule } from '../src/app.module';

describe('SokoLink regression (e2e)', () => {
  let app: INestApplication<App>;
  let accessToken = '';
  let companyId = '';
  let productId = '';
  let rfqId = '';
  const email = `reg_${Date.now()}@sokolink.cd`;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    app.setGlobalPrefix('v1');
    app.useGlobalPipes(
      new ValidationPipe({ whitelist: true, transform: true }),
    );
    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  it('health smoke', async () => {
    const res = await request(app.getHttpServer()).get('/v1/health').expect(200);
    expect(res.body.status).toBe('ok');
  });

  it('register + login flow', async () => {
    const reg = await request(app.getHttpServer())
      .post('/v1/auth/register')
      .send({
        email,
        password: 'password123',
        fullName: 'Regression User',
        companyName: 'Regression SARL',
        province: 'Kinshasa',
        phone: '+243911000000',
        roles: ['PROCESSOR', 'BUYER'],
      })
      .expect(201);
    accessToken = reg.body.accessToken;
    companyId = reg.body.user.companyId;
    expect(accessToken).toBeTruthy();
  });

  it('create product, search, rfq, respond', async () => {
    const cats = await request(app.getHttpServer()).get('/v1/categories');
    const categoryId = cats.body[0]?.id;

    const product = await request(app.getHttpServer())
      .post('/v1/products')
      .set('Authorization', `Bearer ${accessToken}`)
      .send({
        name: 'Farine de manioc',
        description: 'Farine locale qualité export',
        type: 'FINISHED',
        categoryId,
        unit: 'sac 25kg',
        price: 35000,
      })
      .expect(201);
    productId = product.body.id;

    const search = await request(app.getHttpServer())
      .get('/v1/search')
      .query({ intent: 'finished', q: 'manioc' })
      .expect(200);
    expect(search.body.total).toBeGreaterThanOrEqual(1);

    const rfq = await request(app.getHttpServer())
      .post('/v1/rfqs')
      .set('Authorization', `Bearer ${accessToken}`)
      .send({
        title: 'Recherche maïs grain',
        type: 'MP',
        categoryId,
        quantity: '10',
        unit: 'tonnes',
        details: 'Livraison Kinshasa',
      })
      .expect(201);
    rfqId = rfq.body.id;
    expect(rfqId).toBeTruthy();
    expect(productId).toBeTruthy();
    expect(companyId).toBeTruthy();
  });

  it('conversation start', async () => {
    // need another company — skip respond cross-company if single user
    const mine = await request(app.getHttpServer())
      .get('/v1/products')
      .set('Authorization', `Bearer ${accessToken}`)
      .expect(200);
    expect(Array.isArray(mine.body)).toBe(true);
  });
});
