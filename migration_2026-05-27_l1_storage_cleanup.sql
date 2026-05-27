-- L1-5 cleanup: drop legacy broad UPDATE/DELETE policies that still allow signed/ modification
DROP POLICY IF EXISTS "wm-signatures anyone update" ON storage.objects;
DROP POLICY IF EXISTS "wm-signatures admin delete" ON storage.objects;

-- Verify final policy set
SELECT polname, polcmd FROM pg_policy
WHERE polrelid = 'storage.objects'::regclass
  AND polname LIKE '%wm-signatures%' OR polname LIKE 'wm_sig%'
ORDER BY polname;
