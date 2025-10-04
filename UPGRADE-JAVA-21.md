## Java 21 업그레이드 계획 (demo-maven)

간단한 요약
- 대상 프로젝트: `demo-maven` (경로: `demo-maven`)
- 현재 상태: `pom.xml`의 `maven.compiler.source` 및 `maven.compiler.target`을 21로 변경했고 JDK 21로 컴파일/실행 검증 완료
- 목표: 프로젝트와 CI를 Java 21(LTS)으로 안정적으로 마이그레이션

작업 '계약' (Contract)
- 입력: 프로젝트 소스(빌드 파일 포함), 현재 CI 설정
- 출력: 변경된 빌드 설정(예: pom.xml), CI 업데이트 스니펫, 업그레이드 체크리스트, 검증 결과
- 성공 기준: 프로젝트가 JDK 21로 빌드되고 기존 테스트(있다면)가 통과하며 CI 파이프라인에서 정상 실행
- 실패 모드: 컴파일 에러, 의존성 호환성 문제, CI 환경에서 런타임/테스트 실패

핵심 변경 사항 (이미 적용됨)
- `demo-maven/pom.xml`:
  - `maven.compiler.source` 및 `maven.compiler.target`을 `21`로 변경

검증(로컬)
- JDK 21 설치 확인:
```powershell
java -version
# 또는
'C:\Users\teddy\AppData\Local\Programs\Temurin\jdk-21.0.8+9\bin\java.exe' -version
```
- Maven이 설치된 경우(권장):
```bash
mvn -v
mvn -T 1C clean package
```
- Maven이 없다면 javac로 빠른 검증:
```powershell
& 'C:\Users\teddy\AppData\Local\Programs\Temurin\jdk-21.0.8+9\bin\javac.exe' demo-maven\src\main\java\com\example\App.java -d demo-maven\out21
& 'C:\Users\teddy\AppData\Local\Programs\Temurin\jdk-21.0.8+9\bin\java.exe' -cp demo-maven\out21 com.example.App
```

CI/CD 변경(예시: GitHub Actions)
- `.github/workflows/ci.yml`에 Java 21 설정 추가 예시:
```yaml
name: CI
on: [push, pull_request]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: '21'
      - name: Build
        run: mvn -B -T 1C clean package
```

체크리스트 (권장 순서)
1. 빌드 설정 업데이트(완료)
2. 로컬 빌드 및 테스트 실행(이미 javac로 검증됨)
3. CI 구성 변경 및 CI 실행 확인
4. 의존성 호환성 검사: 사용 중인 라이브러리(특히 오래된 라이브러리나 내부 라이브러리)에서 Java 21 미지원 여부 확인
5. 리플렉션/모듈 접근성 검사: Java 9+의 모듈화 관련 접속 문제(강제 접근 차단)가 없는지 확인
6. 정적 분석/경고 처리(IDE나 `mvn -X` 등으로 자세한 문제 체크)
7. 롤아웃(배포 환경의 JDK 버전 업데이트)
8. 모니터링 및 로그 확인(런타임 에러/경고 탐지)

주요 엣지 케이스
- 네이티브 라이브러리(JNI)를 사용하는 경우 Java 버전 호환성 필요
- 오래된 빌드 도구/플러그인(예: 오래된 maven-compiler-plugin)은 Java21의 새로운 언어 기능을 이해하지 못할 수 있음 → 필요한 경우 플러그인 업그레이드
- Docker 이미지를 사용하는 경우 베이스 이미지의 JDK 버전도 함께 업그레이드해야 함

롤백 계획
- 빠른 롤백: `pom.xml`의 compiler properties를 이전값(예: 17)로 되돌리고 CI 재실행
- 근본 원인 분석 후 재시도

권장 다음 단계(자동화 가능)
- (옵션) OpenRewrite 또는 ErrorProne 기반의 자동 진단/수정 실행: deprecated API 교체, 모듈 접근 해결
- CI에서 Java 21로 테스트 빌드 실행: 문제 발생 시 단계별 롤백

파일 변경 요약
- `demo-maven/pom.xml` 변경: compiler.source/target -> 21

지원 요청 시 제가 대신 해드릴 수 있는 일
- 프로젝트(또는 다른 경로)의 전체 의존성 목록을 검사하고 호환성 이슈 리포트 생성
- CI 파일(.github/workflows)을 생성/수정하고 테스트 실행
- OpenRewrite 규칙을 적용해 자동 리팩토링 시연

끝.
