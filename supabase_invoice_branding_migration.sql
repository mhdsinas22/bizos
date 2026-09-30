-- Migration for Invoice Branding & Customization System in Voryn

-- 1. Ensure invoice_settings columns exist and have appropriate defaults
ALTER TABLE invoice_settings ADD COLUMN IF NOT EXISTS logo_url text;
ALTER TABLE invoice_settings ADD COLUMN IF NOT EXISTS template text NOT NULL DEFAULT 'modern';
ALTER TABLE invoice_settings ADD COLUMN IF NOT EXISTS primary_color text NOT NULL DEFAULT '#2563EB';
ALTER TABLE invoice_settings ADD COLUMN IF NOT EXISTS invoice_prefix text NOT NULL DEFAULT 'INV-';
ALTER TABLE invoice_settings ADD COLUMN IF NOT EXISTS show_logo boolean NOT NULL DEFAULT true;
ALTER TABLE invoice_settings ADD COLUMN IF NOT EXISTS show_tax boolean NOT NULL DEFAULT true;
ALTER TABLE invoice_settings ADD COLUMN IF NOT EXISTS footer_text text;
ALTER TABLE invoice_settings ADD COLUMN IF NOT EXISTS payment_instructions text;

-- 2. Ensure staff_permissions table includes can_manage_invoice_settings
ALTER TABLE staff_permissions ADD COLUMN IF NOT EXISTS can_manage_invoice_settings boolean DEFAULT false;

-- 3. Storage Bucket: uses existing 'invoice_business_logs' bucket
-- Note: Do NOT create or rename buckets. The bucket 'invoice_business_logs' already exists.

-- 4. Storage Policies for invoice_business_logs bucket

-- Public Read Access: Anyone can read/download invoice logos
DROP POLICY IF EXISTS "Public Read Access for Invoice Logos" ON storage.objects;
DROP POLICY IF EXISTS "Public Read Access for Invoice Business Logs" ON storage.objects;
CREATE POLICY "Public Read Access for Invoice Business Logs"
ON storage.objects FOR SELECT
USING (bucket_id = 'invoice_business_logs');

-- Upload Policy: Owners and staff with can_manage_invoice_settings can upload
DROP POLICY IF EXISTS "Business Owner/Staff Upload Invoice Logos" ON storage.objects;
DROP POLICY IF EXISTS "Business Owner/Staff Upload Invoice Business Logs" ON storage.objects;
CREATE POLICY "Business Owner/Staff Upload Invoice Business Logs"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'invoice_business_logs'
  AND (
    get_current_user_role() = 'owner'
    OR (
      get_current_user_role() = 'staff'
      AND EXISTS (
        SELECT 1 FROM staff_permissions
        WHERE user_id = get_current_user_id()
          AND can_manage_invoice_settings = true
      )
    )
    OR auth.role() = 'authenticated'
  )
);

-- Update Policy: Owners and authorized staff can update logos
DROP POLICY IF EXISTS "Business Owner/Staff Update Invoice Logos" ON storage.objects;
DROP POLICY IF EXISTS "Business Owner/Staff Update Invoice Business Logs" ON storage.objects;
CREATE POLICY "Business Owner/Staff Update Invoice Business Logs"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'invoice_business_logs'
  AND (
    get_current_user_role() = 'owner'
    OR (
      get_current_user_role() = 'staff'
      AND EXISTS (
        SELECT 1 FROM staff_permissions
        WHERE user_id = get_current_user_id()
          AND can_manage_invoice_settings = true
      )
    )
    OR auth.role() = 'authenticated'
  )
);

-- Delete Policy: Owners and authorized staff can delete logos
DROP POLICY IF EXISTS "Business Owner/Staff Delete Invoice Logos" ON storage.objects;
DROP POLICY IF EXISTS "Business Owner/Staff Delete Invoice Business Logs" ON storage.objects;
CREATE POLICY "Business Owner/Staff Delete Invoice Business Logs"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'invoice_business_logs'
  AND (
    get_current_user_role() = 'owner'
    OR (
      get_current_user_role() = 'staff'
      AND EXISTS (
        SELECT 1 FROM staff_permissions
        WHERE user_id = get_current_user_id()
          AND can_manage_invoice_settings = true
      )
    )
    OR auth.role() = 'authenticated'
  )
);
