# MaMa — Continuous Parenthood Journey

[![CI](https://github.com/yerenkanat/MaMaHealth/actions/workflows/ci.yml/badge.svg)](https://github.com/yerenkanat/MaMaHealth/actions/workflows/ci.yml)

Кроссплатформенное приложение экосистемы непрерывного родительства: трекинг беременности
по неделям, календарь развития ребёнка, умные медицинские нотификации, телемедицина и
экстренная геолокация.

## Монорепозиторий

| Пакет         | Стек                          | Назначение                                        |
|---------------|-------------------------------|---------------------------------------------------|
| `app/`        | Flutter + BLoC                | Мобильный клиент (iOS/Android)                     |
| `api/`        | Node.js + TypeScript + Express| REST API, авторизация, BOLA/IDOR-guard            |
| `worker/`     | Node.js + TypeScript + BullMQ | Data-Driven медицинский планировщик пушей         |
| `migrations/` | PostgreSQL 15 SQL             | Схема БД, partial-индексы, seed медпротоколов     |

## Быстрый старт (dev)

```bash
cp .env.example .env
docker compose up -d db redis          # поднять PostgreSQL + Redis
docker compose run --rm migrate        # применить миграции
docker compose up api worker           # API :8080, воркер по cron

# Flutter-клиент
cd app && flutter pub get && flutter run
```

## Аутентификация

JWT выдаётся при регистрации/логине; клиент хранит его в `flutter_secure_storage`
и шлёт как `Authorization: Bearer <token>`.

```bash
# Регистрация
curl -X POST localhost:8080/auth/register -H 'Content-Type: application/json' \
  -d '{"email":"mom@mama.kz","fullName":"Айгуль","districtId":1,"password":"secret123"}'

# Логин
curl -X POST localhost:8080/auth/login -H 'Content-Type: application/json' \
  -d '{"email":"mom@mama.kz","password":"secret123"}'
# -> { "token": "eyJ..." }
```

Пароли хешируются через `scrypt` (встроенный `node:crypto`), сравнение —
в постоянное время (`timingSafeEqual`).

## Архитектура

```
Flutter (app) ──HTTPS──▶ API (api) ──SQL──▶ PostgreSQL
                              │
                              ▼
                       Redis (BullMQ) ◀── Worker (worker) ──cron──▶ FCM/APNs
```

## Ключевые инварианты

- **Идемпотентность воркера**: повторный запуск за день не дублирует уведомления
  (`UNIQUE (profile_id, protocol_id, fire_date)`).
- **Транзакционная миграция «Я родила!»**: создание ребёнка, архивация беременности и
  перегенерация расписания — в одной транзакции.
- **BOLA/IDOR-guard**: доступ врача к гео/медкарте только при активной связи
  `doctor_patient_links` и совпадении `district_id`.
