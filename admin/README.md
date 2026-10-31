# BinerMention Admin
Independent Next.js static-export panel at https://binercraft.ir/madmin/

## Build
`npm install && npm run typecheck && npm run build`; output is in `out/`. Upload the contents of out to the cPanel document root for /madmin/.

## Database
1. Back up the current MariaDB database.
2. Import `admin/admin-schema.sql` AFTER the existing `PHP-API/schema.sql`.
3. Promote an existing account:
```sql
INSERT INTO admin_roles(user_id,role,is_active)
SELECT id,'owner',1 FROM users WHERE username='YOUR_EXISTING_USERNAME'
ON DUPLICATE KEY UPDATE role='owner',is_active=1;
```
4. Deploy `PHP-API/admin.php` and the updated `.htaccess` to the existing API document root.
5. Add `https://binercraft.ir` to `allowed_origins` in private `config.local.php`.
6. Upload the admin DIST contents to /madmin/.

Admin login verifies the existing password hash and an active admin_roles row. Passwords cannot be read; reset writes a new hash and revokes sessions. User disable stores a profile snapshot and disables the account instead of deleting it. Mutations are recorded in admin_audit_logs.
