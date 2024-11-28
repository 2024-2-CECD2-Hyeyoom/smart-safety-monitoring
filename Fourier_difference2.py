import influxdb_client
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np

# InfluxDB 연결 정보
token = "OEF52rPOc0pFcvMTZsr5HxTKMW7c1T8VRJ6lsmdJYVA="
org = "hyeyoom"
url = "http://localhost:8086"

client = influxdb_client.InfluxDBClient(url=url, token=token, org=org)
query_api = client.query_api()

# 수면 시간대 설정 (5일간, 각 날짜마다 두 개의 시간대)
sleep_periods = [
    ("2024-08-18T22:00:00Z", "2024-08-19T08:00:00Z"),  # 하루 전체 수면 시간대
    ("2024-08-19T22:00:00Z", "2024-08-20T08:00:00Z"),
    ("2024-08-20T22:00:00Z", "2024-08-21T08:00:00Z"),
    ("2024-08-21T22:00:00Z", "2024-08-22T08:00:00Z"),
    ("2024-08-22T22:00:00Z", "2024-08-23T08:00:00Z")
    
]

# 데이터 추출 함수
def get_data(query):
    tables = query_api.query(query, org="hyeyoom")
    data = []
    for table in tables:
        for record in table.records:
            data.append([record.get_time(), record.get_value()])
    df = pd.DataFrame(data, columns=["time", "heart_rate"])
    df['time'] = pd.to_datetime(df['time'])
    df['heart_rate'] = df['heart_rate'].replace(0, pd.NA)  # 0을 NaN으로 변환
    df['heart_rate'] = pd.to_numeric(df['heart_rate'], errors='coerce')
    df['heart_rate'] = df['heart_rate'].interpolate(method='linear')  # 선형 보간법
    df = df.dropna(subset=['heart_rate'])
    return df

# 푸리에 변환 함수
def perform_fft(df):
    time_diff = (df['time'].iloc[1] - df['time'].iloc[0]).total_seconds()  # 시간 간격
    sampling_rate = 1 / time_diff  # 샘플링 주파수 (Hz)
    heart_rate_fft = np.fft.fft(df['heart_rate'])
    frequencies = np.fft.fftfreq(len(df['heart_rate']), d=time_diff)
    half_n = len(frequencies) // 2
    frequencies = frequencies[:half_n]
    heart_rate_fft = heart_rate_fft[:half_n]
    magnitude = np.abs(heart_rate_fft)
    return frequencies, magnitude

# 여러 사람 데이터 가져오기 및 푸리에 변환
user_names = ["박A", "김A", "박B"]  # 3명 이상의 사용자 처리

# 각 사람에 대한 5일간의 데이터 가져오기
all_frequencies = {}
all_magnitudes = {}

# 날짜별 색상 설정
colors = ["blue", "green", "red", "purple", "orange"]  # 각 날짜마다 다른 색상 지정

for user_name in user_names:
    frequencies_list = []
    magnitude_list = []
    
    # 5일간 데이터 쿼리 실행
    for idx, (start_time, stop_time) in enumerate(sleep_periods):
        query = f"""from(bucket: "sensor_data")
          |> range(start: {start_time}, stop: {stop_time})
          |> filter(fn: (r) => r["user_name"] == "{user_name}")
          |> filter(fn: (r) => r["_measurement"] == "심박")
          |> filter(fn: (r) => r["_field"] == "measurement_value")
          |> aggregateWindow(every: 1m, fn: last, createEmpty: false)
          |> yield(name: "last")"""
        
        # 데이터 추출
        df = get_data(query)
        
        # 푸리에 변환 수행
        frequencies, magnitude = perform_fft(df)
        frequencies_list.append(frequencies)
        magnitude_list.append(magnitude)
    
    # 전체 데이터 저장
    all_frequencies[user_name] = frequencies_list
    all_magnitudes[user_name] = magnitude_list

# 시각화 (각 사람의 푸리에 변환 비교)
plt.figure(figsize=(12, 10))

for i, user_name in enumerate(user_names):
    plt.subplot(len(user_names), 1, i+1)
    
    # 여러 날의 푸리에 변환 결과를 색상별로 표시
    for idx, (frequencies, magnitude) in enumerate(zip(all_frequencies[user_name], all_magnitudes[user_name])):
        plt.plot(frequencies, magnitude, color=colors[idx], label=f'날짜 {idx+1}')
    
    plt.title(f'Fourier Transform of Heart Rate for {user_name}', fontsize=14)
    plt.xlabel('Frequency (Hz)', fontsize=12)
    plt.ylabel('Magnitude', fontsize=12)
    plt.grid(True)
    
    # 세로축 범위 확대 (0부터 최대치의 5%까지만 표시)
    plt.ylim(0, np.max(np.concatenate(list(all_magnitudes[user_name]))) * 0.05)
    
    # 범례 추가
    plt.legend()

plt.tight_layout()
plt.show()
