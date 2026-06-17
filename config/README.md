# Huong Dan Cau Hinh OpenClaw

Thu muc nay chua cac file cau hinh cho OpenClaw. Chinh sua cac file nay truoc khi chay install.bat.

---

## llm_config.json — Cau hinh LLM (Mo hinh ngon ngu lon)

| Truong | Kieu du lieu | Bat buoc | Mo ta |
|--------|-------------|----------|-------|
| `provider` | string | Co | Nha cung cap LLM. Gia tri hop le: `anthropic`, `openai`, `google`, `xai`, `mistral`, `groq` |
| `model` | string | Co | Ten mo hinh. Vi du: `claude-sonnet-4-6`, `gpt-4o`, `gemini-2.0-flash` |
| `api_key` | string | Co | API key tu nha cung cap. QUAN TRONG: khong chia se key nay |
| `base_url` | string | Khong | URL tuy chinh cho model tu host (de trong neu dung cloud) |
| `fallback_provider` | string | Khong | Nha cung cap du phong khi provider chinh loi |
| `fallback_model` | string | Khong | Mo hinh du phong |
| `fallback_api_key` | string | Khong | API key du phong |
| `max_tokens` | number | Khong | So token toi da moi lan tra loi (mac dinh: 8192) |
| `temperature` | number | Khong | Do sang tao (0.0 = chinh xac, 1.0 = sang tao; mac dinh: 1.0) |

### Vi du cau hinh voi Anthropic Claude:
```json
{
  "provider": "anthropic",
  "model": "claude-sonnet-4-6",
  "api_key": "sk-ant-api03-xxxxx",
  "base_url": "",
  "max_tokens": 8192,
  "temperature": 1.0
}
```

### Vi du cau hinh voi OpenAI:
```json
{
  "provider": "openai",
  "model": "gpt-4o",
  "api_key": "sk-xxxxx",
  "base_url": "",
  "max_tokens": 8192,
  "temperature": 1.0
}
```

### Vi du cau hinh voi mo hinh tu host (Ollama, LM Studio):
```json
{
  "provider": "openai",
  "model": "llama3.2",
  "api_key": "ollama",
  "base_url": "http://localhost:11434/v1",
  "max_tokens": 4096,
  "temperature": 0.8
}
```

---

## bot_config.json — Cau hinh hanh vi bot

| Truong | Kieu du lieu | Bat buoc | Mo ta |
|--------|-------------|----------|-------|
| `bot_name` | string | Khong | Ten hien thi cua bot (mac dinh: "OpenClaw") |
| `language` | string | Khong | Ngon ngu giao tiep. Vi du: `vi` (tieng Viet), `en` (tieng Anh) |
| `dm_policy` | string | Khong | Chinh sach tin nhan rieng tu: `pairing` (can xac nhan), `allowlist` (danh sach trang), `open` (mo), `disabled` (tat) |
| `group_policy` | string | Khong | Chinh sach nhom chat: `disabled`, `open`, `allowlist` |
| `allow_from` | array | Khong | Danh sach ID nguoi dung duoc phep nhan tin (de trong = tat ca) |
| `workspace` | string | Khong | Thu muc workspace cho agent (de trong = mac dinh: ~/.openclaw/workspace) |
| `agent_id` | string | Khong | ID cua agent chinh (mac dinh: "main") |

### Vi du:
```json
{
  "bot_name": "Tro Ly AI",
  "language": "vi",
  "dm_policy": "pairing",
  "group_policy": "disabled",
  "allow_from": [],
  "workspace": "",
  "agent_id": "main"
}
```

---

## app_config.json — Cau hinh ung dung

| Truong | Kieu du lieu | Bat buoc | Mo ta |
|--------|-------------|----------|-------|
| `gateway_port` | number | Khong | Cong gateway HTTP (mac dinh: 18789) |
| `gateway_host` | string | Khong | Dia chi gateway (mac dinh: "127.0.0.1" = chi may nha) |
| `auto_install_daemon` | boolean | Khong | Tu dong cai daemon khi khoi dong (mac dinh: false) |
| `verbose` | boolean | Khong | Hien thi thong tin chi tiet (mac dinh: false) |
| `log_level` | string | Khong | Muc do ghi log: `debug`, `info`, `warn`, `error` (mac dinh: "info") |
| `control_ui_enabled` | boolean | Khong | Bat giao dien quan ly tai http://127.0.0.1:18789 (mac dinh: true) |
| `sandbox_mode` | string | Khong | Che do sandbox: `off`, `non-main`, `all` (mac dinh: "off") |
| `remote_access` | boolean | Khong | Cho phep truy cap tu xa (mac dinh: false) |

### Vi du mo cong cho mang LAN:
```json
{
  "gateway_port": 18789,
  "gateway_host": "0.0.0.0",
  "verbose": false,
  "log_level": "info"
}
```

---

## paths.json — Cau hinh duong dan

| Truong | Kieu du lieu | Mo ta |
|--------|-------------|-------|
| `openclaw_config_dir` | string | Thu muc cau hinh OpenClaw (de trong = mac dinh: %USERPROFILE%\.openclaw) |
| `workspace_dir` | string | Thu muc workspace cua agent (de trong = mac dinh: %USERPROFILE%\.openclaw\workspace) |
| `logs_dir` | string | Thu muc luu log cuc bo (mac dinh: "logs") |
| `data_dir` | string | Thu muc luu du lieu (mac dinh: "data") |
| `backups_dir` | string | Thu muc luu ban backup (mac dinh: "backups") |

---

## Luu y bao mat

- **Khong commit** file `llm_config.json` vao git neu co chua API key that.
- Xem file `.gitignore` de dam bao cac file nhay cam khong bi commit.
- API key da duoc them vao `.gitignore` tu dong.
