// competency.cypher - questions with answers verifiable OUTSIDE the graph.
// Sources: Alphabet 10-K FY2025 (acc. 0001652044-26-000018) and FY2024 (acc. 0001652044-25-000014), SEC EDGAR.

// CQ1: What does Alphabet own, directly or through intermediaries?
// EXPECTED (EX-21.01 FY2025 + 2017 restructuring): XXVI Holdings Inc. (1 hop),
//   Alphabet Capital US LLC (1 hop), Google LLC (2 hops, via XXVI Holdings).
MATCH path = (:Company {name: 'Alphabet Inc.'})-[:OWNS*1..5]->(sub:Company)
RETURN sub.name AS subsidiary, length(path) AS hops ORDER BY hops, subsidiary;

// CQ2: Which risk-factor topics are NEW in FY2025 vs FY2024?
// EXPECTED: exactly one - 'disruptions-in-our-ability-to' (access to financing / indebtedness;
//   Alphabet began carrying material debt). Rewordings must NOT appear here.
MATCH (r:RiskFactor)-[:DISCLOSED_IN]->(:Filing {fiscalYear: 2025})
WHERE NOT EXISTS { (r)-[:DISCLOSED_IN]->(:Filing {fiscalYear: 2024}) }
RETURN r.topic AS newIn2025;

// CQ3: Which risk-factor topics were DROPPED after FY2024?
// EXPECTED: exactly one - 'the-trading-price-for-our' (Class A / Class C share-price volatility).
MATCH (r:RiskFactor)-[:DISCLOSED_IN]->(:Filing {fiscalYear: 2024})
WHERE NOT EXISTS { (r)-[:DISCLOSED_IN]->(:Filing {fiscalYear: 2025}) }
RETURN r.topic AS droppedAfter2024;

// CQ4: Total revenues per fiscal year?
// EXPECTED: FY2025 = 402,836 MUSD; FY2024 = 350,018 MUSD (consolidated statements of income).
MATCH (f:Filing) RETURN f.fiscalYear AS year, f.totalRevenueMusd AS totalRevenueMusd ORDER BY year;

// CQ5: Which segment grew fastest FY2024 -> FY2025 (percent)?
// EXPECTED: Google Cloud (+35.8%: 43,229 -> 58,705); Services +12.4%; Other Bets NEGATIVE (-6.7%).
MATCH (s:Segment)-[r24:REPORTED_IN]->(:Filing {fiscalYear: 2024}),
      (s)-[r25:REPORTED_IN]->(:Filing {fiscalYear: 2025})
RETURN s.name AS segment,
       round(1000.0 * (r25.revenueMusd - r24.revenueMusd) / r24.revenueMusd) / 10.0 AS growthPct
ORDER BY growthPct DESC;
