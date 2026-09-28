# Thông Tin Deploy — Checkpoint 5

> Điền file này sau khi deploy xong. `pytest tests/test_cp5.py` đọc file này
> để tìm địa chỉ service của bạn và gọi thử.
>
> **Chỉ ghi TÊN biến môi trường, tuyệt đối không dán giá trị API key vào đây.**
> Repo này công khai — dán khóa vào là mất khóa.

## Thông Tin Học Viên

| Mục | Nội dung |
|-----|----------|
| Họ và tên | Le Duy Quan |
| Mã học viên | 2A202602731 |
| Repo | https://github.com/LeDuyQuan1911/K4-L3A-DAY12-LeDuyQuan-L3A202602731-CloudServicesAndDeployment |

## Service

| Mục | Nội dung |
|-----|----------|
| Public URL | http://localhost:8000 (local fallback) |
| Platform | Docker Compose (local fallback) |
| Ngày deploy | 2026-09-28 |

## Biến Môi Trường Đã Set Trên Cloud

Ghi tên biến và **nguồn giá trị**, không ghi giá trị:

| Biến | Đã set | Ghi chú |
|------|--------|---------|
| `PORT` | ✅ | 8000 (mặc định) |
| `AGENT_API_KEY` | ✅ | đặt trong file .env, không nằm trong repo |
| `REDIS_URL` | ✅ | redis://redis:6379/0 (Redis container trong Docker Compose) |
| `RATE_LIMIT_PER_MINUTE` | ✅ | 10 |
| `MONTHLY_BUDGET_USD` | ✅ | 10.0 |
| `LOG_LEVEL` | ✅ | INFO |

## Lệnh Kiểm Tra

```bash
# 1. Liveness — mong đợi 200 {"status":"ok"}
curl -i http://localhost:8000/health

# 2. Readiness — mong đợi 200 {"status":"ready"} (đã nối được Redis)
curl -i http://localhost:8000/ready

# 3. Không có API key — mong đợi 401
curl -i -X POST http://localhost:8000/ask \
  -H "Content-Type: application/json" \
  -d '{"question":"Hello"}'

# 4. Có API key — mong đợi 200 kèm câu trả lời
curl -i -X POST http://localhost:8000/ask \
  -H "Content-Type: application/json" \
  -H "X-API-Key: $AGENT_API_KEY" \
  -H "X-User-Id: sv-test" \
  -d '{"question":"Deploy là gì?"}'
```

## Kết Quả Chạy Thật

```
HTTP/1.1 200 OK
{"status":"ok","service":"day12-agent","version":"1.0.0"}

HTTP/1.1 200 OK
{"status":"ready","redis":true}

HTTP/1.1 401 Unauthorized
{"detail":"invalid or missing API key"}

HTTP/1.1 200 OK
{"answer":"...","user_id":"sv-test","history_length":0,"cost_usd":...,"tokens":{"in":...,"out":...}}
```

## Ảnh Chụp Màn Hình

Đặt ảnh trong thư mục `screenshots/`:

- `screenshots/docker_compose_ps.png` — kết quả `docker compose ps`
- `screenshots/health.png` — kết quả gọi `/health`

---

## Nếu Dùng Phương Án Dự Phòng

```
Sử dụng phương án dự phòng LOCAL_FALLBACK=true vì chưa có tài khoản cloud platform (Railway/Render).
Ứng dụng chạy trên Docker Compose tại localhost:8000 với Redis container.
Tất cả các checkpoint CP1-CP4 đều pass đầy đủ.
```
