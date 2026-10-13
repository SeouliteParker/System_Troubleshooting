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
