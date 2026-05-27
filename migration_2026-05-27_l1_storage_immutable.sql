-- L1-5: Storage immutability for signed/ path
-- Final signed PDFs and signature images must be insert-only.
-- Once uploaded under wm-signatures/signed/*, they cannot be updated or deleted via anon/auth role.

-- Drop existing broad policies that allow UPDATE/DELETE on the bucket
DROP POLICY IF EXISTS "wm_sig_anon_update" ON storage.objects;
DROP POLICY IF EXISTS "wm_sig_auth_delete" ON storage.objects;

-- Recreate narrow UPDATE/DELETE policies that EXCLUDE the signed/ path
CREATE POLICY "wm_sig_anon_update_nonsigned"
  ON storage.objects FOR UPDATE
  TO anon
  USING (bucket_id = 'wm-signatures' AND name NOT LIKE 'signed/%')
  WITH CHECK (bucket_id = 'wm-signatures' AND name NOT LIKE 'signed/%');

CREATE POLICY "wm_sig_auth_delete_nonsigned"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (bucket_id = 'wm-signatures' AND name NOT LIKE 'signed/%');

-- Audit log: read-only via anon (insert allowed), no update/delete
-- (table created already with RLS on wm_contract_audit)
DROP POLICY IF EXISTS "wm_contract_audit_anon_insert" ON wm_contract_audit;
DROP POLICY IF EXISTS "wm_contract_audit_anon_select" ON wm_contract_audit;

CREATE POLICY "wm_contract_audit_anon_insert"
  ON wm_contract_audit FOR INSERT
  TO anon, authenticated
  WITH CHECK (true);

CREATE POLICY "wm_contract_audit_anon_select"
  ON wm_contract_audit FOR SELECT
  TO anon, authenticated
  USING (true);

-- OTP table policies (insert/select only, marked used via update)
DROP POLICY IF EXISTS "wm_otp_codes_anon_all" ON wm_otp_codes;

CREATE POLICY "wm_otp_codes_anon_insert"
  ON wm_otp_codes FOR INSERT
  TO anon, authenticated
  WITH CHECK (true);

CREATE POLICY "wm_otp_codes_anon_select"
  ON wm_otp_codes FOR SELECT
  TO anon, authenticated
  USING (true);

CREATE POLICY "wm_otp_codes_anon_update"
  ON wm_otp_codes FOR UPDATE
  TO anon, authenticated
  USING (true)
  WITH CHECK (true);

-- Verify
SELECT polname, polcmd FROM pg_policy
WHERE polrelid = 'storage.objects'::regclass
  AND polname LIKE 'wm_sig%';
