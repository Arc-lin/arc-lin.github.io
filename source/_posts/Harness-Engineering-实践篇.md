---
title: Harness Engineering 实践篇 — 手把手搭建你的第一个 AI Agent 脚手架
author: Arclin
tags:
  - AI Engineering
  - Harness Engineering
  - Agent
categories:
  - AI 工程
abbrlink: 21de888a
date: 2026-04-01 11:00:00
---

> **前置阅读**：建议先阅读[理论篇](/post/harness-engineering-theory.html)，理解 Harness 五大子系统。

<!--more-->

## 0. 前置准备

### 环境要求

- 一个 Git 仓库（任何项目均可）
- 已安装 Claude Code 或兼容的 AI Agent CLI
- 基本的 shell 脚本能力

### 最小 Harness：4 个文件

```
YOUR PROJECT ROOT
├── AGENTS.md              ← Agent 操作手册（指令层）
├── init.sh                ← 标准启动脚本（生命周期层）
├── feature_list.json      ← 功能清单（范围层 + 状态层）
└── claude-progress.md     ← 会话进度日志（状态层）
```

这四个文件是 Harness 的最小可行单元（MVP），覆盖了五大子系统中的四个（验证层通过 init.sh 中的测试命令实现）。

---

## 1. 核心文件详解与模板

### 1.1 AGENTS.md —— Agent 的工作手册

这是 Agent 每次会话读取的第一个文件，决定了它如何工作。

**设计原则**：短小精悍（2页以内），包含不可违反的核心规则（3-5条），通过路由表指向专项文档。

**最小版本模板**：

```markdown
# AGENTS.md

## 启动流程（每次会话必须执行）
1. 读取本文件，了解工作规则
2. 运行 `./init.sh`，验证环境正常
3. 读取 `claude-progress.md`，了解历史进展
4. 读取 `feature_list.json`，了解功能状态
5. 检查 `git log --oneline -10`，了解最近变更

## 核心规则（不可违反）
1. **一次只做一个功能**，从 feature_list.json 中选择优先级最高的 not_started 功能
2. **功能必须经过验证才能标记为 passing**，不得仅凭"代码写完了"就标记完成
3. **每次会话结束时必须更新** claude-progress.md 和 feature_list.json
4. **不得修改已标记为 passing 的功能**，除非明确被指派修复

## 验证命令
npm test           # 运行单元测试
npm run check      # 类型检查
npm run dev        # 启动应用（冒烟测试）

## 会话结束检查清单
- [ ] claude-progress.md 已更新
- [ ] feature_list.json 反映真实状态
- [ ] 所有变更已 git commit
- [ ] 下一步行动已记录
```

### 1.2 init.sh —— 标准启动脚本

**作用**：确保每次会话开始时，环境处于可工作的已知状态。

```bash
#!/usr/bin/env bash
set -euo pipefail

echo "=== Harness Init ==="
echo "[1/3] 安装依赖..."
npm install

echo "[2/3] 运行基线验证..."
npm run check && npm test

echo "[3/3] 环境就绪。"
echo "运行 npm run dev 以启动应用。"
```

**设计要点**：
- `set -euo pipefail`：任何步骤失败立即退出，不静默吞掉错误
- 验证步骤失败 = 环境不健康 = Agent 应停止工作并报告问题，而非继续往下走
- 脚本本身就是"环境健康"的可执行定义

### 1.3 feature_list.json —— 功能清单

这是整个 Harness 中最关键的状态文件，定义了"什么是工作，工作到什么程度算完成"。

```json
{
  "rules": {
    "single_active_feature": true,
    "passing_requires_evidence": true,
    "do_not_skip_verification": true
  },
  "status_legend": {
    "not_started": "尚未开始",
    "in_progress": "当前会话正在处理（同时只能有一个）",
    "blocked": "有阻塞项，记录在 notes 中",
    "passing": "已通过验证，有证据记录"
  },
  "features": [
    {
      "id": "F001",
      "priority": 1,
      "area": "core",
      "title": "用户登录功能",
      "user_visible_behavior": "用户可以输入用户名和密码登录，登录失败时显示错误提示",
      "status": "not_started",
      "verification": [
        "npm test -- --testPathPattern=auth 通过",
        "手动登录成功后跳转到主页",
        "密码错误时显示用户名或密码错误"
      ],
      "evidence": [],
      "notes": ""
    }
  ]
}
```

| 字段 | 含义 | 重要性 |
|------|------|--------|
| `user_visible_behavior` | 从用户角度描述功能，而非技术实现 | 高：防止 Agent 过度工程化 |
| `verification` | 验证步骤清单（必须可执行）| 高：定义完成标准 |
| `evidence` | 验证通过的证据（测试输出、日志等）| 高：防止自我宣告完成 |
| `status` | 当前状态，只能由验证结果驱动 | 高：是状态层的核心 |

### 1.4 claude-progress.md —— 会话进度日志

```markdown
# Claude Progress Log

## 会话记录（最新在前）

### [2026-04-01] 会话摘要
**已完成**：实现了 F001（用户登录功能），测试通过，有证据记录
**本次变更**：新增 src/auth/login.ts，修改 src/routes/index.ts
**已知问题**：F002（用户注册）尚未开始
**下一步**：继续 F002（用户注册）
```

---

## 2. 功能清单的设计哲学

### 2.1 "用户可见行为"原则

每个功能的描述应从**用户角度**出发：

```
❌ 错误：技术描述
"title": "实现 JWT 认证中间件"

✓ 正确：用户行为描述
"user_visible_behavior": "用户输入邮箱密码后可以登录，会话持续24小时"
```

这样做的原因：防止 Agent 过度工程化（实现了技术但忽略了用户体验）；验证步骤自然地变成"用户能做到 X 吗？"。

### 2.2 验证的三个层次

```
Level 1: 自动化验证（最快）
  单元测试：npm test
  类型检查：tsc --noEmit
  Lint：eslint src/

Level 2: 集成验证（中速）
  API 端到端测试
  数据库集成测试

Level 3: 行为验证（最可靠）
  Smoke test：关键路径手动走一遍
  E2E 测试：Playwright 浏览器自动化
```

最小 Harness 至少需要 Level 1，理想情况包含 Level 3。

---

## 3. Session Handoff：跨会话连续性

`claude-progress.md` 记录"发生了什么"，`session-handoff.md` 则回答"下一步怎么做"。前者是历史，后者是指导。

### session-handoff.md 模板

```markdown
# Session Handoff — 2026-04-01

## 当前可用（Verified Now）
- 用户登录功能（F001）可用：npm test 通过，手动验证通过
- 基础路由框架正常

## 本次变更（Changed This Session）
- 新增 src/auth/login.ts（JWT 认证逻辑）
- 修改 package.json 添加 jsonwebtoken 依赖

## 已知损坏或未验证（Broken Or Unverified）
- src/auth/refresh.ts 已创建但未测试（占位符代码）

## 下一步最佳行动（Next Best Step）
- 开始 F002（用户注册功能）

## 关键命令（Commands）
./init.sh       # 环境验证
npm run dev     # 启动应用（localhost:3000）
npm test        # 运行所有测试
```

### clean-state checklist

每次会话结束前必须通过以下检查：

- [ ] 标准启动路径仍然有效（./init.sh 可以成功运行）
- [ ] 标准验证路径仍然运行（npm test 通过）
- [ ] 当前进度已记录在 claude-progress.md
- [ ] feature_list.json 反映真实通过状态（非未验证的乐观状态）
- [ ] 没有未记录的半完成步骤
- [ ] 已知问题已在 session-handoff.md 中列出
- [ ] 下一次会话无需手动修复即可继续

---

## 4. 验证闭环：防止"自我宣告完成"

### 4.1 evaluator-rubric.md：质量评估量表

| 评估维度 | 检查问题 | 评分（0-2）|
|---------|---------|-----------|
| 正确性（Correctness） | 实现行为是否匹配需求描述？ | |
| 验证充分性（Verification） | 验证是否实际运行并有输出证据？ | |
| 范围纪律（Scope Discipline） | 会话是否保持在一个功能范围内？ | |
| 可靠性（Reliability） | 结果能否在重启后无需修复而存活？ | |
| 可维护性（Maintainability） | 代码和文档是否清晰？ | |
| 交接就绪（Handoff Readiness） | 全新会话能否仅从仓库文件继续工作？ | |

### 4.2 Generator-Evaluator 分离架构（进阶）

来自 Anthropic 的核心创新——将"做工作的 Agent"与"判断工作的 Agent"分离：

```
[Generator] → 实现代码
    ↓
[Evaluator] 用 Playwright 真实点击应用，发现 bug
    ↓ 具体 bug 报告
[Generator] 修复，再次提交评估
    ↑_______↑ 迭代直到所有标准通过
```

在 Anthropic 的实验中，评估 Agent 在第一轮就发现了诸如"点击保存按钮无反应"、"API 返回 undefined"等真实 bug，而这些在代码审查中很容易被遗漏。

---

## 5. 可观测性：让 Agent 能看到自己在做什么

**如果 Agent 看不到运行时反馈，它只能靠猜。**

### 5.1 可观测性配置建议

**结构化日志**（方便 Agent 解析）：

```typescript
// 推荐：结构化日志
console.log(JSON.stringify({
  level: "info",
  event: "user_login",
  userId: user.id,
  timestamp: new Date().toISOString()
}));
```

**在 AGENTS.md 中列出 Agent 可用的调试命令**：

```bash
tail -f logs/app.log                          # 查看应用日志
grep -i "error" logs/app.log | tail -20       # 查看最近错误
npm test -- --testPathPattern=auth --verbose  # 运行单个测试（调试）
```

### 5.2 OpenAI 的高级可观测性实践

OpenAI 团队将 Chrome DevTools 协议接入 Agent 运行时，让 Agent 能够：
- 通过 DOM 快照和截图直接推理 UI 行为
- 复现 bug、验证修复
- 使用 LogQL 查询日志，PromQL 查询指标

每个 Codex 任务都在独立的 git worktree 上运行，任务完成后连同所有日志、指标一起清理，保持环境隔离。

---

## 6. 分层领域架构（进阶）

### 何时需要进阶 Harness？

触发信号：AGENTS.md 超过 3 页、不同领域的规则相互干扰、Agent 经常因为"不知道这里的规范"而犯错。

### 高级版 AGENTS.md 路由设计

```markdown
## 路由地图（Routing Map）

| 任务类型 | 参考文档 |
|---------|---------|
| 理解整体架构 | ARCHITECTURE.md |
| 提交代码或创建 PR | docs/QUALITY_SCORE.md |
| 处理 Secret 或外部 API | docs/SECURITY.md |
| 修改前端组件 | docs/FRONTEND.md |
| 查看或创建执行计划 | docs/PLANS.md |
| 了解系统健康标准 | docs/RELIABILITY.md |
```

### OpenAI 的分层架构实践

每个业务域强制执行依赖方向（只能"向前"）：

```
Types → Config → Repo → Service → Runtime → UI
横切关注点只能通过单一接口 Providers 进入
```

通过自定义 Linter 机械强制执行，Lint 错误消息中直接包含修复指令，让 Agent 在违规时立即知道如何修复。

---

## 7. 渐进式实战路径

基于 [walkinglabs/learn-harness-engineering](https://github.com/walkinglabs/learn-harness-engineering) 课程体系：

| 阶段 | 训练重点 | 目标 |
|------|---------|------|
| P01：最小 Harness | AGENTS.md + init.sh + feature_list.json（4 文件）| 理解有无 Harness 的结果差异 |
| P02：Agent 可读工作区 | 持久化状态文件 + 仓库即事实来源 | 跨会话不丢失上下文 |
| P03：多会话连续性 | progress log + session handoff | 新会话 3 分钟内恢复工作上下文 |
| P04：增量开发 + 运行时反馈 | Scope 控制 + 可观测性基础 | 每次会话产出可用增量 |
| P05：基于证据的验证 | evaluator-rubric + E2E 测试 | 消除"自我宣告完成"问题 |
| P06：完整 Harness（毕业项目）| 所有机制 + 分层架构 + 消融实验 | 生产级 Harness |

**消融实验**（P06 核心练习）：故意移除 Harness 的某个组件，观察 Agent 行为如何降级。这是验证你是否真正理解每个组件价值的最佳方法。

---

## 8. 常见反模式与规避

| 反模式 | 表现 | 解决方案 |
|--------|------|---------|
| 巨型 AGENTS.md | 单文件超过 500 行 | 分层文档路由 |
| 乐观状态 | 功能标记 passing 但实际未验证 | `passing_requires_evidence: true` 规则 |
| 范围蔓延 | 一次会话修改了多个功能区域 | `single_active_feature: true` 规则 |
| 脆弱的 init.sh | 部分步骤失败但脚本继续执行 | `set -euo pipefail` |
| 空的 evidence | evidence 字段为空就标 passing | Evaluator 检查，空 evidence 不得标记 |
| 遗忘的交接 | 会话结束后 session-handoff.md 未更新 | clean-state checklist 强制检查 |
| 外部状态依赖 | 关键信息只存在于 Jira/Notion | 将所有 Agent 需要的信息编码进仓库 |

---

## 总结

Harness Engineering 的价值不在于某一个文件或技巧，而在于将这些机制**系统性地组合**，构建一个让 AI Agent 能够可靠、持续地完成真实工程任务的环境。

> **搭建 Harness 的成本，远低于不搭 Harness 的失败成本。**

---

**参考资料**
- [walkinglabs/learn-harness-engineering](https://github.com/walkinglabs/learn-harness-engineering)
- [OpenAI: 工程技术——在智能体优先的世界中利用 Codex](https://openai.com/zh-Hans-CN/index/harness-engineering/)
- [Anthropic: Harness design for long-running application development](https://www.anthropic.com/engineering/harness-design-long-running-apps)
