INFLUX_BUCKET="changeme"
INFLUX_ORG="changeme"
INFLUX_TOKEN="changeme"
DATA_DIR="changeme"
TEMP_FILE="/tmp/influx_data.csv"
SENSOR_FILE_PATTERNS=("_심박_센서측정정보.csv" "_호흡_센서측정정보.csv")

upload_sensor_data() {
  local file="$1"
  local user_name="$2"
  local sensor_type=$(echo "$file" | grep -oP '(?<=_)[^_]*(?=_센서측정정보\.csv)')

  echo "user_name,sensor_id,sensor_type_code,sensor_type_name,measurement_time,measurement_value,test_status,registration_time,activity_distance,activity_angle,detected_people,sensor_alias,x_coordinate,y_coordinate,human_detection_status" > "$TEMP_FILE"

  while IFS=',' read -r sensor_id sensor_type_code sensor_type_name measurement_time \
      m1 m2 m3 m4 m5 m6 m7 m8 m9 m10 m11 m12 m13 m14 m15 m16 m17 m18 m19 m20 m21 m22 m23 m24 m25 m26 m27 m28 m29 m30 \
      m31 m32 m33 m34 m35 m36 m37 m38 m39 m40 m41 m42 m43 m44 m45 m46 m47 m48 m49 m50 m51 m52 m53 m54 m55 m56 m57 m58 m59 m60 \
      test_status registration_time activity_distance activity_angle detected_people sensor_alias x_coordinate y_coordinate human_detection_status
  do
    start_time=$(date -u -d "$measurement_time -59 minutes" +"%Y-%m-%dT%H:%M:%SZ")

    values=("$m1" "$m2" "$m3" "$m4" "$m5" "$m6" "$m7" "$m8" "$m9" "$m10" "$m11" "$m12" "$m13" "$m14" "$m15" "$m16" "$m17" "$m18" "$m19" "$m20" "$m21" "$m22" "$m23" "$m24" "$m25" "$m26" "$m27" "$m28" "$m29" "$m30" \
        "$m31" "$m32" "$m33" "$m34" "$m35" "$m36" "$m37" "$m38" "$m39" "$m40" "$m41" "$m42" "$m43" "$m44" "$m45" "$m46" "$m47" "$m48" "$m49" "$m50" "$m51" "$m52" "$m53" "$m54" "$m55" "$m56" "$m57" "$m58" "$m59" "$m60")
    
    for i in "${!values[@]}"; do
      current_time=$(date -u -d "$start_time +${i} minutes" +"%Y-%m-%dT%H:%M:%SZ")
      value="${values[i]}"

      if [[ "$value" =~ ^[+-]?[0-9]*\.?[0-9]+$ ]]; then
        echo "$user_name,$sensor_id,$sensor_type_code,$sensor_type_name,$current_time,$value,$test_status,$registration_time,$activity_distance,$activity_angle,$detected_people,$sensor_alias,$x_coordinate,$y_coordinate,$human_detection_status" >> "$TEMP_FILE"
      fi
    done
  done < <(tail -n +2 "$file")

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

for file in "$DATA_DIR"/*.csv; do
  filename=$(basename -- "$file")
  user_name=$(echo "$filename" | cut -d'_' -f1)

  for pattern in "${SENSOR_FILE_PATTERNS[@]}"; do
    if [[ "$filename" == *"$pattern" ]]; then
      echo "Uploading sensor data for $user_name from $file..."
      upload_sensor_data "$file" "$user_name"
      break
    fi
  done
done

