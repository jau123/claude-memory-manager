---
name: memory-management
description: Guide Claude Code memory and CLAUDE.md management — what to record, how to write, when to update vs create new, and how to organize. Use when user asks to "记一下"、"新增记忆"、"更新记忆"、"沉淀本次经验"、"看看本次有什么值得记的"、"改 schema"、"加新 type"、"改记忆结构"、"review memory"、"audit memory"、"复盘"、"开发完了"、"总结一下" or discusses memory system design / CLAUDE.md 管理 / memory schema / memory hub / 防记忆系统漂移. Also use after feature work / debug / 对抗审查 when new insights worth recording.
---

# Memory Management

How to write into Claude Code's auto-memory and CLAUDE.md so the library stays searchable as the project grows.

## Quick Reference

| User says... | Do this |
|---|---|
| "记一下"(模糊,多条候选)/"复盘"/"开发完了看有什么值得记的" | → **Mode 1:候选评估**(多候选筛选) |
| "记一下今天那个 X 坑"(具体单条)/ 重大 bug 修完后 / 安全事件处置完 / 单次决策有非显然结论 | → **Mode 2:新建 memory**(直接走) |
| "更新这个 memory / 修正 X 的结论" | → **Mode 3:update 已有 memory**(优先于新建) |
| 待加段超过 100 行或文件已 > 4 个 H2 主题 | → **Rule 6:拆分而非 update** |
| "改 schema / 加新 type / 改记忆结构" | → **Mode 4:结构性变更**(必读已踩坑清单) |
| "新项目零记忆起步" / "怎么开始" | → **Mode 5:零记忆 bootstrap** |
| "记忆系统看起来乱了 / audit" | → 项目根有 `scripts/audit-memory.sh` 则跑;无则参考 `templates/audit-memory.template.sh` 自建 |

## Important Rules

### Rule 1:事实进 memory,方法进 skill

memory file 装"踩过 X 坑"、"业界 Y 数据"、"项目 Z 状态";本 skill 装"如何决定记什么 / 怎么写 / 怎么组织"。不要把 schema 规范写到 memory 里(类别错误)。

### Rule 2:**先判断"是否值得记",再判断"记到哪"**

不是每个发现都该记。决策树:

| 信号 | 该记吗 |
|---|---|
| 同样的坑踩了第 2 次 | ✅ 必记 |
| 对抗审查发现非显然的判断 | ✅ 记决策的"Why" |
| 业界对照 / 实测数字(可复用基线) | ✅ 记 |
| 一次性 debug 已修完无沉淀价值 | ❌ 不记(commit message 就够) |
| 临时状态会变化 | ⚠️ 看持续性,长期才记 |

### Rule 3:**优先 update 已有,不新建**

主题相关已有 file → update 该 file(加段或加 changelog 段)。**主题完全正交才新建**。新建会导致主题碎片化 → 找东西难 → 失忆。

### Rule 4:**memory 不自动加载,description 决定命中**

topic file(memory/*.md)session 启动**不加载**,Claude 凭 MEMORY.md 索引里的 description 判断是否读。**description 必须场景关键词 + 核心结论混合**,否则 Claude 会凭印象决定读哪个。

### Rule 5:**skill 自身要符合 skill 教的规范**

如果本 skill 让用户写 `## Why` 段,本 skill 也应该解释自己每条规则的 Why(它们都在本文件 inline)。

**Scope 注意**:Rule 5 适用范围是"方法/写法/Quick Reference 形式等",**不递归适用 schema 规则**。Schema(命名/frontmatter/Why 段)是给 memory 文件的,不适用 skill 自身。Skill 不是 memory file。

### Rule 6:**何时拆分而非 update**(防止单文件 / 单组超载)

Rule 3 优先 update,但有阈值。**触发拆分的信号**(单文件层):

| 信号 | 行动 |
|---|---|
| 已有 file > 100 行,且要加的新内容跟原主题正交 | 拆出新 file,不要塞 |
| 已有 file 已 ≥ 4 个 H2 顶层段,且新内容属于第 5 个独立主题 | 拆出新 file |
| 加段后总长度跨过 150 行 | 评估是否拆(看主题独立性) |
| 加的内容跟原 file 标题/description 不匹配 | 拆出新 file(原 file 应该专注其声明的主题) |

**单组超载**(索引层):

| 信号 | 行动 |
|---|---|
| MEMORY.md 某大组 entry 数 ≥ 15 | 考虑建 **hub memory**(段索引)替代扁平索引,新 entry 挂 hub |
| 一个组的 description 加起来扫一遍 > 25 行 | 同上 |

**为什么单组超载也要管**:Claude 凭 MEMORY.md 索引扫 description 命中,组内 20+ 条 description 凭一次扫描有遗漏率。建 hub 后,组索引只一行指向 hub,hub 内做主题地图。

#### 历史踩坑案例(reference,非规则的一部分)

- **单文件超载**:一个 reference 文件长到 130+ 行,塞了 7-8 个独立子主题(基础设施、cron 列表、故障手册等),MEMORY.md 索引描述概括不全,Claude 命中不了具体子主题。拆成 5 个独立 memory 后每个主题精准命中。
- **单组超载**:某分组累积 20+ 条 entry,新 session Claude 扫索引时有遗漏,处理任务时重复造轮子。建一个 hub memory 聚合相关入口 → 解决。

---

## Workflow Modes

### Mode 1:候选评估(多候选,需要筛选)

**触发场景**(多条候选 → 需要 Mode 1 筛选):
- 功能开发完 / 长 debug 完 / 对抗审查完
- 反滥用处置完(可能多个判断点 + 教训)
- 安全事件处置完 / 故障定位完
- 用户说 "记一下"(模糊,未指明具体哪个坑)

**单条具体内容直接走 Mode 2**:用户说 "记一下今天那个 wildcard bug" / "记一下连接泄漏的故障手册" → 已经明确单条 → Mode 2 不要 Mode 1。

**步骤**:

1. **回顾本次会话关键节点**(用户校正、对抗审查发现、未预期 bug、业界对照查询、单次决策的非显然结论)
2. **逐个套 Rule 2 决策树**,筛出值得记的
3. **对每个候选**,判断:
   - 是否已有 memory 文件覆盖?(grep MEMORY.md 索引)→ 有则走 Mode 3 update,无则走 Mode 2 新建
   - 待加的内容是否超 Rule 6 拆分触发线?→ 拆出新 file
   - 是否应该进 CLAUDE.md 而非 memory?(见下方表格)
4. **跟用户确认清单**:列出"建议新增 / 建议 update / 建议拆分"候选,等用户确认再写

**memory vs CLAUDE.md 边界**:

| 内容性质 | 放哪 |
|---|---|
| 学到的具体踩坑(SDK bug、平台限制、业界数据) | memory `feedback_*` |
| 主题深度参考 / 标准方法 / 流程文档 | memory `reference_*` |
| 状态性事实(进行中工作、临时配置、当前架构快照) | memory `project_*` |
| **每次 session 都要遵守的规则**(命令、技术栈、协作偏好) | CLAUDE.md |
| **特定文件操作时才需要的规则** | `.claude/rules/*.md` 加 paths frontmatter |

---

### Mode 2:新建 memory(标准流程)

#### 步骤 1:确定 type

| Type | 何时用 | 必含信息 |
|---|---|---|
| **feedback** | 学到的踩坑(SDK bug / 平台限制 / 用户偏好) | **原因**(为什么这个结论)+ **何时复用**(触发场景) |
| **reference** | 主题深度参考 / 标准方法 / 业界对照 / 复用 pipeline | 不强制原因段(描述性) |
| **project** | 状态性事实(架构快照、进行中工作、经济学分析) | 不强制原因段(状态性) |

**feedback 必含信息的呈现形式**(任一即可):
- 单独段:`## Why` 或同义中文 `## 根因` / `## 原因` / `## 教训` / `## 为什么`(audit 都接受)
- 加粗行内:`**Why**:` / `**根因**:` (短结论也可)
- **inline 在 description** 或 ## 标题里(如果结论本身已经隐含原因 + 何时复用,如对比 ❌/✅ 表格)

**何时复用信息**:可以是单独 `## How to apply` 段,**也可以是 description 含场景关键词**(如 `tab 切换 / mutation` 已经暗示触发场景)。

#### 步骤 2:文件命名

`<type>_<topic>[_<modifier>].md` 全小写下划线:
- ✅ `feedback_supabase_from_deadlock.md`
- ✅ `reference_supabase_egress_favorites_refactor.md`
- ❌ `feedback-supabase-deadlock.md`(用了连字符)
- ❌ `FeedbackSupabaseDeadlock.md`(驼峰)
- ❌ `_schema.md`(下划线开头会被当隐藏文件,且 Claude 不会主动读)

#### 步骤 3:写 frontmatter

```yaml
---
name: kebab-case-slug
description: 场景关键词 + 核心结论
type: feedback | reference | project       # 平铺(推荐)
# 或:
# metadata:
#   type: feedback | reference | project   # 嵌套(兼容写法)
---
```

**`type` 字段位置**:`type:` 平铺(推荐)或 `metadata.type:` 嵌套都接受。audit 脚本两种都识别。新建文件优先用平铺,跟现有多数对齐。

**description 风格判定**:

| ✅ 好 description | ❌ 坏 description |
|---|---|
| `浏览器端 supabase.from() mutation 在 tab 切换后死锁,必须用 fetch() 调 REST API` | `Supabase 相关问题` |
| `CF Image Transformations 失败 7 天缓存 / cf-resized err= / FavoriteCard retry pattern` | `图片有时显示不出来` |
| `RLS 策略必须用 (SELECT auth.uid()) 包装,否则每行重复求值` | `RLS 性能优化` |

判定标准:Claude 读 description 时能不能立刻知道"这是 X 场景下要查的 Y 结论"。

#### 步骤 4:写正文

**feedback 类(必含原因 + 何时复用)**:

```markdown
# 标题(What — 一句话)

[核心结论 + 1-2 段背景]

## Why(或同义:## 根因 / ## 原因 / ## 教训 / ## 为什么)

[为什么是这个结论 — 踩过的具体坑、对抗审查发现、用户偏好]
**为什么必填**:没有原因段,下次重新讨论同一决策时往往会得出同一个错误结论。

## How to apply(可省略,如 description 已含场景关键词)

[何时复用这条 — 触发场景、检查清单、避坑步骤]
```

**reference / project 类**:不强制段结构,按主题自然组织即可。

#### 步骤 5:加到 MEMORY.md 索引

- 选**已有大组**,不新建分组
- description 加到组内对应位置(高重要性用 ⭐⭐ / ⭐⭐⭐ 加粗)
- 跨主题:description 末尾加 `(亦见 [[other-file]])`

---

### Mode 3:Update 已有 memory(优先于新建)

#### 步骤 1:用 grep 确认现有主题归属

```bash
grep -l "<关键词>" memory/*.md
```

#### 步骤 2:决定 update 方式

| 情况 | 怎么 update |
|---|---|
| 新数据 / 新案例补充已有结论 | 在正文加段或 changelog 段 |
| 已有结论被推翻 | 旧文件顶部加 `⚠️ Superseded by [[new-file-slug]]`,新文件正文写"取代 [[old]] 的什么部分" |
| 只是 description 描述不够清楚 | 改 MEMORY.md 索引,不改 file 本身(除非也加内容) |

#### 步骤 3:同步 MEMORY.md

如果改了 description,MEMORY.md 对应行也要改。

---

### Mode 4:结构性变更(改 schema / 加新 type / 改分组)

**必读已踩过的坑清单**:

- [ ] 不要尝试 hook `if: "Write(memory/*.md)"` glob 语法 — `if:` 是 permission rule 不是 file glob,已验证无效
- [ ] 不要用 exit 2 阻塞 hook — 已验证破坏 pre-deploy batch 流(Claude 没有自动重试机制)
- [ ] 不要把 schema 权威源放 `_schema.md` 类下划线开头文件 — Claude 不主动读 topic file
- [ ] 不要在项目 `.claude/settings.json` 配 hook — 该目录通常在 `.gitignore` 里,不进 git 不跨 worktree
- [ ] 加新必填字段时同步 3 处:(a) 本 skill 段 "Mode 2 → 步骤 3" (b) MEMORY.md 顶部速查精华段 (c) audit-memory.sh 脚本字段列表
- [ ] 修 hook / 加约束前先 `bash scripts/audit-memory.sh` 看当前合规率 — <95% 才需要硬措施,≥95% 维持 soft warning

**改 schema 流程**:
1. 跑 audit 拿当前基线
2. 设计变更(改本 skill + 项目 hub)
3. 验证现有 memory 是否大批违反新规(>10% → 暂缓,先按新规迁移)
4. 更新 MEMORY.md 精华段同步
5. 改 audit 脚本字段列表
6. 复跑 audit 看新合规率

---

### Mode 5:零记忆 bootstrap(新项目)

当用户在一个**没有 memory 系统**的项目说"开始建记忆":

#### 步骤 1:确认 auto memory 目录路径

Claude Code 自动建 `~/.claude/projects/<project-slug>/memory/`,其中 `<project-slug>` = 项目绝对路径将 `/` 替换为 `-`。例:
- 项目 `/Users/alice/Project/myapp` → slug `-Users-alice-Project-myapp`

如果 Claude Code 已经为该项目自动创建过 auto memory,目录会存在。验证:`ls ~/.claude/projects/ | grep <项目名>`。

#### 步骤 2:建 MEMORY.md 索引

顶部模板(可压缩到 ~25 行):

```markdown
# <项目名> 项目记忆

## ⭐⭐⭐ 写 memory 速查(硬规则)
- 文件名:`<type>_<topic>.md` 全小写下划线;type ∈ {feedback, reference, project}
- 必填 frontmatter:name / description / type
- feedback 必须含 ## Why 段(或同义中文 ## 根因 / ## 教训 / ## 原因)
- description 风格:场景关键词 + 核心结论
- 同主题已有文件 → update,不新建(超 Rule 6 阈值则拆)
- 详细方法:memory-management skill

## ⭐ 项目主题列表
(暂无 — 后续按主题增加分组)
```

#### 步骤 3:**分组演进阈值**(按文件数决定结构)

| memory 文件数 | 推荐结构 |
|---|---|
| < 15 条 | flat list,无分组(单一列表足够,分组反而碎片化) |
| 15-25 条 | 引入 3-5 个大组(按主题聚合) |
| > 25 条 | 分组成熟,**冻结分组**禁止新建,新条目挂已有组(跨主题用 `(亦见 X)`) |

#### 步骤 4:CLAUDE.md 顶部加 Memory 协议(3-5 行)

```markdown
## Memory 管理
涉及 memory 写入 / 更新 / schema 调整时 → 使用 `memory-management` skill。
- 速查规则:MEMORY.md 顶部 ⭐⭐⭐ 段
- 体检合规率:`bash scripts/audit-memory.sh`(可选,见 skill templates/)
```

#### 步骤 5:复用本 skill 通用方法

**不要把 skill 内容复制到项目**。skill 在用户级,所有项目共用一份方法。项目里只放项目特定状态(分组列表 / 待办 / 项目特有踩坑)。

---

## Schema 规范(权威源)

### 文件命名

`<type>_<topic>[_<modifier>].md` 全小写下划线,type ∈ {feedback, reference, project}

### 必填 frontmatter

```yaml
---
name: kebab-case-slug
description: 场景关键词 + 核心结论
type: feedback | reference | project       # 平铺(推荐)
# 或:
# metadata:
#   type: feedback | reference | project   # 嵌套(兼容)
---
```

audit 脚本两种都识别。新建文件优先平铺。

### feedback 必含信息

**原因段**(任一):
- `## Why` 或同义中文标题 `## 根因` / `## 教训` / `## 原因` / `## 为什么` / `## Root cause`(可带英文 `:` 或中文 `:`)
- 加粗行内 `**Why**:` / `**Why**:` / `**根因**:` 等

**何时复用**(任一):
- 单独 `## How to apply` 段
- description 含场景关键词(隐含触发场景即可)

### description 风格

混合(场景关键词 + 核心结论),让 Claude 凭 description 命中"X 场景查 Y 结论"

### 分组冻结

从已有大组选,禁止新建分组。归属模糊用 `(亦见 hub-X)` 跨引用。

---

## Common Mistakes

| 错 | 对 |
|---|---|
| 凭印象写 description "Supabase 问题" | 写场景关键词 + 结论 "supabase.from() tab 切换死锁,用 fetch" |
| feedback 只写"是什么" | feedback 必带 ## Why,保护未来不重新质疑 |
| 同主题新建第二个文件 | 优先 update 已有,新建会碎片化 |
| 新建"网络问题"分组放 1 条 entry | 用已有分组,跨主题用 `(亦见 X)` |
| 把 schema 规范写到 memory file | schema 在本 skill,memory 装事实 |
| 用 hook exit 2 强制阻塞 | 用 soft warning(stderr + exit 0)或 audit 事后体检 |

---

## Self-Check(写完后)

- [ ] 类型对吗(feedback/reference/project)?
- [ ] 文件名符合 `<type>_<topic>.md` 全小写下划线?
- [ ] frontmatter 3 字段齐(name / description / type)?
- [ ] feedback 类有原因段(`## Why` 或同义中文 / 加粗行内)?
- [ ] description 含场景关键词 + 核心结论?
- [ ] 已加到 MEMORY.md 索引正确大组下?
- [ ] 没新建分组?(如果新建了,撤回放已有组)
- [ ] 跨主题加了 `(亦见 X)` 提示?
- [ ] **Rule 6 检查**:新 file < 100 行 + < 5 个 H2 段?(如果 update 已有 file 让它超阈值,改成拆出新 file)
- [ ] **触发力体检**:列 3 个未来可能问到的场景关键词,模拟问"Claude 凭 description 会读这个 memory 吗?"(如果想象不出场景,description 不合格)

---

## Tool Integration

audit 脚本是**可选**项目工具。

**项目根有 `scripts/audit-memory.sh`** → 跑:
```bash
bash scripts/audit-memory.sh  # 看合规率 / 列违规 / 列 30 天未触
```

输出:总文件数 / 缺 frontmatter / 缺 Why / MEMORY.md 断链 / 30 天未触 / 合规率%。
目标合规率 ≥ 95%。

**没有 audit 脚本** → 从模板自建:
```bash
# 用户级 skill 自带通用模板
cp ~/.claude/skills/memory-management/templates/audit-memory.template.sh \
   <你的项目>/scripts/audit-memory.sh
# 修改 MEMORY_DIR 指向你项目的 auto memory 目录
chmod +x <你的项目>/scripts/audit-memory.sh
bash <你的项目>/scripts/audit-memory.sh
```

参考默认 auto memory 路径:`~/.claude/projects/<project-slug>/memory/`,见 Mode 5 步骤 1。

