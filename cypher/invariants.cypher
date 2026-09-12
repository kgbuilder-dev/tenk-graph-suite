// invariants.cypher - states the domain forbids. Every query MUST return zero rows.

// INV1: No company may own itself, directly or transitively.
MATCH (c:Company)-[:OWNS*]->(c) RETURN 'INV1' AS inv, c.name AS violation;

// INV2: Every filing has exactly one filer and a fiscal year.
MATCH (f:Filing)
WHERE f.fiscalYear IS NULL OR COUNT { (f)-[:FILED_BY]->(:Company) } <> 1
RETURN 'INV2' AS inv, f.form + '/' + coalesce(toString(f.fiscalYear),'?') AS violation;

// INV3: Reported segment revenues must reconcile EXACTLY with the filing's total revenues
// via the hedging line: total = sum(segments) + hedgingGains. No tolerance: 10-K values are
// exact integers in millions - there is nothing to round, and an unjustified tolerance is
// exactly what swallowed the 127 MUSD hedging gap in the first draft.
// NOTE: the naive form (sum(segments) <= total) FIRES on real FY2025 data - segments sum to
// 402,963 vs total 402,836, because hedging LOSSES (-127) net out at the total line.
// See invariant-naive-inv3.cypher for that version, kept as a demonstration.
MATCH (s:Segment)-[rep:REPORTED_IN]->(f:Filing)
WITH f, sum(rep.revenueMusd) AS segTotal
WHERE segTotal + f.hedgingGainsMusd <> f.totalRevenueMusd
RETURN 'INV3' AS inv, toString(f.fiscalYear) + ': segments=' + toString(segTotal) AS violation;

// INV4: No orphan risk factors - every RiskFactor is disclosed in at least one filing.
MATCH (r:RiskFactor) WHERE NOT (r)-[:DISCLOSED_IN]->(:Filing)
RETURN 'INV4' AS inv, r.topic AS violation;
