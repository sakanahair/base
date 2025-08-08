'use client';

import Link from "next/link";
import { useState } from "react";

export default function Home() {
  const [isFlutterLoaded, setIsFlutterLoaded] = useState(false);

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-7xl mx-auto">
        <div className="text-center">
          <h1 className="text-4xl font-bold text-gray-900 sm:text-5xl md:text-6xl">
            Flutter + Next.js
          </h1>
          <p className="mt-3 max-w-md mx-auto text-base text-gray-500 sm:text-lg md:mt-5 md:text-xl md:max-w-3xl">
            マルチプラットフォーム対応のFlutterアプリとNext.jsの統合環境
          </p>
        </div>

        <div className="mt-10 grid grid-cols-1 gap-8 sm:grid-cols-2 lg:grid-cols-3">
          <div className="bg-white overflow-hidden shadow rounded-lg">
            <div className="px-4 py-5 sm:p-6">
              <h3 className="text-lg font-medium text-gray-900">Flutter Web App</h3>
              <p className="mt-2 text-sm text-gray-500">
                Flutter で作成したWebアプリケーション
              </p>
              <div className="mt-3">
                <Link
                  href="/app/"
                  className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700"
                  onClick={() => setIsFlutterLoaded(true)}
                >
                  Flutter アプリを開く
                </Link>
              </div>
            </div>
          </div>

          <div className="bg-white overflow-hidden shadow rounded-lg">
            <div className="px-4 py-5 sm:p-6">
              <h3 className="text-lg font-medium text-gray-900">Web Terminal</h3>
              <p className="mt-2 text-sm text-gray-500">
                ブラウザ内で動作するターミナル
              </p>
              <div className="mt-3">
                <Link
                  href="/terminal"
                  className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-green-600 hover:bg-green-700"
                >
                  ターミナルを開く
                </Link>
              </div>
            </div>
          </div>

          <div className="bg-white overflow-hidden shadow rounded-lg">
            <div className="px-4 py-5 sm:p-6">
              <h3 className="text-lg font-medium text-gray-900">Build Status</h3>
              <p className="mt-2 text-sm text-gray-500">
                ビルドとデプロイメントの状態
              </p>
              <div className="mt-3">
                <span className={`inline-flex items-center px-3 py-0.5 rounded-full text-sm font-medium ${
                  isFlutterLoaded ? 'bg-green-100 text-green-800' : 'bg-yellow-100 text-yellow-800'
                }`}>
                  {isFlutterLoaded ? 'Flutter Loaded' : 'Ready'}
                </span>
              </div>
            </div>
          </div>
        </div>

        <div className="mt-10 bg-white shadow rounded-lg">
          <div className="px-4 py-5 sm:p-6">
            <h3 className="text-lg font-medium text-gray-900 mb-4">デプロイメント情報</h3>
            <dl className="grid grid-cols-1 gap-x-4 gap-y-6 sm:grid-cols-2">
              <div>
                <dt className="text-sm font-medium text-gray-500">Flutter Web ビルドパス</dt>
                <dd className="mt-1 text-sm text-gray-900">/public/app/</dd>
              </div>
              <div>
                <dt className="text-sm font-medium text-gray-500">Next.js ビルド出力</dt>
                <dd className="mt-1 text-sm text-gray-900">/dist/</dd>
              </div>
              <div>
                <dt className="text-sm font-medium text-gray-500">ビルドコマンド</dt>
                <dd className="mt-1 text-sm text-gray-900 font-mono">npm run build:all</dd>
              </div>
              <div>
                <dt className="text-sm font-medium text-gray-500">開発サーバー</dt>
                <dd className="mt-1 text-sm text-gray-900 font-mono">npm run dev</dd>
              </div>
            </dl>
          </div>
        </div>
      </div>
    </div>
  );
}