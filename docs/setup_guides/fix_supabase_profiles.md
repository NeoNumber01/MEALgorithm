# 修复 Supabase "public.profiles" 表缺失错误指南

## 问题描述
你遇到了以下错误：
`PostgrestError(message: "Could not find the table 'public.profiles' in the schema cache")`

## 错误原因 (Root Cause)
这个错误表明你的 Supabase 数据库中缺少 `profiles` 表。我们的应用依赖这个表来存储用户的目标 (Goals)、身体数据 (Stats) 和 AI 偏好。如果没有它，Dashboard 无法计算卡路里目标，导致可能会显示空数据或加载失败。

## 解决方案 (Solution)
我们需要在 Supabase 中运行 SQL 脚本来创建这个表。

### 步骤 1: 登录 Supabase Dashboard
1. 访问你的 Supabase 项目后台。
2. 点击左侧菜单栏的 **Build** -> **SQL Editor** (图标类似于命令行 `>_`).

### 步骤 2: 运行修复脚本
1. 点击 **New Query** (新建查询)。
2. 将以下 SQL 代码复制并粘贴到编辑器中：

```sql
-- 1. 创建 profiles 表
create table if not exists public.profiles (
  id uuid not null references auth.users on delete cascade,
  calorie_target integer,
  goal_description text,
  full_name text,
  avatar_url text,
  updated_at timestamp with time zone,
  
  -- 身体数据 (Physical Stats)
  height_cm integer,
  weight_kg numeric(5,2),
  age integer,
  gender text CHECK (gender IN ('male', 'female', 'other')),
  activity_level text CHECK (activity_level IN ('sedentary', 'light', 'moderate', 'active', 'very_active')) DEFAULT 'moderate',
  
  -- 计算目标 (Calculated Targets)
  protein_target integer,
  carbs_target integer,
  fat_target integer,
  
  -- AI 缓存
  cached_feedback text,
  feedback_updated_at timestamp with time zone,
  last_meal_at timestamp with time zone,

  -- 偏好设置
  food_preferences text,
  food_dislikes text,
  dietary_restrictions text,
  custom_notes text,
  
  primary key (id),
  constraint username_length check (char_length(full_name) >= 3)
);

-- 2. 启用行级安全策略 (RLS) - 非常重要！
alter table public.profiles enable row level security;

-- 3. 创建访问策略
create policy "Public profiles are viewable by everyone." on profiles for select using ( true );
create policy "Users can insert their own profile." on profiles for insert with check ( auth.uid() = id );
create policy "Users can update own profile." on profiles for update using ( auth.uid() = id );

-- 4. 自动创建 Profile 的触发器 (当新用户注册时)
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, full_name, avatar_url)
  values (new.id, new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'avatar_url');
  return new;
end;
$$ language plpgsql security definer;

-- 绑定触发器
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
```

3. 点击右下角的 **Run** 按钮。

### 步骤 3: 验证
1. 运行成功后，回到 App，下拉刷新 Dashboard。
2. 错误应该消失，你现在可以正常记录数据了。

---

## 为何要这样做？ (Education)
Supabase 是基于 PostgreSQL 的。`public.profiles` 是一种常见的模式，用于扩展 `auth.users` 表。`auth.users` 由 Supabase 内部管理，且由于安全原因，我们通常不直接向其添加自定义列（如身高、体重）。因此，创建一个通过 `id` 链接及 `Foreign Key` 关联的 `profiles` 表是最佳实践。
