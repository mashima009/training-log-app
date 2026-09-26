# Training Log

スマホで使える個人向けトレーニング記録アプリです。静的なHTMLとして動作し、初期状態ではブラウザのlocalStorageへ保存します。Supabaseを設定すると、同じデータをクラウドへ同期できます。

## ローカル確認

```powershell
cd C:\Users\mashi\training-log-app
python -m http.server 8000
```

ブラウザで `http://localhost:8000/training-log-app/` を開きます。PWAとService Workerは、`file://` ではなくHTTP経由でのみ動作します。

## Supabase本番接続

1. Supabaseでプロジェクトを作成します。
2. SQL Editorで `supabase/schema.sql` を実行します。
3. Project Settings > APIからProject URLとanon keyを取得します。
4. アプリの「アカウント」>「Supabase接続」に入力して保存します。
5. 同じ画面の「アカウント登録・ログイン」からメールアドレスとパスワードで登録します。
6. ログイン後のトレーニング記録・食事記録・身体データは、Supabase Authのユーザー単位で分離されます。

anon keyはクライアント公開用のキーです。service_role keyは絶対に入力しないでください。Supabase Dashboardの Authentication > Providers で Email providerを有効にしてください。

以前のバージョンで作成したSupabase上の `personal-user` の記録は、自動ではアカウントへ割り当てません。これらが自分の記録であることを確認したうえで、SupabaseのAuthentication > Usersから対象アカウントのUIDを取得し、SQL Editorで `<USER_UUID>` を置き換えて実行してください。

```sql
update public.workouts set user_id = '<USER_UUID>' where user_id = 'personal-user';
update public.workout_sets set user_id = '<USER_UUID>' where user_id = 'personal-user';
update public.body_metrics set user_id = '<USER_UUID>' where user_id = 'personal-user';
```

ブラウザ内に保存されている旧データは、ログイン時に確認が表示され、了承した場合のみアカウント用の領域へコピーされます。

## Vercel公開

### GitHub経由

1. このフォルダーをGitHubリポジトリへpushします。
2. Vercelで「Add New Project」>対象リポジトリを選びます。
3. Framework Presetは `Other`、Build Commandは空欄、Output Directoryは `.` にします。
4. Deployを実行します。

### Vercel CLI

```powershell
npm install --global vercel
cd C:\Users\mashi\training-log-app
vercel
vercel --prod
```

公開後のURLをスマホで開き、ブラウザの「ホーム画面に追加」を選ぶとPWAとして利用できます。

## ファイル構成

- `index.html` - アプリ本体
- `manifest.webmanifest` - PWA設定
- `sw.js` - オフライン用Service Worker
- `icon.svg` - アプリアイコン
- `vercel.json` - Vercelの配信設定
- `supabase/schema.sql` - Supabaseのテーブルとインデックス
