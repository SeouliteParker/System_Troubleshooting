# [Bug] CPU 과점유에 따른 프로세스 종료

## 1. Description
CPU_MAX_OCCUPY=80 설정에서 CPU 부하가 증가하다
CPU Threshold Violated 경고와 함께 프로세스가 종료됐다.

## 2. Evidence & Logs
Before (80%):
- CPU 부하 51.42~55.77%에서 임계치 위반
- 증거: logs/cpu_test.log, logs/cpu_test2.log

After (40%):
- 6분 이상 생존
- Cooldown 반복 및 작업 재개 확인
- 증거: logs/cpu_40_retry.log

## 3. Root Cause Analysis
애플리케이션 내부 CPU 보호 정책이 작동한 것으로 추정된다.
설정값 80%와 실제 경고값이 달라 추가 원인 분석이 필요하다.
실제 OS CPU 점유율 및 Watchdog 종료 로그는 추가 확인이 필요하다.

## 4. Workaround & Verification
CPU_MAX_OCCUPY를 80에서 40으로 변경했다.
변경 후 관측 구간에서 임계치 위반 없이 작업이 지속됐다.
