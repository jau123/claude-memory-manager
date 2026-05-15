---
name: supabase-from-deadlock
description: 浏览器端 supabase.from() mutation 在 tab 切换后死锁,必须用 fetch() 调 REST API
type: feedback
---

# Supabase SDK `.from()` 浏览器端 mutation 死锁

## 问题

浏览器端用 `supabase.from('table').update(...)` 等 mutation,在用户切换 tab 后 mutation 卡住不返回,UI 显示无限 loading,刷新页面才好。

## 根因

`@supabase/ssr` 0.9.0+ 内部用 Web Locks API 管理 session。SDK 调 mutation 前会先 `getSession()` 拿 token,getSession 需要 lock。tab 不可见时浏览器对 Web Locks 持锁策略变保守,锁等不到 → mutation hang。

[Bug 已知,issue #2013 OPEN](https://github.com/supabase/supabase-js/issues/2013)。

## How to apply

浏览器端 **mutation** 走 `fetch()` 直接调 Supabase REST API,绕开 SDK lock:

```ts
await fetch(`${SUPABASE_URL}/rest/v1/table`, {
  method: 'POST',
  headers: {
    'apikey': SUPABASE_ANON_KEY,
    'Authorization': `Bearer ${session.access_token}`,
    'Prefer': 'return=representation',
  },
  body: JSON.stringify(data),
})
```

Query(SELECT)可以继续用 SDK(只读没问题)。token 从 React state 取(`session.access_token`),401 时 `refreshSession()` 重试。

待 SDK #2013 修复进入稳定版后切回。
