# Alphabet 10-K Knowledge Graph + Test Suite

A small, fully-verifiable knowledge graph built from Alphabet's SEC 10-K filings
(FY2024 + FY2025), with the test suite that proves it correct: competency questions,
invariants, and count tripwires. Companion repo for the article
["How I Test a Knowledge Graph"](https://akkonrad.medium.com/how-i-test-a-knowledge-graph-fc6a90d8da06).

Every number in the seed data traces to a public SEC EDGAR document. No LLM extraction -
this graph is hand-curated so the ground truth is checkable by anyone.

## Data sources

| What | Where | Filing |
|---|---|---|
| Subsidiaries + ownership | Exhibit 21.01 (`googexhibit2101q42025.htm`) | 10-K FY2025, acc. 0001652044-26-000018, filed 2026-02-05 |
| Segment revenues, total revenues, hedging | Segment note (XBRL report R90) | 10-K FY2025 (contains FY2024/FY2023 comparatives) |
| Risk-factor headings | Item 1A | 10-K FY2025 + 10-K FY2024 (acc. 0001652044-25-000014) |

Notes on modeling choices:
- Exhibit 21 lists only three significant subsidiaries (Google LLC, XXVI Holdings Inc.,
  Alphabet Capital US LLC). The `OWNS` chain Alphabet -> XXVI Holdings -> Google LLC follows
  the 2017 restructuring in which XXVI Holdings became the intermediate holder of Google's
  equity; Exhibit 21 itself lists subsidiaries flat ("direct or indirect").
- Risk factors carry a stable `topic` key across years, so rewordings of the same risk do
  not show up as new/dropped. 29 topics: 27 in both years, 1 new in FY2025
  (access to financing / indebtedness), 1 dropped after FY2024 (share-price volatility).

## Run it

```bash
docker rm -f tenk-neo4j 2>/dev/null; true  # clear a leftover container from a previous run
docker run -d --name tenk-neo4j -p 7799:7687 -e NEO4J_AUTH=neo4j/tenktest123 neo4j:5-community
# wait ~10s for startup
docker exec -i tenk-neo4j cypher-shell -u neo4j -p tenktest123 < cypher/load.cypher
docker exec -i tenk-neo4j cypher-shell -u neo4j -p tenktest123 --format plain < cypher/competency.cypher
docker exec -i tenk-neo4j cypher-shell -u neo4j -p tenktest123 --format plain < cypher/invariants.cypher
docker exec -i tenk-neo4j cypher-shell -u neo4j -p tenktest123 --format plain < cypher/tripwire.cypher
```

Works against any Neo4j 5+ (Aura included): swap the address/credentials in `cypher-shell`.

## What's in the suite

- `cypher/competency.cypher` - 5 questions with expected answers documented in comments,
  each verifiable against the filings (acceptance tests).
- `cypher/invariants.cypher` - 4 queries that must return zero rows forever (assertions).
- `cypher/invariant-naive-inv3.cypher` - the first, wrong version of INV3, kept on purpose:
  strict "segments must not exceed total" FIRES on real FY2025 data (segments 402,963 MUSD
  vs total 402,836), because hedging losses (-127) reconcile at the total line. And the
  habitual 0.1% "rounding tolerance" from my first draft silently swallowed that 127 MUSD
  gap. Both lessons are the point of the companion article.
- `cypher/tripwire.cypher` - label/relationship counts to diff between ingests
  (regression tests).
- `results/` - actual outputs from the run documented in the article, including the
  controlled entity-resolution corruption that makes INV1 fire (`inv1-corruption-demo.txt`).
- `data/seed/*.csv` - the curated source data. The original EDGAR documents are not
  committed (they are large and public); fetch them from SEC EDGAR using the accession
  numbers in the table above.

## CI

One line per file: run each `.cypher` through `cypher-shell` and fail the build on
non-empty output from the invariant files.
