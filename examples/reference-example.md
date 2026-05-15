---
name: database-egress-diagnosis
description: Standard 15-minute method to localize a database egress spike (PostgreSQL + PostgREST stack). pg_stat_statements queryid clustering + common false leads + three-tier cache split + optimistic mutation writes.
type: reference
---

# Database Egress Diagnosis

A reusable diagnostic pipeline for the case "egress is climbing and the dashboard can't tell me which query." Written for PostgreSQL + PostgREST (e.g. Supabase).

## Diagnosis (15 minutes to a culprit)

```sql
-- 1. Confirm pg_stat_statements covers the window when egress climbed
SELECT stats_reset, NOW() - stats_reset AS uptime FROM pg_stat_statements_info;

-- 2. Cluster by queryid; sort by calls × rows
-- For PostgREST CTE pgrst_source, calls = rows = actual request count
SELECT queryid, LEFT(REPLACE(query, E'\n', ' '), 180) AS q, calls, rows
FROM pg_stat_statements
WHERE query NOT ILIKE '%pg_stat%'
ORDER BY rows DESC NULLS LAST LIMIT 30;

-- 3. The same logical query may produce multiple queryids
-- (PostgREST regenerates prepared statements when SELECT fields change)
```

## False Leads to Skip

Two recurring wrong answers when egress climbs:

- "Component mount triggers refetch — add staleTime 30s." Global staleTime is usually already set (e.g. React Query 5min). 30s is shorter, so this makes it worse.
- "refetchOnWindowFocus is too aggressive." Often already disabled globally.

The real culprit is almost always **mutation invalidate** — mutations force a refetch regardless of staleTime.

## Treatment: Three-Tier Cache Split

Applies when one query dominates PostgREST calls (e.g. > 50% of total rows):

| Tier | Purpose | Row size |
|---|---|---|
| Lightweight IDs | "Does this exist?" checks (isFavorited, hasItem) | ~80B |
| Full WithContent | Renders nested data | ~2KB+ |
| Single Detail | Detail panel, server-side RLS filtered | ~300B |

Mutation strategy:

- High-frequency toggles: optimistically write IDs + WithContent (only if cache already populated). Use real id to swap temp_id. Do not call `invalidateQueries`.
- Low-frequency user-driven mutations: `invalidate WithContent` as a safety net is fine.
- 23505 path (cache out of sync with server): fall back to a real lookup to fetch the canonical row.

## When This Pattern Applies

- Database egress climbing + dashboard cannot localize the source → walk through pg_stat queryid clustering above
- Do not assume `staleTime` / `refetchOnWindowFocus` is the cause until you have ruled out mutation invalidate
