#!/bin/bash
# 로컬 파일(csv)들을 한번에 influxDB에 올리는 코드

INFLUX_BUCKET="sensor_data"
INFLUX_ORG="hyeyoom"
INFLUX_TOKEN="changeme" # 토큰 입력하세요
DATA_DIR="changeme" # 데이터파일(csv)들이 들어있는 폴더 경로 입력하세요 - 주의) 파일들은 모두 UTF-8 인코딩이어야 합니다.
FILE_EXTENSION_SENSOR="_센서측정정보.csv"
FILE_EXTENSION_EVENT="_대상자실시간이벤트.csv"
TEMP_FILE="/tmp/influx_data.csv"

# 센서 데이터 파일 업로드
upload_sensor_data() {
  local file="$1"
  local user_name="$2"

  local sensor_type=$(echo "$file" | grep -oP '(?<=_)[^_]*(?=_센서측정정보\.csv)')

  echo "user_name,sensor_id,sensor_type_code,sensor_type_name,measurement_time,measurement_value,test_status,registration_time,activity_distance,activity_angle,detected_people,sensor_alias,x_coordinate,y_coordinate,human_detection_status" > "$TEMP_FILE"

  while IFS=',' read -r sensor_id sensor_type_code sensor_type_name measurement_time measure_value test_status registration_time activity_distance activity_angle detected_people sensor_alias x_coordinate y_coordinate human_detection_status
  do
    if [[ "$measure_value" == *,* ]]; then
      IFS=',' read -ra values <<< "$measure_value"

      start_time=$(date -u -d "$measurement_time -59 minutes" +"%Y-%m-%dT%H:%M:%SZ")

      for i in "${!values[@]}"
      do
        current_time=$(date -u -d "$start_time +${i} minutes" +"%Y-%m-%dT%H:%M:%SZ")
        value="${values[i]}"

        if [[ "$value" =~ ^[+-]?[0-9]*\.?[0-9]+$ ]]; then
          echo "$user_name,$sensor_id,$sensor_type_code,$sensor_type_name,$current_time,$value,$test_status,$registration_time,$activity_distance,$activity_angle,$detected_people,$sensor_alias,$x_coordinate,$y_coordinate,$human_detection_status" >> "$TEMP_FILE"
        fi
      done
    else
      if [[ "$measure_value" =~ ^[+-]?[0-9]*\.?[0-9]+$ ]]; then
        echo "$user_name,$sensor_id,$sensor_type_code,$sensor_type_name,$measurement_time,$measure_value,$test_status,$registration_time,$activity_distance,$activity_angle,$detected_people,$sensor_alias,$x_coordinate,$y_coordinate,$human_detection_status" >> "$TEMP_FILE"
      fi
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

# 이벤트 데이터 파일 업로드
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

  if [[ "$filename" == *"$FILE_EXTENSION_SENSOR" ]]; then
    echo "Uploading sensor data for $user_name from $file..."
    upload_sensor_data "$file" "$user_name"
  elif [[ "$filename" == *"$FILE_EXTENSION_EVENT" ]]; then
    echo "Uploading event data for $user_name from $file..."
    upload_event_data "$file" "$user_name"
  fi
done

echo "Data upload complete!"

