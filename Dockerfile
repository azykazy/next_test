# ベースステージ
FROM node:18-alpine AS base

# 依存関係インストールステージ
FROM base AS deps
RUN apk add --no-cache libc6-compat
WORKDIR /app

COPY package*.json ./
RUN npm ci

# ビルダーステージ
FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .

RUN npm run build

# 実行ステージ
FROM base AS runner
WORKDIR /app

ENV NODE_ENV production

# 非root実行のためのユーザー作成
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

# 静的ファイルのコピー
COPY --from=builder /app/public ./public

# 適切な権限設定
RUN mkdir .next
RUN chown nextjs:nodejs .next

# ビルド成果物のコピー
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

# 非root実行ユーザーに切り替え
USER nextjs

EXPOSE 3000

ENV PORT 3000
ENV HOSTNAME "0.0.0.0"

CMD ["node", "server.js"] 