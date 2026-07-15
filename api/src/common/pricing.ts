import { PaymentPurpose } from '@prisma/client';

/**
 * Grille tarifaire SokoLink (Phase 1). Montants par défaut en CDF ; la devise
 * reste stockée par paiement pour autoriser aussi l'USD au cas par cas.
 */
export const Pricing = {
  currency: 'CDF',
  proMonthly: 60000,
  proYearly: 600000,
  boostWeekly: 15000,
  boostDaysPerUnit: 7,
  verificationYearly: 90000,
  verificationMonths: 12,
  leadPack: 30000,
  leadPackCredits: 10,
} as const;

export interface PricingPlan {
  code: string;
  purpose: PaymentPurpose;
  label: string;
  amount: number;
  currency: string;
  periodMonths?: number;
  quantity?: number;
  description: string;
}

export const PricingPlans: PricingPlan[] = [
  {
    code: 'PRO_MONTHLY',
    purpose: PaymentPurpose.SUBSCRIPTION,
    label: 'PRO — 1 mois',
    amount: Pricing.proMonthly,
    currency: Pricing.currency,
    periodMonths: 1,
    description:
      'Annonces illimitées, priorité recherche, réponses RFQ illimitées, statistiques.',
  },
  {
    code: 'PRO_YEARLY',
    purpose: PaymentPurpose.SUBSCRIPTION,
    label: 'PRO — 12 mois',
    amount: Pricing.proYearly,
    currency: Pricing.currency,
    periodMonths: 12,
    description: 'Tous les avantages PRO, avec deux mois offerts.',
  },
  {
    code: 'BOOST_WEEK',
    purpose: PaymentPurpose.BOOST,
    label: 'Boost produit — 7 jours',
    amount: Pricing.boostWeekly,
    currency: Pricing.currency,
    quantity: Pricing.boostDaysPerUnit,
    description: 'Met un produit en tête de sa catégorie pendant 7 jours.',
  },
  {
    code: 'VERIFY_YEAR',
    purpose: PaymentPurpose.VERIFICATION,
    label: 'Badge Vérifié — 12 mois',
    amount: Pricing.verificationYearly,
    currency: Pricing.currency,
    periodMonths: Pricing.verificationMonths,
    description: 'Renforce la confiance des acheteurs (KYC validé).',
  },
  {
    code: 'LEAD_PACK',
    purpose: PaymentPurpose.LEAD,
    label: 'Pack 10 crédits de mise en relation',
    amount: Pricing.leadPack,
    currency: Pricing.currency,
    quantity: Pricing.leadPackCredits,
    description: 'Répondez à 10 RFQ supplémentaires au-delà du quota gratuit.',
  },
];
