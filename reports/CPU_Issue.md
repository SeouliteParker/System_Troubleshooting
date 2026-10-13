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

## 5. Additional OS-Level Verification

### CPU 80% 재현 실험 (2026-10-14)

환경:
- MEMORY_LIMIT=512
- CPU_MAX_OCCUPY=80
- MULTI_THREAD_ENABLE=false

측정 결과:
- 내부 CpuWorker 최대 부하: 55.82%
- OS ps 측정 작업 프로세스 CPU: 약 0.7~0.8%
- CPU Threshold Violated 발생: 07:05:59
- 프로세스 종료 확인

증거 파일:
- logs/cpu_80_verify.log
- logs/cpu_80_ps.log

### 분석

애플리케이션 내부 Current Load와 OS의 CPU 사용률은
일치하지 않았다.

CPU_MAX_OCCUPY=80 설정에서도 내부 부하 55.82%에서
임계치 위반이 발생했다.

Watchdog/SIGTERM 메시지는 확인되지 않았으므로
종료 신호 및 내부 임계치 판단 로직은 추가 분석이 필요하다.

## 6. Monitor & SIGTERM Verification

### OS 관제 결과
monitor.sh를 이용해 프로세스별 CPU 및 RSS를 측정했다.

- 부모 PID 4833: CPU 약 0.2%
- 작업 PID 4845: CPU 약 0.8~0.9%
- 프로그램 내부 Current Load: 최대 53.98%

OS 측정값과 애플리케이션 내부 부하 수치는
서로 다른 측정 기준을 사용하고 있다.

### 종료 신호 검증
- CPU Threshold Violated 발생
- 종료 코드: 143
- 종료 신호: SIGTERM으로 해석 가능
- Watchdog이 신호를 보냈는지는 미확정

### 증거 파일
- logs/monitor.log
- logs/cpu_watchdog_test.log
- logs/cpu_exit_test.log
- logs/cpu_exit_code.txt

### 결론
CPU 임계치 위반과 SIGTERM 종료가 관측되었다.
CPU 보호 정책의 작동과 관련된 종료로 추정되지만,
신호 발신 주체는 추가 확인이 필요하다.
