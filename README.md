# System Troubleshooting

## 프로젝트 소개
Ubuntu Linux에서 agent-leak-app의 시스템 장애를 재현하고 분석한 프로젝트.

## 실습 환경
- macOS Intel x86_64
- OrbStack
- Ubuntu 26.04.1 LTS
- Linux x86_64

## 장애 분석 결과

| 장애 | 원인 및 현상 | 검증 결과 |
|---|---|---|
| OOM | 메모리 증가 및 한도 초과 | MEMORY_LIMIT 변경 후 복구 확인 |
| CPU Spike | CPU 임계치 위반 | CPU_MAX_OCCUPY 조정 후 안정화 |
| Deadlock | 스레드 간 순환 대기 | 멀티스레드 비활성화 후 작업 완료 |

## 장애 보고서
- [OOM 분석](reports/OOM_Issue.md)
- [CPU 분석](reports/CPU_Issue.md)
- [Deadlock 분석](reports/Deadlock_Issue.md)

## 증거 자료
실제 프로그램 로그와 리눅스 시스템 도구(ps, top)로 수집한 데이터를 사용했다.

## 개선 방향
- 메모리 캐시 관리 및 누수 방지
- CPU 부하 제한 및 모니터링
- 스레드 락 획득 순서 통일

## 최종 장애 검증 (2026-10-14)

### 1. OOM 동일 조건 비교
공통 조건: CPU_MAX_OCCUPY=40, MULTI_THREAD_ENABLE=false

- Before: MEMORY_LIMIT=256, 33초 후 MemoryGuard 종료, EXIT_CODE=137
- After: MEMORY_LIMIT=512, 캐시 정리 및 메모리 복구 확인, 90초 관찰
- EXIT_CODE=124는 timeout에 의한 종료이며 OOM 종료가 아님

증거: logs/oom_256_final.log, logs/oom_512_final.log

### 2. CPU 종료 신호 분석
- CPU Threshold Violated 발생
- 종료 코드 143 (SIGTERM)
- strace에서 kill 및 tgkill을 통한 SIGTERM 확인
- 애플리케이션 내부 종료 동작은 확인했으나 Watchdog 함수 호출 여부는 미확정

증거: logs/cpu_signal_trace.log, logs/cpu_strace.log

### 3. 운영 모니터링
monitor.sh는 다음 항목을 점검한다.

- 프로세스 agent-leak-app-x86 실행 확인
- TCP 15034 LISTEN 확인
- 프로세스 또는 포트 비정상 시 exit 1
- CPU, 메모리, 디스크 사용률 수집
- 방화벽 비활성 및 임계값 초과 시 WARNING 기록

프로세스 비정상 종료 검증 완료.
포트 단독 비정상 상황은 추가 검증 필요.

### GitHub Issues
- OOM: https://github.com/SeouliteParker/System_Troubleshooting/issues/1
- CPU: https://github.com/SeouliteParker/System_Troubleshooting/issues/2
- Deadlock: https://github.com/SeouliteParker/System_T

### 정상 상태 통합 테스트 (2026-10-14)
- 애플리케이션 PID 7099 실행 확인
- TCP 15034 LISTEN 확인
- monitor.sh 8초간 정상 관제
- 종료 코드 124: timeout에 의한 정상적인 관찰 종료
- 프로세스 CPU/RSS 및 시스템 CPU·메모리·디스크 기록 확인
- 방화벽 비활성 상태 확인
- 테스트 후 애플리케이션과 포트 정상 종료 확인
