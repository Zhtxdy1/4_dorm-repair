# 宿舍维修系统（V5.0）

> 项目阶段：**启动 / 开发中**。本文件描述目标与计划，完成状态以后续提交为准。

一个打算自己跑完的宿舍报修闭环：学生拍照提交 → 系统定级派工 → 师傅进楼维修 → 学生验收 → 归档。
目标不是"做得像大厂系统"，而是**证明正常维修链不需要人催、返修必须人工审查、每步都留痕**。

---

## 计划做什么

| 里程碑 | 内容 | 状态 |
|---|---|---|
| M1 | Spring Boot 骨架 + 状态机内核 + 一条链跑通 | 计划中 |
| M2 | MySQL 8 + MyBatis-Plus，三端人员分表与迁移版本管理 | 计划中 |
| M3 | Python AI 定级服务，规则闸门与模型兜底 | 计划中 |
| M4 | 学生、师傅、管理端三个独立 Vue 应用 | 计划中 |
| M5 | Bearer Token、返修审查、真实文件、幂等与生产运维配置 | 计划中 |

**计划中的界面入口**（服务起来后访问）：

- 学生端 `http://localhost:5173/`、师傅端 `http://localhost:5174/`、管理端 `http://localhost:5175/`
- 原型（离线、零依赖、假数据）：`prototype/index.html`，作为视觉与交互定稿依据

---

## 怎么跑起来（开发中）

最终形态是五个进程：AI（Python 8001）、后端（Java 8082）、学生端（5173）、师傅端（5174）、管理端（5175）；三个前端均将 `/api` 代理到 8082。

**Windows：双击 `start.bat`**，会启动 AI 与后端；三个前端另开终端执行 `npm run dev`。

```powershell
# 1 AI 定级服务（M3 完成后）
cd app\ai
python -m uvicorn app:app --host 127.0.0.1 --port 8001

# 2 后端（先建库，见下一节）
cd app\server
mvn -q -DskipTests package
java -jar target\dorm-repair-server-1.0.0.jar
```

| 想改什么 | 怎么改 |
|---|---|
| 端口 | `server.port`（后端 8082）、`--port`（AI 8001）、`PORT`（前端） |
| 数据库 | 环境变量 `DB_HOST` / `DB_PORT` / `DB_NAME` / `DB_USER` / `DB_PASSWORD` |
| 存储换内存 | `APP_STORE=memory`（仅用于开发与单测，重启就没了） |
| AI 不在本机 | `AI_SERVICE_URL`（默认 `http://127.0.0.1:8001`）、`AI_TIMEOUT_MS`、`AI_REVIEW_TIMEOUT_MS` |

### 建库（M2 完成后执行，只需一次）

```powershell
$tmp = Join-Path $env:TEMP 'dormdb'; New-Item -ItemType Directory -Force $tmp | Out-Null
Copy-Item app\server\src\main\resources\db\schema.sql $tmp
Copy-Item app\server\src\main\resources\db\data.sql  $tmp
& 'C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe' -uroot -p123456 --default-character-set=utf8mb4 -e "source $tmp/schema.sql"
& 'C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe' -uroot -p123456 --default-character-set=utf8mb4 -e "source $tmp/data.sql"
```

> `source` 打不开中文路径，所以先复制到 `%TEMP%` 再 source。

### 前端（M4 完成后）

首次各自执行 `npm install`，然后 `npm run dev`（端口 5173 / 5174 / 5175）。

---

## 怎么验证

| 要证明的事 | 计划中的命令 | 期望 |
|---|---|---|
| 状态机与业务闭环回归 | `cd app\server; mvn -q test` | 全绿 |
| 一条链真跑通 | `pwsh -NoProfile -File app\server\tests\m1-chain.ps1` | 全部通过 |
| 数据真落 MySQL | `pwsh -NoProfile -File app\server\tests\m2-mysql.ps1` | 全部通过 |
| AI 挂了仍可建单 | `pwsh -NoProfile -File app\server\tests\m3-ai.ps1` | 全部通过 |
| 返修审查链 | `pwsh -NoProfile -File app\server\tests\m4-rework.ps1` | 全部通过 |
| 真 Bearer Token 与权限 | `pwsh -NoProfile -File app\server\tests\m5-auth.ps1` | 全部通过 |
| AI 规则与分类器 | `cd app\ai; python -m pytest -q` | 全绿 |
| 前端状态词与进度 | `cd app\web; npm run test:unit` | 全绿 |
| 原型状态机自检 | `node prototype/tests/selftest.js prototype` | 全部通过 |

看接口而不是跑脚本（实现后）：

- `GET /api/v1/state/matrix` —— 哪些状态转移合法
- `GET /api/v1/ai/health` —— AI 服务、LLM 模式与模型匹配状态
- `POST /api/v1/orders` + `POST /api/v1/orders/{no}/finish` —— 故意用错状态，看是否 409 且列出 `allowed`

---

## 目录（规划）

```
宿舍维修系统\
├─ README.md                     本文件
├─ start.bat                     双击起 AI + 后端
├─ docs\                         文档（只放文档）
│  ├─ README.md                  文档索引
│  ├─ 01_需求\                   需求报告 / 闭环大纲 / 口径统一说明
│  ├─ 02_流程与状态\             流程图、状态机图（html 看细节，png 贴 PPT）
│  ├─ 03_系统设计\               接口契约与系统设计说明书
│  └─ 04_项目管理\               开发计划 / 评审 / 答辩脚本
├─ prototype\                    ★ 原型（离线可跑，假数据，只当视觉与交互标准）
├─ app\                          ★ 正式项目
│  ├─ server\                    Spring Boot 4 + MyBatis-Plus + MySQL
│  ├─ ai\                        Python + FastAPI 定级服务
│  ├─ student-web\               学生独立应用 :5173
│  ├─ worker-web\                师傅独立应用 :5174
│  ├─ admin-web\                 管理端独立应用 :5175
│  └─ web\packages\contract\     只读共享契约
└─ deploy\                       容器化与运维配置
```

---

## 三端各跑在哪（别搞错）

| 端点 | 设备 | 谁用 | 在哪儿用 |
|---|---|---|---|
| 学生端 | **手机**（430 宽竖屏） | 报修的学生 | 宿舍里、走廊上，扫码就进 |
| 师傅端 | **手机**（430 宽竖屏） | 跑楼的维修师傅 | 站着、走着、在门口，一只手操作 |
| 管理端 | **电脑**（桌面 1440） | 后勤维修部的督察/主任 | 办公室，看台账和例外 |

学生端和师傅端固定 430 宽、底部浮动导航、按钮大一号；管理端是左侧深色导航 + 密集表格 + 鼠标 hover，**不要做成手机壳**。

---

## 三条铁律

1. **`prototype/` 只读物证。** 原型零依赖可双击跑，新功能只进 `app/`，不许把原型的逻辑复制过去。
2. **原型用假数据，`app/` 用真数据库，两者不混。**
3. **文档只放 `docs/`，代码只放 `prototype/` 和 `app/`。** 交作业时能单独打包。

---

## 口径标准

工单怎么流转，冲突时按这个顺序取：

1. `SYS-004 状态机设计`（外部标准，优先级最高）
2. `REQ-002 闭环大纲 xmind`（业务闭环）
3. `SYS-003 接口契约` / 状态机图 / 流程图（图可能有笔误，不是源头）

计划实现：`status` 只能由 `OrderStateService.transit()` 改，service 里不出现 `setStatus(...)`；合法转移只在 `TransitionTable.java` 定义。

---

## 明确边界（当前阶段）

- 本地开发优先，生产试点、目标环境容量、持续压测尚未开展；
- 真实模型、真实上传、生产桶与告警接收器都对接好之后再宣称生产就绪；
- 多楼栋组织树首版只做 B7/B8 两栋样本。

---

## 许可证

MIT License，见 [LICENSE](LICENSE)。
