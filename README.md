


# 차세대 응급안전 시스템 구축

Docker

Docker compose 

Ubuntu


## ⚡️ Getting Started

1. Ubuntu 실행 후 해당 프로젝트 깃 클론

```bash
git clone https://github.com/2024-2-CECD2-Hyeyoom/smart-safety-monitoring.git
```

2. tick-stack 디렉터리로 이동

```bash
cd tig-stack
```

3. IDE 열기
```bash
code .
```

4. .env 환경변수 설정(아이디, 비밀번호, API토큰)
```bash
├── telegraf/
├── .env         <---
├── docker-compose.yml
├── entrypoint.sh
└── ...
```

5. 다시 우분투 터미널 창으로 돌아와서 해당 명령어 입력하여 서비스 시작
```bash
docker-compose up -d
```

만약 권한 문제 생기면 터미널 창에 다음을 입력하세요.
```bash
export INFLUX_TOKEN=my_token
export INFLUX_ORG=my_org
export INFLUX_BUCKET=my_bucket
```

6. InfluxDB
- URL: http://localhost:8086
- Organization : hyeyoom
- Bucket : sensor_data
- 2024/08/11 ~ 2024/08/25 시간 설정 후 조회해야 됩니다.
- 
![스크린샷(113)](https://github.com/user-attachments/assets/1d1f17f3-501c-48e2-8504-8f2ca44b2a7d)


7. Grafana
- URL: http://localhost:3000
- Username: admin
- Password: admin
- 추후 password 변경할 수 있습니다.


## Docker Images Used (Official & Verified)

[**Telegraf**](https://hub.docker.com/_/telegraf) / `1.19`

[**InfluxDB**](https://hub.docker.com/_/influxdb) / `2.1.1`

[**Grafana-OSS**](https://hub.docker.com/r/grafana/grafana-oss) / `8.4.3`


