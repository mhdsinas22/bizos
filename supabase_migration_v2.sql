-- ==========================================================
-- BizOS Multi-Tenant Invoices, Customers, Products, Payments & Settings Migration
-- ==========================================================

-- 1. CUSTOMERS Table
CREATE TABLE IF NOT EXISTS customers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
  name text NOT NULL,
  phone text,
  email text,
  address text,
  gstin text,
  notes text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_customers_business_id ON customers(business_id);
CREATE INDEX IF NOT EXISTS idx_customers_name ON customers(name);
CREATE INDEX IF NOT EXISTS idx_customers_phone ON customers(phone);


-- 2. PRODUCTS / SERVICES Table
CREATE TABLE IF NOT EXISTS products_services (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
  name text NOT NULL,
  type text NOT NULL DEFAULT 'service', -- 'product' or 'service'
  description text,
  price numeric NOT NULL DEFAULT 0.0,
  tax_rate numeric DEFAULT 0.0,
  unit text DEFAULT 'item',
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_products_services_business_id ON products_services(business_id);
CREATE INDEX IF NOT EXISTS idx_products_services_type ON products_services(type);


-- 3. INVOICE SETTINGS Table
CREATE TABLE IF NOT EXISTS invoice_settings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL UNIQUE REFERENCES businesses(id) ON DELETE CASCADE,
  business_name text,
  business_phone text,
  business_email text,
  business_address text,
  gstin text,
  logo_url text,
  template text NOT NULL DEFAULT 'modern', -- 'modern', 'classic', 'minimal', 'professional'
  primary_color text NOT NULL DEFAULT '#2563EB',
  invoice_prefix text NOT NULL DEFAULT 'INV-',
  show_logo boolean NOT NULL DEFAULT true,
  show_tax boolean NOT NULL DEFAULT true,
  footer_text text,
  payment_instructions text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_invoice_settings_business_id ON invoice_settings(business_id);


-- 4. INVOICES Table
CREATE TABLE IF NOT EXISTS invoices (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
  customer_id uuid REFERENCES customers(id) ON DELETE SET NULL,
  customer_name_snapshot text NOT NULL,
  customer_phone_snapshot text,
  customer_email_snapshot text,
  customer_address_snapshot text,
  customer_gstin_snapshot text,
  invoice_number text NOT NULL,
  sequence_number bigint NOT NULL DEFAULT 1,
  invoice_date date NOT NULL DEFAULT CURRENT_DATE,
  due_date date,
  status text NOT NULL DEFAULT 'draft', -- 'draft', 'sent', 'partially_paid', 'paid', 'overdue', 'cancelled'
  payment_status text NOT NULL DEFAULT 'unpaid', -- 'unpaid', 'partially_paid', 'paid'
  subtotal numeric NOT NULL DEFAULT 0.0,
  discount_type text DEFAULT 'flat', -- 'percentage', 'flat'
  discount_amount numeric DEFAULT 0.0,
  tax_amount numeric DEFAULT 0.0,
  grand_total numeric NOT NULL DEFAULT 0.0,
  paid_amount numeric NOT NULL DEFAULT 0.0,
  balance_amount numeric NOT NULL DEFAULT 0.0,
  notes text,
  payment_instructions text,
  template_snapshot jsonb,
  created_by_user_id uuid REFERENCES users(id) ON DELETE SET NULL,
  created_by_name text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  CONSTRAINT unique_invoice_number_per_business UNIQUE (business_id, invoice_number)
);

CREATE INDEX IF NOT EXISTS idx_invoices_business_id ON invoices(business_id);
CREATE INDEX IF NOT EXISTS idx_invoices_customer_id ON invoices(customer_id);
CREATE INDEX IF NOT EXISTS idx_invoices_status ON invoices(status);
CREATE INDEX IF NOT EXISTS idx_invoices_payment_status ON invoices(payment_status);
CREATE INDEX IF NOT EXISTS idx_invoices_invoice_date ON invoices(invoice_date);


-- 5. INVOICE ITEMS Table
CREATE TABLE IF NOT EXISTS invoice_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_id uuid NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
  product_service_id uuid REFERENCES products_services(id) ON DELETE SET NULL,
  item_name text NOT NULL,
  description text,
  quantity numeric NOT NULL DEFAULT 1,
  unit text DEFAULT 'item',
  unit_price numeric NOT NULL DEFAULT 0.0,
  discount numeric DEFAULT 0.0,
  tax_rate numeric DEFAULT 0.0,
  tax_amount numeric DEFAULT 0.0,
  line_total numeric NOT NULL DEFAULT 0.0,
  created_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_invoice_items_invoice_id ON invoice_items(invoice_id);


-- 6. INVOICE PAYMENTS Table
CREATE TABLE IF NOT EXISTS invoice_payments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_id uuid NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
  business_id uuid NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
  income_id uuid REFERENCES incomes(id) ON DELETE SET NULL,
  amount numeric NOT NULL,
  payment_date timestamptz NOT NULL DEFAULT now(),
  payment_method text NOT NULL DEFAULT 'Cash',
  reference_number text,
  notes text,
  created_by_user_id uuid REFERENCES users(id) ON DELETE SET NULL,
  created_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_invoice_payments_invoice_id ON invoice_payments(invoice_id);
CREATE INDEX IF NOT EXISTS idx_invoice_payments_business_id ON invoice_payments(business_id);


-- 7. Add Granular Permission Columns to STAFF_PERMISSIONS Table
ALTER TABLE staff_permissions ADD COLUMN IF NOT EXISTS can_view_invoices boolean DEFAULT true;
ALTER TABLE staff_permissions ADD COLUMN IF NOT EXISTS can_create_invoices boolean DEFAULT true;
ALTER TABLE staff_permissions ADD COLUMN IF NOT EXISTS can_edit_invoices boolean DEFAULT true;
ALTER TABLE staff_permissions ADD COLUMN IF NOT EXISTS can_delete_invoices boolean DEFAULT false;
ALTER TABLE staff_permissions ADD COLUMN IF NOT EXISTS can_manage_customers boolean DEFAULT true;
ALTER TABLE staff_permissions ADD COLUMN IF NOT EXISTS can_manage_products boolean DEFAULT true;
ALTER TABLE staff_permissions ADD COLUMN IF NOT EXISTS can_manage_payments boolean DEFAULT true;
ALTER TABLE staff_permissions ADD COLUMN IF NOT EXISTS can_manage_invoice_settings boolean DEFAULT false;


-- 8. RPC Function for Safe Per-Business Sequential Invoice Number Generation
CREATE OR REPLACE FUNCTION generate_next_invoice_number(p_business_id uuid, p_prefix text DEFAULT 'INV-')
RETURNS jsonb SECURITY DEFINER AS $$
DECLARE
  v_next_seq bigint;
  v_inv_num text;
BEGIN
  SELECT COALESCE(MAX(sequence_number), 0) + 1 INTO v_next_seq
  FROM invoices
  WHERE business_id = p_business_id;

  v_inv_num := TRIM(p_prefix) || LPAD(v_next_seq::text, 4, '0');

  RETURN jsonb_build_object(
    'sequence_number', v_next_seq,
    'invoice_number', v_inv_num
  );
END;
$$ LANGUAGE plpgsql;


-- 9. Enable Row Level Security (RLS) on New Tables
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE products_services ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoice_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoice_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoice_payments ENABLE ROW LEVEL SECURITY;


-- 10. Define RLS Policies for Multi-Tenant Business Isolation

-- ==================== CUSTOMERS ====================
CREATE POLICY customers_select_policy ON customers FOR SELECT
  USING (
    business_id IN (
      SELECT id FROM businesses WHERE owner_id = get_current_user_id() AND get_current_user_role() = 'owner'
    )
    OR (
      get_current_user_role() = 'staff'
      AND business_id IN (
        SELECT business_id FROM staff_permissions WHERE user_id = get_current_user_id()
      )
    )
  );

CREATE POLICY customers_insert_policy ON customers FOR INSERT
  WITH CHECK (
    business_id IN (
      SELECT id FROM businesses WHERE owner_id = get_current_user_id() AND get_current_user_role() = 'owner'
    )
    OR (
      get_current_user_role() = 'staff'
      AND business_id IN (
        SELECT business_id FROM staff_permissions WHERE user_id = get_current_user_id()
      )
    )
  );

CREATE POLICY customers_update_policy ON customers FOR UPDATE
  USING (
    business_id IN (
      SELECT id FROM businesses WHERE owner_id = get_current_user_id() AND get_current_user_role() = 'owner'
    )
    OR (
      get_current_user_role() = 'staff'
      AND business_id IN (
        SELECT business_id FROM staff_permissions WHERE user_id = get_current_user_id()
      )
    )
  );

CREATE POLICY customers_delete_policy ON customers FOR DELETE
  USING (
    business_id IN (
      SELECT id FROM businesses WHERE owner_id = get_current_user_id() AND get_current_user_role() = 'owner'
    )
    OR (
      get_current_user_role() = 'staff'
      AND business_id IN (
        SELECT business_id FROM staff_permissions WHERE user_id = get_current_user_id()
      )
    )
  );


-- ==================== PRODUCTS_SERVICES ====================
CREATE POLICY products_services_select_policy ON products_services FOR SELECT
  USING (
    business_id IN (
      SELECT id FROM businesses WHERE owner_id = get_current_user_id() AND get_current_user_role() = 'owner'
    )
    OR (
      get_current_user_role() = 'staff'
      AND business_id IN (
        SELECT business_id FROM staff_permissions WHERE user_id = get_current_user_id()
      )
    )
  );

CREATE POLICY products_services_insert_policy ON products_services FOR INSERT
  WITH CHECK (
    business_id IN (
      SELECT id FROM businesses WHERE owner_id = get_current_user_id() AND get_current_user_role() = 'owner'
    )
    OR (
      get_current_user_role() = 'staff'
      AND business_id IN (
        SELECT business_id FROM staff_permissions WHERE user_id = get_current_user_id()
      )
    )
  );

CREATE POLICY products_services_update_policy ON products_services FOR UPDATE
  USING (
    business_id IN (
      SELECT id FROM businesses WHERE owner_id = get_current_user_id() AND get_current_user_role() = 'owner'
    )
    OR (
      get_current_user_role() = 'staff'
      AND business_id IN (
        SELECT business_id FROM staff_permissions WHERE user_id = get_current_user_id()
      )
    )
  );

CREATE POLICY products_services_delete_policy ON products_services FOR DELETE
  USING (
    business_id IN (
      SELECT id FROM businesses WHERE owner_id = get_current_user_id() AND get_current_user_role() = 'owner'
    )
    OR (
      get_current_user_role() = 'staff'
      AND business_id IN (
        SELECT business_id FROM staff_permissions WHERE user_id = get_current_user_id()
      )
    )
  );


-- ==================== INVOICE SETTINGS ====================
CREATE POLICY invoice_settings_select_policy ON invoice_settings FOR SELECT
  USING (
    business_id IN (
      SELECT id FROM businesses WHERE owner_id = get_current_user_id() AND get_current_user_role() = 'owner'
    )
    OR (
      get_current_user_role() = 'staff'
      AND business_id IN (
        SELECT business_id FROM staff_permissions WHERE user_id = get_current_user_id()
      )
    )
  );

CREATE POLICY invoice_settings_insert_policy ON invoice_settings FOR INSERT
  WITH CHECK (
    business_id IN (
      SELECT id FROM businesses WHERE owner_id = get_current_user_id() AND get_current_user_role() = 'owner'
    )
    OR (
      get_current_user_role() = 'staff'
      AND business_id IN (
        SELECT business_id FROM staff_permissions WHERE user_id = get_current_user_id()
      )
    )
  );

CREATE POLICY invoice_settings_update_policy ON invoice_settings FOR UPDATE
  USING (
    business_id IN (
      SELECT id FROM businesses WHERE owner_id = get_current_user_id() AND get_current_user_role() = 'owner'
    )
    OR (
      get_current_user_role() = 'staff'
      AND business_id IN (
        SELECT business_id FROM staff_permissions WHERE user_id = get_current_user_id()
      )
    )
  );


-- ==================== INVOICES ====================
CREATE POLICY invoices_select_policy ON invoices FOR SELECT
  USING (
    business_id IN (
      SELECT id FROM businesses WHERE owner_id = get_current_user_id() AND get_current_user_role() = 'owner'
    )
    OR (
      get_current_user_role() = 'staff'
      AND business_id IN (
        SELECT business_id FROM staff_permissions WHERE user_id = get_current_user_id()
      )
    )
  );

CREATE POLICY invoices_insert_policy ON invoices FOR INSERT
  WITH CHECK (
    business_id IN (
      SELECT id FROM businesses WHERE owner_id = get_current_user_id() AND get_current_user_role() = 'owner'
    )
    OR (
      get_current_user_role() = 'staff'
      AND business_id IN (
        SELECT business_id FROM staff_permissions WHERE user_id = get_current_user_id()
      )
    )
  );

CREATE POLICY invoices_update_policy ON invoices FOR UPDATE
  USING (
    business_id IN (
      SELECT id FROM businesses WHERE owner_id = get_current_user_id() AND get_current_user_role() = 'owner'
    )
    OR (
      get_current_user_role() = 'staff'
      AND business_id IN (
        SELECT business_id FROM staff_permissions WHERE user_id = get_current_user_id()
      )
    )
  );

CREATE POLICY invoices_delete_policy ON invoices FOR DELETE
  USING (
    business_id IN (
      SELECT id FROM businesses WHERE owner_id = get_current_user_id() AND get_current_user_role() = 'owner'
    )
    OR (
      get_current_user_role() = 'staff'
      AND business_id IN (
        SELECT business_id FROM staff_permissions WHERE user_id = get_current_user_id()
      )
    )
  );


-- ==================== INVOICE_ITEMS ====================
CREATE POLICY invoice_items_select_policy ON invoice_items FOR SELECT
  USING (
    invoice_id IN (
      SELECT id FROM invoices WHERE business_id IN (
        SELECT id FROM businesses WHERE owner_id = get_current_user_id() AND get_current_user_role() = 'owner'
      ) OR (
        get_current_user_role() = 'staff' AND business_id IN (
          SELECT business_id FROM staff_permissions WHERE user_id = get_current_user_id()
        )
      )
    )
  );

CREATE POLICY invoice_items_insert_policy ON invoice_items FOR INSERT
  WITH CHECK (
    invoice_id IN (
      SELECT id FROM invoices WHERE business_id IN (
        SELECT id FROM businesses WHERE owner_id = get_current_user_id() AND get_current_user_role() = 'owner'
      ) OR (
        get_current_user_role() = 'staff' AND business_id IN (
          SELECT business_id FROM staff_permissions WHERE user_id = get_current_user_id()
        )
      )
    )
  );

CREATE POLICY invoice_items_update_policy ON invoice_items FOR UPDATE
  USING (
    invoice_id IN (
      SELECT id FROM invoices WHERE business_id IN (
        SELECT id FROM businesses WHERE owner_id = get_current_user_id() AND get_current_user_role() = 'owner'
      ) OR (
        get_current_user_role() = 'staff' AND business_id IN (
          SELECT business_id FROM staff_permissions WHERE user_id = get_current_user_id()
        )
      )
    )
  );

CREATE POLICY invoice_items_delete_policy ON invoice_items FOR DELETE
  USING (
    invoice_id IN (
      SELECT id FROM invoices WHERE business_id IN (
        SELECT id FROM businesses WHERE owner_id = get_current_user_id() AND get_current_user_role() = 'owner'
      ) OR (
        get_current_user_role() = 'staff' AND business_id IN (
          SELECT business_id FROM staff_permissions WHERE user_id = get_current_user_id()
        )
      )
    )
  );


-- ==================== INVOICE_PAYMENTS ====================
CREATE POLICY invoice_payments_select_policy ON invoice_payments FOR SELECT
  USING (
    business_id IN (
      SELECT id FROM businesses WHERE owner_id = get_current_user_id() AND get_current_user_role() = 'owner'
    )
    OR (
      get_current_user_role() = 'staff'
      AND business_id IN (
        SELECT business_id FROM staff_permissions WHERE user_id = get_current_user_id()
      )
    )
  );

CREATE POLICY invoice_payments_insert_policy ON invoice_payments FOR INSERT
  WITH CHECK (
    business_id IN (
      SELECT id FROM businesses WHERE owner_id = get_current_user_id() AND get_current_user_role() = 'owner'
    )
    OR (
      get_current_user_role() = 'staff'
      AND business_id IN (
        SELECT business_id FROM staff_permissions WHERE user_id = get_current_user_id()
      )
    )
  );

CREATE POLICY invoice_payments_update_policy ON invoice_payments FOR UPDATE
  USING (
    business_id IN (
      SELECT id FROM businesses WHERE owner_id = get_current_user_id() AND get_current_user_role() = 'owner'
    )
    OR (
      get_current_user_role() = 'staff'
      AND business_id IN (
        SELECT business_id FROM staff_permissions WHERE user_id = get_current_user_id()
      )
    )
  );

CREATE POLICY invoice_payments_delete_policy ON invoice_payments FOR DELETE
  USING (
    business_id IN (
      SELECT id FROM businesses WHERE owner_id = get_current_user_id() AND get_current_user_role() = 'owner'
    )
    OR (
      get_current_user_role() = 'staff'
      AND business_id IN (
        SELECT business_id FROM staff_permissions WHERE user_id = get_current_user_id()
      )
    )
  );
