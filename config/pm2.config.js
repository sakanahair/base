// PM2設定ファイル
// Usage: pm2 start config/pm2.config.js

module.exports = {
  apps: [
    {
      name: 'sakana-next',
      script: 'npm',
      args: 'start',
      cwd: '/var/www/sakana/next',
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: '1G',
      env: {
        NODE_ENV: 'production',
        PORT: 3000,
      },
      env_development: {
        NODE_ENV: 'development',
        PORT: 3000,
      },
      error_file: '/var/www/sakana/logs/pm2-error.log',
      out_file: '/var/www/sakana/logs/pm2-out.log',
      log_file: '/var/www/sakana/logs/pm2-combined.log',
      time: true,
      merge_logs: true,
      
      // クラッシュ時の再起動設定
      min_uptime: '10s',
      max_restarts: 10,
      
      // グレースフルシャットダウン
      kill_timeout: 5000,
      
      // ヘルスチェック
      health_check: {
        interval: 30000,
        url: 'http://localhost:3000/api/health',
        max_consecutive_failures: 3,
      },
    },
  ],

  // デプロイ設定
  deploy: {
    production: {
      user: 'root',
      host: 'beta.reboot47',
      ref: 'origin/master',
      repo: 'https://github.com/sakanahair/base.git',
      path: '/var/www/sakana',
      'post-deploy': 'cd next && npm install && npm run build && pm2 reload sakana-next',
    },
  },
};