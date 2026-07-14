export const FreePlanLimits = {
  maxProducts: 5,
  maxRfqsPerMonth: 5,
  maxResponsesPerMonth: 10,
} as const;

export const ProPlanLimits = {
  maxProducts: 100,
  maxRfqsPerMonth: 100,
  maxResponsesPerMonth: 200,
} as const;
