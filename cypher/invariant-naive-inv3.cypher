// The FIRST version of INV3 - "segment revenues must not exceed total revenue".
// Two lessons from real data:
// 1. STRICT form (below) fires on FY2025: segments sum to 402,963 MUSD vs total 402,836,
//    because hedging losses (-127) are a reconciling item at the total line.
//    The test caught a modeling gap, not a data bug.
// 2. My first draft had a habitual 0.1% "rounding tolerance" (f.totalRevenueMusd * 1.001).
//    That tolerance SILENTLY SWALLOWED the 127 MUSD discrepancy (0.03% of total).
//    Values in a 10-K are exact integers in millions - there is nothing to round.
//    A tolerance you can't justify is a blindfold, not robustness.
MATCH (s:Segment)-[rep:REPORTED_IN]->(f:Filing)
WITH f, sum(rep.revenueMusd) AS segTotal
WHERE segTotal > f.totalRevenueMusd
RETURN 'INV3-naive' AS inv, toString(f.fiscalYear) + ': segments=' + toString(segTotal)
       + ' > total=' + toString(f.totalRevenueMusd) AS violation;
