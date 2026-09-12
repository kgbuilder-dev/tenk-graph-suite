// tripwire.cypher - counts to compare against the previous ingest.
MATCH (n) RETURN 'nodes:' + head(labels(n)) AS what, count(*) AS n ORDER BY what
UNION ALL
MATCH ()-[r]->() RETURN 'rels:' + type(r) AS what, count(*) AS n ORDER BY what;
