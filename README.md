# WMS — 工资管理系统 (Wage Management System)

基于 MySQL 9.3 实现的工资管理系统后端，全部业务逻辑通过存储过程、触发器、函数和事件在数据库端完成。

## 技术栈

| 层级 | 技术 |
|---|---|
| 数据库 | MySQL 9.3 Community Server (InnoDB) |
| 字符集 | utf8mb4 / utf8mb4_unicode_ci |
| 脚本 | SQL (DDL / DML / 存储过程 / 触发器 / 函数 / 事件) |
| 建模工具 | PDManer (ER 图) |
| 开发工具 | Navicat Premium 17 |

## 项目结构

```
WMS/
├── create_table.sql          # 数据库及 15 张表 DDL
├── create_functions          # 4 个函数
├── create_view               # 8 个视图
├── create_procedure          # 9 个存储过程
├── create_trigger            # 6 个触发器
├── create_event              # 1 个定时事件
├── generate_500_emp_data     # 测试数据生成（500 名员工）
├── demo_script               # 功能演示脚本
└── README.md
```

## 数据库架构

### 表结构（15 张）

**核心实体表：**

| 表名 | 说明 |
|---|---|
| `departments` | 部门表，自关联树形结构（总部 → 一级部门 → 分部） |
| `employees` | 员工表，含部门、职称、岗位、在职状态 |
| `titles` | 职称表，双序列（技术 1-6，管理 7-11） |
| `positions` | 岗位表，5 条职能线 × 3 个等级，共 16 个岗位 |
| `salary_categories` | 工资类别表，10 项（6 应发 + 4 应扣） |
| `seniority_rules` | 工龄规则表，支持多版本按生效日期匹配 |
| `sys_config` | 系统配置表（发薪日等） |

**关联/中间表：**

| 表名 | 说明 |
|---|---|
| `title_salary` | 职称-工资标准关联 |
| `position_salary` | 岗位-工资标准关联 |
| `emp_title_history` | 员工职称变更历史 |
| `emp_position_history` | 员工岗位变动历史 |

**业务数据表：**

| 表名 | 说明 |
|---|---|
| `attendance_records` | 考勤明细（请假/迟到/旷工/正常） |
| `monthly_salary_details` | 月度工资明细 |
| `monthly_salary_summary` | 月度工资总表 |
| `seniority_salary` | 工龄工资独立表 |

### 数据库对象

- **8 个视图** — 在职员工信息、部门信息、工资发放表（公司/部门/个人）、年度工资占比、部门工资统计、员工年度平均
- **9 个存储过程** — 工资初始化、计算汇总、审核锁定、解锁冲销、逻辑删除、个人查询、工龄计算、手动录入、考勤重算
- **6 个触发器** — 考勤变更自动重算、已发放月份修改拦截、职称/岗位变更履历追踪
- **4 个函数** — 发薪日读取、部门月均工资、员工年均工资、工龄规则匹配
- **1 个事件** — 每天凌晨 1:00 检查发薪日，自动初始化当月工资

## 快速开始

### 环境要求

- MySQL 8.0+

### 部署步骤

在 MySQL 中按顺序执行：

```sql
SOURCE create_table.sql;
SOURCE create_functions;
SOURCE create_view;
SOURCE create_procedure;
SOURCE create_trigger;
SOURCE create_event;
```

### 生成测试数据

```sql
SOURCE generate_500_emp_data;
```

将生成 500 名员工、约 15,500 条考勤记录和约 3,500 条工资明细。

### 运行演示

```sql
SOURCE demo_script;
```

## 核心业务规则

- **发薪日**：由 `sys_config` 表配置，函数动态读取，支持运行时切换
- **职称/岗位生效**：发薪日前变更当月生效，之后下月生效
- **工龄工资**：`base + 工龄年数 × add`，按生效日期区间自动匹配规则版本
- **考勤扣款**：请假 100 元/天、迟到早退 50 元/次、旷工 300 元/天、满勤奖 300 元
- **审核流程**：计算（待审核）→ 审核（已发放，锁定）→ 解锁 → 冲销修正 → 重算 → 重新审核
- **权限控制**：普通员工仅查本人工资；分部经理及以上可查本部门全员（个人置顶）

