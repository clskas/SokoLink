import { FreePlanLimits } from './plan-limits';

describe('FreePlanLimits', () => {
  it('keeps free catalogue small', () => {
    expect(FreePlanLimits.maxProducts).toBeLessThanOrEqual(10);
    expect(FreePlanLimits.maxRfqsPerMonth).toBeGreaterThan(0);
  });
});
