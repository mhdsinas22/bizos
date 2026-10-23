# Supabase Edge Function: `create-staff-account`

## 1. Overview
This Edge Function securely provisions new staff accounts for Voryn ERP using the Supabase Admin Auth API.

### Key Security & Architectural Benefits:
1. **Preserves Owner Session**: In Supabase Flutter client, invoking `signUp()` directly replaces or terminates the owner's active authentication session. This Edge Function provisions staff on the backend using the Admin API without altering the client session.
2. **Server-Side Authorization**: Validates caller JWT via `supabase.auth.getUser()`, verifies that the caller has an active profile with role `Owner` or `Admin`, and derives the staff `owner_id` directly from the verified caller identity (never trusting an unverified client parameter).
3. **Confirmed Immediate Login**: Provisions staff with `email_confirm: true` so staff can log in immediately with email and password without waiting for email verification links.
4. **No Plaintext Passwords**: Staff credentials are stored exclusively in Supabase Auth. The `public.users` table stores `auth_user_id` and does not store plaintext passwords.
5. **Atomic Cleanup / Compensating Transaction**: If profile creation or branch/permission insertion fails, the newly created Supabase Auth user is automatically rolled back and deleted to avoid orphaned auth records.

---

## 2. Deployment Instructions

### Prerequisites
- Supabase CLI installed and logged in (`supabase login`).
- Supabase project linked (`supabase link --project-ref <your-project-id>`).

### Deploying the Function
Run the following command from the workspace root:

```bash
supabase functions deploy create-staff-account --no-verify-jwt
```

> **Note on `--no-verify-jwt`**: We pass `--no-verify-jwt` because our function code explicitly performs custom JWT verification using `supabase.auth.getUser(token)` and evaluates database owner roles before execution.

---

## 3. Environment Variables & Secrets

Supabase Edge Functions automatically have access to:
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY`

Verify that these variables exist in your Supabase Project Settings > Edge Functions.

---

## 4. Database Migration Execution

Before invoking the function or using the new staff flow, apply the SQL migration:
1. Open your **Supabase Dashboard** > **SQL Editor**.
2. Copy and paste the contents of `supabase_staff_auth_migration.sql`.
3. Click **Run**.

This migration:
- Ensures `users.auth_user_id` is indexed with a unique constraint.
- Ensures `LOWER(TRIM(users.email))` has a unique index.
- Adds necessary performance indexes on `staff_businesses` and `staff_permissions`.
- Creates the `get_my_profile()` security definer function.
- Sets up Row Level Security (RLS) policies allowing owners full management of their staff and staff members full read access to their own profile and branch assignments.

---

## 5. Request Payload Specification

- **Method**: `POST`
- **Headers**:
  - `Authorization: Bearer <owner_access_token>`
  - `Content-Type: application/json`
- **Body**:
  ```json
  {
    "name": "Sarah Connor",
    "email": "sarah@company.com",
    "password": "SecretPassword123",
    "phone": "+1 555-0199",
    "userId": "sarahc",
    "selectedBusinessIds": ["branch-uuid-1", "branch-uuid-2"],
    "permissions": ["view_tasks", "add_tasks"]
  }
  ```

- **Success Response (201 Created)**:
  ```json
  {
    "success": true,
    "authUserId": "auth-uuid",
    "userId": "public-users-uuid",
    "message": "Staff account created successfully"
  }
  ```

- **Error Response (400 / 401 / 403 / 500)**:
  ```json
  {
    "error": "A user with this email address already exists."
  }
  ```
