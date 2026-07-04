-- ==========================================================
-- BizOS Multi-Tenant Isolation Migration Script
-- ==========================================================

-- 1. Helper Functions to Extract Security Context from Request Headers
CREATE OR REPLACE FUNCTION get_current_user_id() RETURNS uuid AS $$
  SELECT NULLIF(current_setting('request.headers', true)::json->>'x-user-id', '')::uuid;
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION get_current_owner_id() RETURNS uuid AS $$
  SELECT NULLIF(current_setting('request.headers', true)::json->>'x-owner-id', '')::uuid;
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION get_current_user_role() RETURNS text AS $$
  SELECT LOWER(NULLIF(current_setting('request.headers', true)::json->>'x-user-role', ''));
$$ LANGUAGE sql STABLE;


-- 2. Alter USERS Table
ALTER TABLE users ADD COLUMN IF NOT EXISTS owner_id uuid REFERENCES users(id);

-- Set existing owners' owner_id to their own ID
UPDATE users SET owner_id = id WHERE LOWER(role) = 'owner' AND owner_id IS NULL;


-- 3. Alter BUSINESSES Table
-- Ensure owner_id points to users table
ALTER TABLE businesses ADD CONSTRAINT fk_businesses_owner FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE CASCADE;


-- 4. Alter STAFF_PERMISSIONS Table
ALTER TABLE staff_permissions ADD CONSTRAINT fk_permissions_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
ALTER TABLE staff_permissions ADD CONSTRAINT fk_permissions_business FOREIGN KEY (business_id) REFERENCES businesses(id) ON DELETE CASCADE;


-- 5. Alter TASKS Table
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS owner_id uuid REFERENCES users(id) ON DELETE CASCADE;
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS created_by uuid REFERENCES users(id) ON DELETE SET NULL;
ALTER TABLE tasks ADD CONSTRAINT fk_tasks_business FOREIGN KEY (business_id) REFERENCES businesses(id) ON DELETE CASCADE;


-- 6. Create ACCOUNTS Table
CREATE TABLE IF NOT EXISTS accounts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid REFERENCES businesses(id) ON DELETE CASCADE,
  owner_id uuid REFERENCES users(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now()
);


-- 7. Performance Indexes on Foreign Keys and Frequently Filtered Columns
CREATE INDEX IF NOT EXISTS idx_users_owner_id ON users(owner_id);
CREATE INDEX IF NOT EXISTS idx_users_userid ON users(userid);
CREATE INDEX IF NOT EXISTS idx_businesses_owner_id ON businesses(owner_id);
CREATE INDEX IF NOT EXISTS idx_staff_permissions_user_id ON staff_permissions(user_id);
CREATE INDEX IF NOT EXISTS idx_staff_permissions_business_id ON staff_permissions(business_id);
CREATE INDEX IF NOT EXISTS idx_tasks_owner_id ON tasks(owner_id);
CREATE INDEX IF NOT EXISTS idx_tasks_business_id ON tasks(business_id);
CREATE INDEX IF NOT EXISTS idx_accounts_owner_id ON accounts(owner_id);
CREATE INDEX IF NOT EXISTS idx_accounts_business_id ON accounts(business_id);
CREATE INDEX IF NOT EXISTS idx_incomes_business_id ON incomes(business_id);
CREATE INDEX IF NOT EXISTS idx_expenses_business_id ON expenses(business_id);
CREATE INDEX IF NOT EXISTS idx_activities_business_id ON activities(business_id);


-- 8. Secure RPC Function for Login
-- Runs with SECURITY DEFINER to bypass RLS restrictions during credentials check
CREATE OR REPLACE FUNCTION login_user(p_userid text, p_password text)
RETURNS TABLE (
  id uuid,
  userid text,
  password text,
  name text,
  role text,
  owner_id uuid,
  email text,
  phone text,
  status text,
  is_active boolean,
  login_status text
) SECURITY DEFINER AS $$
DECLARE
  v_id uuid;
  v_userid text;
  v_password text;
  v_name text;
  v_role text;
  v_owner_id uuid;
  v_email text;
  v_phone text;
  v_status text;
  v_is_active boolean;
BEGIN
  SELECT u.id, u.userid, u.password, u.name, u.role, u.owner_id, u.email, u.phone, u.status, u.is_active
  INTO v_id, v_userid, v_password, v_name, v_role, v_owner_id, v_email, v_phone, v_status, v_is_active
  FROM users u
  WHERE LOWER(TRIM(u.userid)) = LOWER(TRIM(p_userid))
  LIMIT 1;

  IF v_id IS NULL THEN
    RETURN QUERY SELECT NULL::uuid, NULL::text, NULL::text, NULL::text, NULL::text, NULL::uuid, NULL::text, NULL::text, NULL::text, NULL::boolean, 'user_not_found'::text;
  ELSIF v_password <> p_password THEN
    RETURN QUERY SELECT NULL::uuid, NULL::text, NULL::text, NULL::text, NULL::text, NULL::uuid, NULL::text, NULL::text, NULL::text, NULL::boolean, 'incorrect_password'::text;
  ELSE
    RETURN QUERY SELECT v_id, v_userid, v_password, v_name, v_role, v_owner_id, v_email, v_phone, v_status, v_is_active, 'success'::text;
  END IF;
END;
$$ LANGUAGE plpgsql;


-- 9. Enable Row Level Security (RLS) on Tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE businesses ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff_permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE incomes ENABLE ROW LEVEL SECURITY;
ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE activities ENABLE ROW LEVEL SECURITY;


-- 10. Define RLS Policies

-- ==================== USERS ====================
CREATE POLICY users_select_policy ON users FOR SELECT
  USING (
    id = get_current_user_id()
    OR (get_current_user_role() = 'owner' AND owner_id = get_current_user_id())
  );

CREATE POLICY users_insert_policy ON users FOR INSERT
  WITH CHECK (
    (get_current_user_role() = 'owner' AND owner_id = get_current_user_id() AND LOWER(role) = 'staff')
    OR (LOWER(role) = 'owner' AND id = owner_id)
  );

CREATE POLICY users_update_policy ON users FOR UPDATE
  USING (
    id = get_current_user_id()
    OR (get_current_user_role() = 'owner' AND owner_id = get_current_user_id())
  )
  WITH CHECK (
    id = get_current_user_id()
    OR (get_current_user_role() = 'owner' AND owner_id = get_current_user_id())
  );

CREATE POLICY users_delete_policy ON users FOR DELETE
  USING (
    get_current_user_role() = 'owner'
    AND owner_id = get_current_user_id()
    AND LOWER(role) = 'staff'
  );


-- ==================== BUSINESSES ====================
CREATE POLICY businesses_select_policy ON businesses FOR SELECT
  USING (
    (get_current_user_role() = 'owner' AND owner_id = get_current_user_id())
    OR (
      get_current_user_role() = 'staff'
      AND id IN (
        SELECT business_id FROM staff_permissions WHERE user_id = get_current_user_id()
      )
    )
  );

CREATE POLICY businesses_insert_policy ON businesses FOR INSERT
  WITH CHECK (get_current_user_role() = 'owner' AND owner_id = get_current_user_id());

CREATE POLICY businesses_update_policy ON businesses FOR UPDATE
  USING (get_current_user_role() = 'owner' AND owner_id = get_current_user_id())
  WITH CHECK (get_current_user_role() = 'owner' AND owner_id = get_current_user_id());

CREATE POLICY businesses_delete_policy ON businesses FOR DELETE
  USING (get_current_user_role() = 'owner' AND owner_id = get_current_user_id());


-- ==================== STAFF_PERMISSIONS ====================
CREATE POLICY staff_permissions_select_policy ON staff_permissions FOR SELECT
  USING (
    user_id = get_current_user_id()
    OR (
      get_current_user_role() = 'owner'
      AND user_id IN (SELECT id FROM users WHERE owner_id = get_current_user_id())
    )
  );

CREATE POLICY staff_permissions_insert_policy ON staff_permissions FOR INSERT
  WITH CHECK (
    get_current_user_role() = 'owner'
    AND user_id IN (SELECT id FROM users WHERE owner_id = get_current_user_id())
    AND business_id IN (SELECT id FROM businesses WHERE owner_id = get_current_user_id())
  );

CREATE POLICY staff_permissions_update_policy ON staff_permissions FOR UPDATE
  USING (
    get_current_user_role() = 'owner'
    AND user_id IN (SELECT id FROM users WHERE owner_id = get_current_user_id())
  )
  WITH CHECK (
    get_current_user_role() = 'owner'
    AND user_id IN (SELECT id FROM users WHERE owner_id = get_current_user_id())
  );

CREATE POLICY staff_permissions_delete_policy ON staff_permissions FOR DELETE
  USING (
    get_current_user_role() = 'owner'
    AND user_id IN (SELECT id FROM users WHERE owner_id = get_current_user_id())
  );


-- ==================== TASKS ====================
CREATE POLICY tasks_select_policy ON tasks FOR SELECT
  USING (
    (get_current_user_role() = 'owner' AND owner_id = get_current_user_id())
    OR (
      get_current_user_role() = 'staff'
      AND business_id IN (
        SELECT business_id FROM staff_permissions
        WHERE user_id = get_current_user_id() AND can_view_tasks = true
      )
    )
  );

CREATE POLICY tasks_insert_policy ON tasks FOR INSERT
  WITH CHECK (
    (
      get_current_user_role() = 'owner'
      AND owner_id = get_current_user_id()
      AND business_id IN (SELECT id FROM businesses WHERE owner_id = get_current_user_id())
    )
    OR (
      get_current_user_role() = 'staff'
      AND owner_id = get_current_owner_id()
      AND business_id IN (
        SELECT business_id FROM staff_permissions
        WHERE user_id = get_current_user_id() AND can_add_tasks = true
      )
    )
  );

CREATE POLICY tasks_update_policy ON tasks FOR UPDATE
  USING (
    (get_current_user_role() = 'owner' AND owner_id = get_current_user_id())
    OR (
      get_current_user_role() = 'staff'
      AND business_id IN (
        SELECT business_id FROM staff_permissions
        WHERE user_id = get_current_user_id() AND can_add_tasks = true
      )
    )
  )
  WITH CHECK (
    (get_current_user_role() = 'owner' AND owner_id = get_current_user_id())
    OR (
      get_current_user_role() = 'staff'
      AND business_id IN (
        SELECT business_id FROM staff_permissions
        WHERE user_id = get_current_user_id() AND can_add_tasks = true
      )
    )
  );

CREATE POLICY tasks_delete_policy ON tasks FOR DELETE
  USING (
    (get_current_user_role() = 'owner' AND owner_id = get_current_user_id())
    OR (
      get_current_user_role() = 'staff'
      AND business_id IN (
        SELECT business_id FROM staff_permissions
        WHERE user_id = get_current_user_id() AND can_add_tasks = true
      )
    )
  );


-- ==================== ACCOUNTS ====================
CREATE POLICY accounts_select_policy ON accounts FOR SELECT
  USING (
    (get_current_user_role() = 'owner' AND owner_id = get_current_user_id())
    OR (
      get_current_user_role() = 'staff'
      AND business_id IN (
        SELECT business_id FROM staff_permissions
        WHERE user_id = get_current_user_id() AND can_view_accounts = true
      )
    )
  );

CREATE POLICY accounts_insert_policy ON accounts FOR INSERT
  WITH CHECK (
    (
      get_current_user_role() = 'owner'
      AND owner_id = get_current_user_id()
      AND business_id IN (SELECT id FROM businesses WHERE owner_id = get_current_user_id())
    )
    OR (
      get_current_user_role() = 'staff'
      AND owner_id = get_current_owner_id()
      AND business_id IN (
        SELECT business_id FROM staff_permissions
        WHERE user_id = get_current_user_id() AND can_view_accounts = true
      )
    )
  );

CREATE POLICY accounts_update_policy ON accounts FOR UPDATE
  USING (
    (get_current_user_role() = 'owner' AND owner_id = get_current_user_id())
    OR (
      get_current_user_role() = 'staff'
      AND business_id IN (
        SELECT business_id FROM staff_permissions
        WHERE user_id = get_current_user_id() AND can_view_accounts = true
      )
    )
  )
  WITH CHECK (
    (get_current_user_role() = 'owner' AND owner_id = get_current_user_id())
    OR (
      get_current_user_role() = 'staff'
      AND business_id IN (
        SELECT business_id FROM staff_permissions
        WHERE user_id = get_current_user_id() AND can_view_accounts = true
      )
    )
  );

CREATE POLICY accounts_delete_policy ON accounts FOR DELETE
  USING (
    (get_current_user_role() = 'owner' AND owner_id = get_current_user_id())
    OR (
      get_current_user_role() = 'staff'
      AND business_id IN (
        SELECT business_id FROM staff_permissions
        WHERE user_id = get_current_user_id() AND can_view_accounts = true
      )
    )
  );


-- ==================== INCOMES ====================
CREATE POLICY incomes_select_policy ON incomes FOR SELECT
  USING (
    business_id IN (
      SELECT id FROM businesses WHERE owner_id = get_current_user_id() AND get_current_user_role() = 'owner'
    )
    OR (
      get_current_user_role() = 'staff'
      AND business_id IN (
        SELECT business_id FROM staff_permissions
        WHERE user_id = get_current_user_id() AND can_view_accounts = true
      )
    )
  );

CREATE POLICY incomes_insert_policy ON incomes FOR INSERT
  WITH CHECK (
    business_id IN (
      SELECT id FROM businesses WHERE owner_id = get_current_user_id() AND get_current_user_role() = 'owner'
    )
    OR (
      get_current_user_role() = 'staff'
      AND business_id IN (
        SELECT business_id FROM staff_permissions
        WHERE user_id = get_current_user_id() AND can_view_accounts = true
      )
    )
  );

CREATE POLICY incomes_update_policy ON incomes FOR UPDATE
  USING (
    business_id IN (
      SELECT id FROM businesses WHERE owner_id = get_current_user_id() AND get_current_user_role() = 'owner'
    )
    OR (
      get_current_user_role() = 'staff'
      AND business_id IN (
        SELECT business_id FROM staff_permissions
        WHERE user_id = get_current_user_id() AND can_view_accounts = true
      )
    )
  )
  WITH CHECK (
    business_id IN (
      SELECT id FROM businesses WHERE owner_id = get_current_user_id() AND get_current_user_role() = 'owner'
    )
    OR (
      get_current_user_role() = 'staff'
      AND business_id IN (
        SELECT business_id FROM staff_permissions
        WHERE user_id = get_current_user_id() AND can_view_accounts = true
      )
    )
  );

CREATE POLICY incomes_delete_policy ON incomes FOR DELETE
  USING (
    business_id IN (
      SELECT id FROM businesses WHERE owner_id = get_current_user_id() AND get_current_user_role() = 'owner'
    )
    OR (
      get_current_user_role() = 'staff'
      AND business_id IN (
        SELECT business_id FROM staff_permissions
        WHERE user_id = get_current_user_id() AND can_view_accounts = true
      )
    )
  );


-- ==================== EXPENSES ====================
CREATE POLICY expenses_select_policy ON expenses FOR SELECT
  USING (
    business_id IN (
      SELECT id FROM businesses WHERE owner_id = get_current_user_id() AND get_current_user_role() = 'owner'
    )
    OR (
      get_current_user_role() = 'staff'
      AND business_id IN (
        SELECT business_id FROM staff_permissions
        WHERE user_id = get_current_user_id() AND can_view_accounts = true
      )
    )
  );

CREATE POLICY expenses_insert_policy ON expenses FOR INSERT
  WITH CHECK (
    business_id IN (
      SELECT id FROM businesses WHERE owner_id = get_current_user_id() AND get_current_user_role() = 'owner'
    )
    OR (
      get_current_user_role() = 'staff'
      AND business_id IN (
        SELECT business_id FROM staff_permissions
        WHERE user_id = get_current_user_id() AND can_view_accounts = true
      )
    )
  );

CREATE POLICY expenses_update_policy ON expenses FOR UPDATE
  USING (
    business_id IN (
      SELECT id FROM businesses WHERE owner_id = get_current_user_id() AND get_current_user_role() = 'owner'
    )
    OR (
      get_current_user_role() = 'staff'
      AND business_id IN (
        SELECT business_id FROM staff_permissions
        WHERE user_id = get_current_user_id() AND can_view_accounts = true
      )
    )
  )
  WITH CHECK (
    business_id IN (
      SELECT id FROM businesses WHERE owner_id = get_current_user_id() AND get_current_user_role() = 'owner'
    )
    OR (
      get_current_user_role() = 'staff'
      AND business_id IN (
        SELECT business_id FROM staff_permissions
        WHERE user_id = get_current_user_id() AND can_view_accounts = true
      )
    )
  );

CREATE POLICY expenses_delete_policy ON expenses FOR DELETE
  USING (
    business_id IN (
      SELECT id FROM businesses WHERE owner_id = get_current_user_id() AND get_current_user_role() = 'owner'
    )
    OR (
      get_current_user_role() = 'staff'
      AND business_id IN (
        SELECT business_id FROM staff_permissions
        WHERE user_id = get_current_user_id() AND can_view_accounts = true
      )
    )
  );


-- ==================== ACTIVITIES ====================
CREATE POLICY activities_select_policy ON activities FOR SELECT
  USING (
    business_id IS NULL
    OR business_id IN (
      SELECT id FROM businesses WHERE owner_id = get_current_user_id() AND get_current_user_role() = 'owner'
    )
    OR (
      get_current_user_role() = 'staff'
      AND business_id IN (
        SELECT business_id FROM staff_permissions
        WHERE user_id = get_current_user_id()
      )
    )
  );

CREATE POLICY activities_insert_policy ON activities FOR INSERT
  WITH CHECK (
    business_id IS NULL
    OR business_id IN (
      SELECT id FROM businesses WHERE owner_id = get_current_user_id() AND get_current_user_role() = 'owner'
    )
    OR (
      get_current_user_role() = 'staff'
      AND business_id IN (
        SELECT business_id FROM staff_permissions
        WHERE user_id = get_current_user_id()
      )
    )
  );


-- ==================== PERSONAL_EXPENSES ====================
CREATE TABLE IF NOT EXISTS personal_expenses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id uuid REFERENCES users(id) ON DELETE CASCADE,
  amount numeric NOT NULL,
  category text NOT NULL,
  description text,
  expense_date date NOT NULL DEFAULT CURRENT_DATE,
  created_at timestamptz DEFAULT now()
);

-- Enable RLS and add Owner-Only policy
ALTER TABLE personal_expenses ENABLE ROW LEVEL SECURITY;

CREATE POLICY personal_expenses_owner_policy ON personal_expenses
  USING (get_current_user_role() = 'owner' AND owner_id = get_current_user_id())
  WITH CHECK (get_current_user_role() = 'owner' AND owner_id = get_current_user_id());

