---
name: supabase-egress-diagnosis
description: ⭐⭐ Supabase egress 诊断标准方法 + 案例(25-37GB/天 → ~4GB/天,-85%)。pg_stat queryid 聚类 + "加 staleTime"是反复被错提的无效优化 + 治本是三层 cache 拆 + mutation 乐观双写
type: reference
---

# Supabase Egress 诊断标准方法

## 诊断方法(15 分钟内定位)

```sql
-- 1. pg_stat_statements 看 stats_reset 时间(确认窗口跟 egress 抬头对齐)
SELECT stats_reset, NOW() - stats_reset AS uptime FROM pg_stat_statements_info;

-- 2. 按 queryid 聚类找 calls × rows 大头
-- 关键:PostgREST CTE pgrst_source 模式下 calls = rows = 实际请求次数
SELECT queryid, LEFT(REPLACE(query, E'\n', ' '), 180) AS q, calls, rows
FROM pg_stat_statements
WHERE query NOT ILIKE '%pg_stat%'
ORDER BY rows DESC NULLS LAST LIMIT 30;

-- 3. 同一逻辑 query 可能有多个 queryid(SELECT 字段变化时 PostgREST 重生成 prepared statement)
```

## ⚠️ 反复被错误提出的"加 staleTime"无效优化

全局 staleTime 通常已设(例如 React Query 5min)。所以以下诊断结论永远是**错的**:

- "组件挂载触发 refetch,加 staleTime 30s"— ❌ 30s 比 5min 短反而变差
- "refetchOnWindowFocus 触发太多"— ❌ 全局已禁用

**真凶永远是 mutation invalidate**(不受 staleTime 影响,强制重拉)。

## 治本架构(适用 query 占 PostgREST calls > 50%)

三层 cache 拆分:

| 层 | 用途 | SELECT 体积 |
|---|---|---|
| 轻量 IDs | 只判断"是否存在"(isFavorited / hasItem) | ~80B/行 |
| 完整 WithContent | 真正渲染嵌套数据 | ~2KB+/行 |
| 单条 Detail | 详情面板单条查询(服务端 RLS 过滤) | ~300B |

mutation 策略:
- 高频 toggle 类:乐观双写 IDs + WithContent(后者仅当 cache 已存在),用真实 id swap temp_id,**不**调 invalidateQueries
- 低频用户主动 mutation:保留 invalidate WithContent 兜底
- 23505 路径(cache 与服务端不同步)必须回 lookup 拿真实 row

## 实测降幅参考

- **诊断**:pg_stat_statements 累计 5.8 天,useFavorites 嵌套 SELECT 占 PostgREST calls **76%**(14.7M / 19.3M)
- **方案**:三层拆分 + 5 个 mutation 双写 cache + 低频路径 invalidate 兜底
- **实测降幅**:25-37 GB/天 → **~4 GB/天(-85%)**

## 何时复用这套方法

- Supabase egress 突涨 + Dashboard 看不出具体来源 → 走 pg_stat queryid 聚类
- 不要假设 staleTime / refetchOnWindowFocus 是问题源 — 检查全局配置先
