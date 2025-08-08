import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

// ドメインとパスのマッピング
const domainMappings: Record<string, string> = {
  'morishita.yourdomain.com': '/morishita',
  'app.yourdomain.com': '/app',
  'terminal.yourdomain.com': '/terminal',
  'project-a.yourdomain.com': '/project-a',
  'client.yourdomain.com': '/client',
  // 追加のドメインマッピングをここに記載
};

export function middleware(request: NextRequest) {
  // ホスト名を取得
  const hostname = request.headers.get('host') || '';
  
  // 開発環境では localhost を除外
  if (hostname.includes('localhost')) {
    return NextResponse.next();
  }
  
  // ドメインに基づいてパスをリライト
  const mappedPath = domainMappings[hostname];
  
  if (mappedPath) {
    // URLを構築
    const url = request.nextUrl.clone();
    
    // パスが既にマップされたパスで始まっていない場合のみリライト
    if (!url.pathname.startsWith(mappedPath)) {
      url.pathname = `${mappedPath}${url.pathname}`;
      return NextResponse.rewrite(url);
    }
  }
  
  // カスタムヘッダーを追加（オプション）
  const response = NextResponse.next();
  
  // Flutter Web用のCORSヘッダー
  if (request.nextUrl.pathname.startsWith('/app')) {
    response.headers.set('Cross-Origin-Embedder-Policy', 'require-corp');
    response.headers.set('Cross-Origin-Opener-Policy', 'same-origin');
  }
  
  return response;
}

// ミドルウェアを適用するパスを設定
export const config = {
  matcher: [
    /*
     * Match all request paths except for the ones starting with:
     * - api (API routes)
     * - _next/static (static files)
     * - _next/image (image optimization files)
     * - favicon.ico (favicon file)
     */
    '/((?!api|_next/static|_next/image|favicon.ico).*)',
  ],
};