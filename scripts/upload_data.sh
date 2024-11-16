#!/bin/bash
# 시크릿 파일 경로
TOKEN_FILE="/run/secrets/influxdb2-admin-token"

# 시크릿 파일이 존재하는지 확인
if [ -f "$TOKEN_FILE" ]; then
  # 시크릿 파일에서 토큰 읽기
  INFLUX_TOKEN=$(cat "$TOKEN_FILE")
else
  echo "시크릿 파일을 찾을 수 없습니다: $TOKEN_FILE"
  exit 1
fi

INFLUX_BUCKET="sensor_data" # 사용 중인 버킷 이름
INFLUX_ORG="hyeyoom"       # 조직 이름
DATA_DIR="/data" # 데이터 파일 경로
FILE_EXTENSION_SENSOR="_센서측정정보.csv"
FILE_EXTENSION_EVENT="_대상자실시간이벤트.csv"
EXCLUDE_PATTERNS=("_심박_센서측정정보.csv" "_호흡_센서측정정보.csv")
TEMP_FILE="/tmp/influx_data.csv"

upload_sensor_data() {
  local file="$1"
  local user_name="$2"

  local sensor_type=$(echo "$file" | grep -oP '(?<=_)[^_]*(?=_센서측정정보\.csv)')

  echo "user_name,sensor_id,sensor_type_code,sensor_type_name,measurement_time,measurement_value,test_status,registration_time,activity_distance,activity_angle,detected_people,sensor_alias,x_coordinate,y_coordinate,human_detection_status" > "$TEMP_FILE"

  while IFS=',' read -r sensor_id sensor_type_code sensor_type_name measurement_time measure_value test_status registration_time activity_distance activity_angle detected_people sensor_alias x_coordinate y_coordinate human_detection_status
  do
    if [[ "$measure_value" =~ ^[+-]?[0-9]*\.?[0-9]+$ ]]; then
      echo "$user_name,$sensor_id,$sensor_type_code,$sensor_type_name,$measurement_time,$measure_value,$test_status,$registration_time,$activity_distance,$activity_angle,$detected_people,$sensor_alias,$x_coordinate,$y_coordinate,$human_detection_status" >> "$TEMP_FILE"
    fi
  done < "$file"

  influx write \
    -b "$INFLUX_BUCKET" \
    -o "$INFLUX_ORG" \
    -t "$INFLUX_TOKEN" \
    --skipHeader 1 \
    --header "#constant measurement,$sensor_type" \
    --header "#datatype tag,tag,tag,tag,dateTime:RFC3339,double,string,string,double,double,long,tag,double,double,string" \
    --header "user_name,sensor_id,sensor_type_code,sensor_type_name,measurement_time,measurement_value,test_status,registration_time,activity_distance,activity_angle,detected_people,sensor_alias,x_coordinate,y_coordinate,human_detection_status" \
    -f "$TEMP_FILE"
}

upload_event_data() {
  local file="$1"
  local user_name="$2"

  influx write \
    -b "$INFLUX_BUCKET" \
    -o "$INFLUX_ORG" \
    -t "$INFLUX_TOKEN" \
    --skipHeader 1 \
    --header "#constant measurement,${user_name}_events" \
    --header "#datatype tag,tag,string,string,dateTime:RFC3339,string" \
    --header "user_name,subject_id,subject_name,event_code,event_description,event_time,registration_time" \
    -f "$file"
}

for file in "$DATA_DIR"/*.csv; do
  filename=$(basename -- "$file")
  user_name=$(echo "$filename" | cut -d'_' -f1)

  skip=false
  for pattern in "${EXCLUDE_PATTERNS[@]}"; do
    if [[ "$filename" == *"$pattern" ]]; then
      skip=true
      break
    fi
  done

  if [ "$skip" = false ]; then
    if [[ "$filename" == *"$FILE_EXTENSION_SENSOR" ]]; then
      echo "Uploading sensor data for $user_name from $file..."
      upload_sensor_data "$file" "$user_name"
    elif [[ "$filename" == *"$FILE_EXTENSION_EVENT" ]]; then
      echo "Uploading event data for $user_name from $file..."
      upload_event_data "$file" "$user_name"
    fi
  else
    echo "Skipping file $filename (excluded pattern)"
  fi
done

echo "Data upload complete!"
