---
name: current-focus
description: 项目当前进行中的工作 / 临时配置 / 等观察的 metric。每周更新或重大决策后更新。新 session Claude 加载时看到本文件知道"还有什么没收尾"
type: project
---

# 当前焦点(2026-05-15)

## 进行中

- **favorites egress 重构 5/14 部署**(commit ec56868)
  - 5/15 观察 24h 稳态,预期 -85%(25-37GB/天 → ~4GB/天)
  - 若过渡期回弹 > 15GB/天需复盘
  - 后续:监控月底 egress 总量

- **Supabase Spend Cap 临时 disabled**
  - 原因:5/14 已用 200GB/月,月底大概率超 250GB 触发只读
  - 6/1 billing reset 后重开
  - 监控:每周看 [usage page](https://app.supabase.com/org/_/usage)

## Backlog(本周晚些时候做)

- [ ] CLAUDE.md 砍 < 200 行(当前 476 行)
- [ ] anti-abuse hub memory 建立(9 个反滥用文件聚合入口)

## Backlog(暂搁置)

- [ ] PreToolUse hook soft warning — 当前 baseline 93%+ 暂不必要
- [ ] 30 天未触的 18 个 memory review(audit 输出)

## 演进信号

本文件每次大决策后追加一段,旧段移到下方"## 历史"段保留。当前没有历史段(2026-05-15 是首版)。
