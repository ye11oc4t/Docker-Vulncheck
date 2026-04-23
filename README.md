# 🐳 Docker-Vulncheck

**K-Shield Jr 10기** | 취약점진단분반 E-01조  
Docker 보안 취약점 자동/수동 점검 프로젝트

---

## 📋 프로젝트 개요

| 항목 | 내용 |
|------|------|
| 과정 | K-Shield Jr 10기 취약점진단 트랙 |
| 조 | E-01조 |
| 대상 | Docker Engine 23.0.6 (Ubuntu Linux) |
| 점검 항목 수 | D-01 ~ D-41 (총 41개) |
| 참고 기준 | KISA Docker 보안 가이드, SK 쉴더스 보안 가이드 |

---

## 📊 점검 결과 요약

| 결과 | 항목 수 |
|------|---------|
| ✅ 양호 (Good) | 16 |
| ❌ 취약 (Vulnerable) | 23 |
| 🔍 검토 필요 (Review) | 2 |

### 주요 취약 항목

| 진단코드 | 항목명 | 취약도 |
|---------|--------|--------|
| D-03~D-07 | audit 설정 미적용 (`/var/lib/docker`, `/etc/docker`, `docker.service`, `docker.socket`, `/etc/default/docker`) | 상 |
| D-08 | 컨테이너 간 네트워크 트래픽 미제한 (`enable_icc: true`) | 상 |
| D-21 | 컨테이너 내 SSH 활성화 | 상 |
| D-22 | 호스트 OS 주요 자원 접근 미제어 | 상 |
| D-24/D-27 | SSL/TLS 미적용 | 상 |
| D-25 | `--no-new-privileges` 미설정 | 상 |
| D-31 | root 계정으로 컨테이너 실행 | 중 |
| D-32 | Docker Content Trust 비활성화 | 중 |
| D-33/D-37 | SELinux/seccomp 보안 옵션 미설정 | 중 |
| D-38 | 로그 레벨 및 중앙 집중식 로깅 미설정 | 하 |

---

## 📁 디렉토리 구조

```
kshieldjr-docker-vulncheck/
├── scripts/
│   └── docker_vulncheck.sh        # 자동 취약점 점검 스크립트 (D-01~D-27)
├── results/
│   └── docker_vulncheck_result.txt # 스크립트 실행 결과
└── reports/
    ├── docker_vuln_detail_report.pdf    # DOCKER 취약점 점검 상세 보고서
    ├── docker_manual_assessment_report.pdf  # 수동 점검 결과 리포트
    └── docker_vuln_checklist.xlsx       # 취약점 점검 체크리스트
```

---

## 🔧 스크립트 사용법

```bash
# root 권한 필요
sudo bash scripts/docker_vulncheck.sh | tee results/docker_vulncheck_result.txt
```

점검 항목: D-01(최신 패치), D-02 - D-07(audit 설정), D-08(네트워크), D-09 - D-20(파일 권한), D-21 - D-27(SSH/TLS/권한)

---

## 👥 팀원

표재경 · 김서연 · 김효민 · 전동현 · 황유림
