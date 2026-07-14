import { Controller, Get, NotFoundException, Param } from '@nestjs/common';
import { readFileSync, existsSync } from 'fs';
import { join } from 'path';

const DOCS_CANDIDATES = [
  join(process.cwd(), '..', 'docs'),
  join(process.cwd(), 'docs'),
  join(__dirname, '..', '..', '..', 'docs'),
];

function resolveDocsRoot(): string {
  for (const candidate of DOCS_CANDIDATES) {
    if (existsSync(candidate)) return candidate;
  }
  return DOCS_CANDIDATES[0];
}

@Controller('legal')
export class LegalController {
  private readDoc(relativePath: string): string {
    const full = join(resolveDocsRoot(), relativePath);
    if (!existsSync(full)) {
      throw new NotFoundException(`Document introuvable: ${relativePath}`);
    }
    return readFileSync(full, 'utf8');
  }

  @Get('cgu')
  cgu() {
    return {
      slug: 'cgu',
      title: 'Conditions Générales d’Utilisation',
      content: this.readDoc(join('legal', 'cgu.md')),
      updatedAt: '2026-07-14',
    };
  }

  @Get('confidentialite')
  privacy() {
    return {
      slug: 'confidentialite',
      title: 'Politique de confidentialité',
      content: this.readDoc(join('legal', 'confidentialite.md')),
      updatedAt: '2026-07-14',
    };
  }

  @Get('manuel')
  manual() {
    return {
      slug: 'manuel',
      title: 'Manuel d’utilisation SokoLink',
      content: this.readDoc('manuel-utilisateur.md'),
      updatedAt: '2026-07-14',
    };
  }

  @Get(':slug')
  bySlug(@Param('slug') slug: string) {
    if (slug === 'cgu') return this.cgu();
    if (slug === 'confidentialite') return this.privacy();
    if (slug === 'manuel') return this.manual();
    throw new NotFoundException();
  }
}
