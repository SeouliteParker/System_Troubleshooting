# [Bug] Deadlock - 멀티스레드 자원 교착상태

## 1. Description (현상 설명)

2026-10-13 Ubuntu에서 MULTI_THREAD_ENABLE=true로 실행 시
프로세스는 살아 있지만 작업이 진행되지 않는 현상이 발생했다.

## 2. Evidence & Logs (증거 자료)

### Before: MULTI_THREAD_ENABLE=true

- PID 2777, 2782 생존 확인
- CPU 사용률 0.0%
- 세 스레드가 futex_wait 상태
- WAITING / BLOCKED 로그 발생

Thread-1:
- Shared_Memory_A 점유
- Socket_Pool_B 대기

Thread-2:
- Socket_Pool_B 점유
- Shared_Memory_A 대기

증거:
- logs/deadlock_true.log
- ps 및 ps -L 명령어 출력

### After: MULTI_THREAD_ENABLE=false

- Concurrency: False [OK]
- Scheduler: All tasks completed
- 관측 구간에서 WAITING/BLOCKED 없음

증거:
- logs/deadlock_false.log

## 3. Root Cause Analysis (원인 분석)

Thread-1과 Thread-2가 각각 자원 A와 B를 점유한 채
상대방이 보유한 자원을 기다리면서 순환 대기가 발생했다.

교착상태의 4대 조건:
1. 상호 배제
2. 점유 대기
3. 비선점
4. 순환 대기

프로그램 로그와 스레드의 futex_wait 상태가
교착상태 발생 판단을 뒷받침한다.

## 4. Workaround & Verification (조치 및 검증)

MULTI_THREAD_ENABLE을 true에서 false로 변경했다.

Before:
- 프로세스 생존, CPU 0.0%
- WAITING/BLOCKED 발생
- 작업 진행 정체

After:
- All tasks completed 확인
- 관측 구간에서 교착상태 없음

근본적인 개선 방안:
- 모든 스레드의 락 획득 순서 통일
- 락 대기 타임아웃 적용
- 불필요한 중첩 락 제거
