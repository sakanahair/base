#!/bin/bash

# Firebase CLIを使ってadmin@sakana.hairユーザーを作成するスクリプト
# 事前にfirebase login が必要です

echo "Creating admin user in Firebase Authentication..."

# Firebase CLIでユーザーを作成（この方法はFirebase CLIの機能によって異なる場合があります）
# 代替案：Firebase ConsoleのWebインターフェースから手動で作成

echo "手動でFirebase Consoleから以下のユーザーを作成してください："
echo "Email: admin@sakana.hair"
echo "Password: Pass12345"
echo ""
echo "手順："
echo "1. https://console.firebase.google.com/ にアクセス"
echo "2. sakana-adminプロジェクトを選択"
echo "3. Authentication > Users タブを開く"
echo "4. 'Add user' ボタンをクリック"
echo "5. Email: admin@sakana.hair, Password: Pass12345 を入力"
echo "6. 'Add user' をクリック"