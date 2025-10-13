# 간단한 법인 영업관리(명함 정리) 툴

무엇을 만드나
- 명함 이미지에서 OCR로 이름, 회사, 연락처(전화/이메일)를 추출
- 수동으로 명함 정보를 입력하는 폼
- 추출된 정보를 CSV/Excel로 저장하고 조회

## 요구사항

- Python 3.9+
- Tesseract OCR 설치 (Windows: see https://github.com/UB-Mannheim/tesseract/wiki)
- 필요한 패키지 설치: `pip install -r requirements.txt`

사용법(빠른 시작)
1) 명함 이미지를 `sales/input/`에 넣습니다.
2) `python sales/extract.py`를 실행해 OCR과 추출을 시도합니다.
3) 결과는 `sales/contacts.csv`에 저장됩니다.
4) `python sales/viewer.py`로 목록을 확인하거나 `contacts.xlsx`로 내보냅니다.

예제(텍스트 붙여넣기 테스트):

```bash
python -c "from sales.extract import extract_fields; print(extract_fields(open('sales/sample-card.txt').read()))"
```

참고: OCR은 100% 정확하지 않으므로 수동 검증 단계가 필요합니다.
