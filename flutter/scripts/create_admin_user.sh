#!/bin/bash

# Firebase CLIを使ってadmin@sakana.hairユーザーを作成
# プロジェクト: sakana

echo "Creating admin user for Firebase project 'sakana'..."

# プレーンテキストパスワードをBase64エンコード（簡易的な方法）
# 注意: これは本番環境では推奨されません。Firebaseコンソールから作成するのが最も安全です。

cat > admin_users.json << EOF
{
  "users": [
    {
      "uid": "admin_sakana_001",
      "email": "admin@sakana.hair",
      "emailVerified": true,
      "password": "Pass12345",
      "displayName": "Admin User",
      "disabled": false
    }
  ]
}
EOF

echo "Importing user to Firebase..."
firebase auth:import admin_users.json --project sakana

echo "Done! You can now login with:"
echo "Email: admin@sakana.hair"
echo "Password: Pass12345"

# Clean up
rm admin_users.json