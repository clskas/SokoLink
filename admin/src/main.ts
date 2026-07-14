import { NestFactory } from '@nestjs/core';
import { NestExpressApplication } from '@nestjs/platform-express';
import { join } from 'path';
import cookieParser from 'cookie-parser';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create<NestExpressApplication>(AppModule);
  app.use(cookieParser());
  app.useBodyParser('urlencoded', { extended: true });
  app.useStaticAssets(join(__dirname, '..', 'public'));
  app.setBaseViewsDir(join(__dirname, '..', 'views'));
  app.setViewEngine('hbs');
  const port = Number(process.env.ADMIN_PORT ?? 3200);
  await app.listen(port, '0.0.0.0');
  console.log(`SokoLink Admin listening on http://0.0.0.0:${port}`);
}
bootstrap();
