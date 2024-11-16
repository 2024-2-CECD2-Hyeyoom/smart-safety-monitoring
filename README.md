# 차세대 응급 안전 시스템

---

## Getting Started

Docker

docker-compose

### 1. Docker desktop에서 Git bash 열고 다음을 입력
```bash
git clone https://github.com/2024-2-CECD2-Hyeyoom/smart-safety-monitoring.git
cd smart-safety-monitoring

echo "hy" > ~/.env.influxdb2-admin-username  
echo "hy12345678" > ~/.env.influxdb2-admin-password
echo $(openssl rand -base64 32) > ~/.env.influxdb2-admin-token
```

### 2. docker-compose.yml 수정
```bash


```

### 3. 도커 이미지 pull하고 실행
```bash
docker pull seohee0348/hy_influxdb:latest

docker-compose up -d
```

** 만약 오류 나서 다시 실행해야 하는 경우 도커 volume을 모두 삭제해야 함.
