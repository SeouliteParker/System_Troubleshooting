# [Bug] OOM - 메모리 한도 초과로 인한 프로세스 종료

## 1. Description (현상 설명)

2026-10-13 Ubuntu 환경에서 agent-leak-app-x86 실행 중
메모리 사용량이 지속적으로 증가하여 프로세스가 종료되었다.

MEMORY_LIMIT=256MB 설정에서 MemoryGuard 보호 정책이 작동했다.

## 2. Evidence & Logs (증거 자료)

### Before: MEMORY_LIMIT=256

- Heap: 25MB → 275MB
- 증가 속도: 약 3초마다 25MB
- MemoryGuard 작동 시각: 21:31:37

핵심 로그:

[CRITICAL] Memory limit exceeded (275MB >= 256MB)
[CRITICAL] Self-terminating process 1830

원본 증거: logs/agent_app.log

### After: MEMORY_LIMIT=512

- CPU_MAX_OCCUPY=40
- Heap: 25MB → 525MB
- 메모리 캐시 정리 후 Heap 초기화
- 프로세스 실행 지속

핵심 로그:

[WARNING] Memory Usage Reached Limit (525MB)
[INFO] Memory Cache Flushed. Process Stabilized.
[SYSTEM] MEMORY RECOVERED (Cache Cleared)

RSS 관측 결과:
- 약 468.7MB → 518.7MB
- 복구 후 약 18.6MB로 감소
- 이후 메모리 재증가 확인

원본 증거:
- logs/memory_rss_retry.log
- logs/memory_rss_final.log

## 3. Root Cause Analysis (원인 분석)

MemoryWorker의 메모리 사용량이 지속적으로 증가했다.

256MB 설정에서는 MemoryGuard가 한도 초과를 감지하여
프로세스 종료를 시도했다.

512MB 설정에서는 메모리 캐시 정리 및 복구가 관측되었다.

이는 메모리 누수 의심 패턴이지만,
의도적으로 증가시키는 실습용 로직일 가능성도 있다.

## 4. Workaround & Verification (조치 및 검증)

MEMORY_LIMIT를 256MB에서 512MB로 상향 조정했다.

Before:
- Heap 275MB에서 한도 초과
- MemoryGuard 종료

After:
- Heap 525MB에서 캐시 정리
- RSS 감소 및 프로그램 실행 지속

초기 비교에서는 CPU_MAX_OCCUPY도 변경되었으나,
2026-10-14 추가 실험에서 CPU_MAX_OCCUPY=40,
MULTI_THREAD_ENABLE=false로 고정하여 재검증했다.
동일 조건 비교 결과는 5장을 참조한다.

근본적인 개선 방안:
- 불필요한 메모리 참조 해제
- 캐시 크기 제한
- 메모리 사용량 지속 모니터링

## 5. Final Controlled Comparison (2026-10-14)

동일한 조건에서 MEMORY_LIMIT만 변경하여 비교했다.

공통 조건:
- CPU_MAX_OCCUPY=40
- MULTI_THREAD_ENABLE=false

Before (256MB):
- 실행 시간: 33초
- Heap: 25MB → 275MB
- MemoryGuard 종료
- 종료 코드: 137 (SIGKILL)

After (512MB):
- 관찰 시간: 90초
- Memory Cache Flushed 확인
- MEMORY RECOVERED 확인
- 종료 코드: 124 (timeout에 의한 종료)

결론:
MEMORY_LIMIT를 256MB에서 512MB로 변경했을 때
프로세스 생존 시간이 증가하고 메모리 복구가 관측됐다.

이는 동일 CPU 조건에서 검증한 결과다.

증거:
- logs/oom_256_final.log
- logs/oom_512_final.log
