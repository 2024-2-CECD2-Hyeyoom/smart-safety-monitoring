# 차세대 응급 안전 시스템

---

## Getting Started

Docker

docker-compose

### 1. Docker desktop에서 Git bash 열고 다음을 입력
```bash
git clone https://github.com/2024-2-CECD2-Hyeyoom/smart-safety-monitoring.git
cd smart-safety-monitoring

// 스크립트 CRLF --> LF 형식으로 전환
awk '{ sub("\r$", ""); print }' scripts/upload_data.sh > scripts/upload_data_unix.sh
mv scripts/upload_data_unix.sh scripts/upload_data.sh

awk '{ sub("\r$", ""); print }' scripts/upload_hr_rp_data.sh > scripts/upload_hr_rp_data_unix.sh
mv scripts/upload_hr_rp_data_unix.sh scripts/upload_hr_rp_data.sh

echo "hy" > ~/.env.influxdb2-admin-username  
echo "hy12345678" > ~/.env.influxdb2-admin-password
echo $(openssl rand -base64 32) > ~/.env.influxdb2-admin-token

# 실행 권한 추가
chmod +x scripts/upload_data.sh
chmod +x scripts/upload_hr_rp_data.sh
```

### 2. docker-compose.yml 수정
```
- type: bind
  source: ~/Dev/sample_data_csv/modified_sample_data # 이 부분을 자기 로컬에 다운받은 데이터 폴더 경로를 넣어줘야 함 ** 경로 주의해서 넣기!
  target: /data  

```

### 3. 도커 이미지 pull하고 실행
```bash
docker pull seohee0348/hy_influxdb:latest

docker-compose up -d
```

### 4. influxdb 실행
http://localhost:8086

시간 설정 (2024/08/11 ~ 2024/08/24)

** 만약 오류 나서 다시 실행해야 하는 경우 도커 volume을 모두 삭제해야 함.
