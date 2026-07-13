-- Active: 1783518467638@@127.0.0.1@3306@wms

-- 单行注释 CTRL + /
/* 多行注释 CTRL + alt + a */
DROP DATABASE IF EXISTS WMS;
-- 建数据库
create database WMS ;

DROP TABLE IF EXISTS departments, employees,
 titles, positions, salary_categories, title_salary, 
 position_salary, seniority_rules, emp_title_history, 
 emp_position_history, attendance_records, 
 monthly_salary_details, monthly_salary_summary, 
 seniority_salary, sys_config;

show DATABASES;

use WMS;

-- 1.部门表{ 部门id，父部门id，部门经理id，部门等级id，部门名称}
DROP TABLE IF EXISTS departments;
CREATE TABLE departments(
    `dept_id` INT NOT NULL AUTO_INCREMENT COMMENT '部门id',
    `parent_dept_id` INT COMMENT '父部门id',
    `manager_emp_id` INT COMMENT '部门经理id',
    `dept_level` TINYINT NOT NULL COMMENT '部门等级id;部门层级:1 总部 / 2 一级部门 / 3 分部',
    `dept_name` VARCHAR(50) NOT NULL COMMENT '部门名称',
    PRIMARY KEY (`dept_id`)

) COMMENT '部门';

--给部门名称加unique约束，避免重复
Alter TABLE departments ADD CONSTRAINT uk_dept_name UNIQUE (`dept_name`);

CREATE INDEX `idx_parent_dept` ON departments (
    `parent_dept_id` ASC
)COMMENT '父部门索引';
CREATE INDEX `idx_manager` ON departments (
    `manager_emp_id` ASC
)COMMENT '经理索引';

-- 表创建完成后，再添加自关联父部门外键
ALTER TABLE departments
ADD CONSTRAINT fk_parent_dept
FOREIGN KEY (`parent_dept_id`) REFERENCES departments(`dept_id`)
ON DELETE SET NULL ON UPDATE CASCADE;

--员工表建立后，再添加外键 fk_dept_manager
ALTER TABLE departments ADD CONSTRAINT fk_dept_manager
FOREIGN KEY (`manager_emp_id`) REFERENCES employees(`emp_id`)
ON DELETE SET NULL ON UPDATE CASCADE;

-- 2.员工(员工id,员工名称,部门id,当前职称id,当前岗位id,入职时间,状态)
DROP TABLE IF EXISTS employees;
CREATE TABLE employees(
    `emp_id` INT NOT NULL AUTO_INCREMENT COMMENT '员工id',
    `emp_name` VARCHAR(30) NOT NULL COMMENT '员工名称',
    `dept_id` INT COMMENT '部门id',
    `cur_title_id` INT COMMENT '当前职称id',
    `cur_position_id` INT COMMENT '当前岗位id',
    `entry_date` DATE NOT NULL COMMENT '入职时间',
    `emp_status` ENUM('在职', '离职') NOT NULL DEFAULT '在职' COMMENT '状态',
    PRIMARY KEY (`emp_id`),

    FOREIGN KEY (dept_id) REFERENCES departments(dept_id) 
    ON DELETE SET NULL ON UPDATE CASCADE,
    FOREIGN KEY (cur_title_id) REFERENCES titles(title_id) 
    ON DELETE SET NULL ON UPDATE CASCADE,
    FOREIGN KEY (cur_position_id) REFERENCES positions(pos_id) 
    ON DELETE SET NULL ON UPDATE CASCADE


) COMMENT '员工';

CREATE INDEX `idx_dept` ON employees (
    `dept_id` 
)COMMENT '部门';
CREATE INDEX `idx_title` ON employees (
    `cur_title_id` 
)COMMENT '当前职称';
CREATE INDEX `idx_pos` ON employees (
    `cur_position_id` 
)COMMENT '当前岗位';

-- 3.职称(职称id,职称类别)
DROP TABLE IF EXISTS titles;
CREATE TABLE titles(
    `title_id` INT NOT NULL AUTO_INCREMENT COMMENT '职称id',
    `title_name` VARCHAR(40) NOT NULL COMMENT '职称类别',
    PRIMARY KEY (`title_id`)
) COMMENT '职称';

--给职称类别加unique约束，避免重复
Alter TABLE titles ADD CONSTRAINT uk_title_name UNIQUE (`title_name`);

-- 4.岗位(岗位id,岗位等级,岗位类别)
DROP TABLE IF EXISTS positions;
CREATE TABLE positions(
    `pos_id` INT NOT NULL AUTO_INCREMENT COMMENT '岗位id',
    `pos_level` TINYINT NOT NULL COMMENT '岗位等级',
    `pos_name` VARCHAR(40) NOT NULL COMMENT '岗位类别',
    PRIMARY KEY (`pos_id`)
) COMMENT '岗位';

--给岗位类别加unique约束，避免重复
Alter TABLE positions ADD CONSTRAINT uk_pos_name UNIQUE (`pos_name`);

-- 5.工资类别(工资类别id,类别名称,生成方式,类型)
DROP TABLE IF EXISTS salary_categories;
CREATE TABLE salary_categories(
    `cat_id` INT NOT NULL AUTO_INCREMENT COMMENT '工资类别id',
    `cat_name` VARCHAR(40) NOT NULL COMMENT '类别名称',
    `calc_mode` ENUM('系统计算', '手动录入') NOT NULL COMMENT '生成方式',
    `cat_type` ENUM('应发', '应扣') NOT NULL COMMENT '类型',
    PRIMARY KEY (`cat_id`)
) COMMENT '工资类别';

-- ① salary_categories.calc_mode 扩展为三值枚举
ALTER TABLE salary_categories
MODIFY COLUMN calc_mode ENUM('系统计算','手动录入','系统计算(可覆盖)') NOT NULL
COMMENT '系统计算=纯自动不可改 | 系统计算(可覆盖)=系统出默认值,HR可调 | 手动录入=纯手工';

--给类别名称加unique约束，避免重复
Alter TABLE salary_categories ADD CONSTRAINT uk_cat_name UNIQUE (`cat_name`);

-- 6.职称-工资(职称id,工资类别id,工资金额)
DROP TABLE IF EXISTS title_salary;
CREATE TABLE title_salary(
    `title_id` INT NOT NULL COMMENT '职称id;关联职称表',
    `cat_id` INT NOT NULL COMMENT '工资类别id;关联工资类别表',
    `salary_amount` DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT '工资金额;该职称对应薪资标准金额',
    PRIMARY KEY (`title_id`,`cat_id`),

    FOREIGN KEY (title_id) REFERENCES titles(title_id) 
    ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (cat_id) REFERENCES salary_categories(cat_id) 
    ON DELETE CASCADE ON UPDATE CASCADE

) COMMENT '职称-工资';

-- 7.岗位-工资(岗位id,工资类别id,工资金额)
DROP TABLE IF EXISTS position_salary;
CREATE TABLE position_salary(
    `pos_id` INT NOT NULL COMMENT '岗位id;关联岗位表',
    `cat_id` INT NOT NULL COMMENT '工资类别id;关联工资类别表',
    `salary_amount` DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT '工资金额;该岗位对应薪资标准金额',
    PRIMARY KEY (`pos_id`,`cat_id`),

    FOREIGN KEY (pos_id) REFERENCES positions(pos_id) 
    ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (cat_id) REFERENCES salary_categories(cat_id) 
    ON DELETE CASCADE ON UPDATE CASCADE

) COMMENT '岗位-工资';

-- 8.工龄规则(规则id,规则名称,基础金额,递增金额,生效日期,结束日期)
DROP TABLE IF EXISTS seniority_rules;
CREATE TABLE seniority_rules(
    `rule_id` INT NOT NULL AUTO_INCREMENT COMMENT '规则id',
    `rule_name` VARCHAR(30) NOT NULL COMMENT '规则名称',
    `base_amount` DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT '基础金额;基础每月工龄工资',
    `add_amount` DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT '递增金额;每多一年递增金额',
    `start_date` DATE NOT NULL COMMENT '生效日期',
    `end_date` DATE DEFAULT NULL COMMENT '结束日期;规则失效日期，NULL = 永久生效',
    PRIMARY KEY (`rule_id`)
) COMMENT '工龄规则';

CREATE UNIQUE INDEX `uk_rule_date` ON seniority_rules (
    `start_date` DESC,
    `end_date` DESC
)COMMENT '有效日期';

-- 9.员工职称变更(变更id,员工id,变更前职称id,变更后职称id,变更时间)
DROP TABLE IF EXISTS emp_title_history;
CREATE TABLE emp_title_history(
    `change_id` INT NOT NULL AUTO_INCREMENT COMMENT '变更id',
    `emp_id` INT NOT NULL COMMENT '员工id',
    `old_title_id` INT NOT NULL COMMENT '变更前职称id',
    `new_title_id` INT NOT NULL COMMENT '变更后职称id',
    `change_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '变更时间',
    PRIMARY KEY (`change_id`),

    FOREIGN KEY (emp_id) REFERENCES employees(emp_id) 
    ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (old_title_id) REFERENCES titles(title_id) 
    ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (new_title_id) REFERENCES titles(title_id) 
    ON DELETE RESTRICT ON UPDATE CASCADE

) COMMENT '员工职称变更';

CREATE INDEX `idx_emp` ON emp_title_history (
    `emp_id` ASC
)COMMENT '员工';

-- 10.员工岗位变动(变更id,员工id,变更前岗位id,变更后岗位id,变更时间)
DROP TABLE IF EXISTS emp_position_history;
CREATE TABLE emp_position_history(
    `change_id` INT NOT NULL AUTO_INCREMENT COMMENT '变更id',
    `emp_id` INT NOT NULL COMMENT '员工id',
    `old_pos_id` INT NOT NULL COMMENT '变更前岗位id',
    `new_pos_id` INT NOT NULL COMMENT '变更后岗位id',
    `change_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '变更时间',
    PRIMARY KEY (`change_id`),

    FOREIGN KEY (emp_id) REFERENCES employees(emp_id) 
    ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (old_pos_id) REFERENCES positions(pos_id) 
    ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (new_pos_id) REFERENCES positions(pos_id) 
    ON DELETE RESTRICT ON UPDATE CASCADE

) COMMENT '员工岗位变动';

CREATE INDEX `idx_emp` ON emp_position_history (
    `emp_id` ASC
)COMMENT '员工';

-- 11.考勤明细表(考勤id,员工id,考勤类别,发生日期)
DROP TABLE IF EXISTS attendance_records;
CREATE TABLE attendance_records(
    `att_id` INT NOT NULL AUTO_INCREMENT COMMENT '考勤id',
    `emp_id` INT NOT NULL COMMENT '员工id',
    `att_type` ENUM('请假', '迟到早退', '旷工', '正常出勤') NOT NULL COMMENT '考勤类别',
    `att_date` DATE NOT NULL COMMENT '发生日期',
    PRIMARY KEY (`att_id`),

    FOREIGN KEY (emp_id) REFERENCES employees(emp_id) 
    ON DELETE CASCADE ON UPDATE CASCADE

) COMMENT '考勤明细表';

-- 12.月度工资明细(明细id,员工id,薪酬月份,工资类别id,金额)
DROP TABLE IF EXISTS monthly_salary_details;
CREATE TABLE monthly_salary_details(
    `detail_id` INT NOT NULL AUTO_INCREMENT COMMENT '明细id',
    `emp_id` INT NOT NULL COMMENT '员工id',
    `salary_month` CHAR(7) NOT NULL COMMENT '薪酬月份;薪酬月份，格式 "YYYY-MM" ',
    `cat_id` INT NOT NULL COMMENT '工资类别id',
    `amount` DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT '金额',
    PRIMARY KEY (`detail_id`),

    FOREIGN KEY (emp_id) REFERENCES employees(emp_id) 
    ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (cat_id) REFERENCES salary_categories(cat_id) 
    ON DELETE CASCADE ON UPDATE CASCADE

) COMMENT '月度工资明细';
--  monthly_salary_details 增加覆盖标记，追踪每条明细是否被人工修改过
--  联合唯一索引：同一员工同月同类薪资仅一条
CREATE UNIQUE INDEX `uk_emp_month_cat` ON monthly_salary_details (
    `emp_id` ,
    `salary_month` ,
    `cat_id` 
);
CREATE INDEX `idx_month` ON monthly_salary_details (
    `salary_month` 
);

-- ③ monthly_salary_details 增加覆盖标记，追踪每条明细是否被人工修改过
ALTER TABLE monthly_salary_details
ADD COLUMN is_overridden TINYINT(1) NOT NULL DEFAULT 0
    COMMENT '0=系统原始值 1=人工已覆盖',
ADD COLUMN override_note VARCHAR(100) DEFAULT NULL
    COMMENT '覆盖原因(如"带薪病假不扣款""申诉通过撤销旷工")';

-- 13.月度工资总(总表id,员工id,薪酬月份,应发合计,应扣合计,实发总工资,状态)
DROP TABLE IF EXISTS monthly_salary_summary;
CREATE TABLE monthly_salary_summary(
    `summary_id` INT NOT NULL AUTO_INCREMENT COMMENT '总表id',
    `emp_id` INT NOT NULL COMMENT '员工id',
    `salary_month` CHAR(7) NOT NULL COMMENT '薪酬月份;薪酬月份，与明细表统一格式',
    `total_income` DECIMAL(10,2) NOT NULL COMMENT '应发合计',
    `total_deduct` DECIMAL(10,2) NOT NULL COMMENT '应扣合计',
    `real_salary` DECIMAL(10,2) NOT NULL COMMENT '实发总工资',
    `pay_status` ENUM('未发放', '待审核','已发放') NOT NULL DEFAULT ('未发放') COMMENT '状态',
    PRIMARY KEY (`summary_id`),

    FOREIGN KEY (emp_id) REFERENCES employees(emp_id) 
    ON DELETE CASCADE ON UPDATE CASCADE

) COMMENT '月度工资总';

CREATE UNIQUE INDEX `uk_emp_month` ON monthly_salary_summary (
    `emp_id` ASC,
    `salary_month` DESC
)COMMENT '员工-月份工资';
CREATE INDEX `idx_month` ON monthly_salary_summary (
    `salary_month` DESC
)COMMENT '月份';

--14.工龄工资表(工龄工资主键 ID, 员工 id, 薪酬月份，工龄规则 ID, 截至薪月完整工龄年数，工龄工资金额)
DROP TABLE IF EXISTS seniority_salary;
-- 工龄工资独立表
CREATE TABLE seniority_salary (
    ss_id        INT  AUTO_INCREMENT PRIMARY KEY,
    emp_id       INT  NOT NULL,
    salary_month CHAR(7) NOT NULL,
    rule_id      INT  NOT NULL COMMENT '适用的工龄规则ID',
    service_years INT  NOT NULL COMMENT '截至薪月的完整工龄年数',
    amount       DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    UNIQUE KEY uk_emp_month (emp_id, salary_month),
    FOREIGN KEY (emp_id) REFERENCES employees(emp_id) ON DELETE CASCADE,
    FOREIGN KEY (rule_id) REFERENCES seniority_rules(rule_id)
) COMMENT '工龄工资表';

CREATE UNIQUE INDEX `uk_ss_emp_month` ON seniority_salary (
    `emp_id` ,
    `salary_month`
)COMMENT '员工-工龄工资';

--15. 系统配置表
DROP TABLE IF EXISTS sys_config;
CREATE TABLE sys_config (
    config_key   VARCHAR(50) NOT NULL UNIQUE PRIMARY KEY COMMENT '配置键',
    config_value VARCHAR(50) NOT NULL COMMENT '配置值'
) COMMENT '系统配置';

-- 种子数据：发薪日
--INSERT INTO sys_config VALUES ('pay_day', '10');
EXPLAIN SELECT * FROM departments WHERE parent_dept_id = 1;