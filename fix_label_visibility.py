# -*- coding: utf-8 -*-
"""
Admin Review 페이지 라벨 가독성 개선
- .rf-label: 25% → 60% (필드 라벨 가독성 향상)
- 섹션 헤더 (4곳): 30% → 65% (섹션 구분 명확화)
- .rf-value: 70% → 90% (값 텍스트 밝기 향상)

운영에 영향 없는 시각 개선 변경. 정확한 문자열 매칭만 사용.
"""

import os
import shutil
import sys

DEPLOY = os.path.dirname(os.path.abspath(__file__))
INDEX = os.path.join(DEPLOY, "index.html")
BACKUP = INDEX + ".before-label-fix"

# 각 항목: (찾을 문자열, 바꿀 문자열, 기대 매치 개수)
REPLACEMENTS = [
    # 1. .rf-label CSS 정의 (필드 라벨 색상)
    (
        '.review-field .rf-label{color:rgba(255,255,255,0.25);font-family:var(--mono);font-size:11px;text-transform:uppercase;letter-spacing:0.5px;margin-bottom:4px}',
        '.review-field .rf-label{color:rgba(255,255,255,0.6);font-family:var(--mono);font-size:11px;text-transform:uppercase;letter-spacing:0.5px;margin-bottom:4px}',
        1,
    ),
    # 2. .rf-value CSS 정의 (값 텍스트 색상 약간 밝게)
    (
        '.review-field .rf-value{color:rgba(255,255,255,0.7);font-weight:500}',
        '.review-field .rf-value{color:rgba(255,255,255,0.9);font-weight:500}',
        1,
    ),
    # 3. 섹션 헤더 — 기업 기본 정보
    (
        'html += \'<div style="font-size:11px;color:rgba(255,255,255,0.3);margin-bottom:8px;font-family:var(--mono);text-transform:uppercase;letter-spacing:1px">기업 기본 정보</div>\';',
        'html += \'<div style="font-size:11px;color:rgba(255,255,255,0.65);margin-bottom:8px;font-family:var(--mono);text-transform:uppercase;letter-spacing:1px;font-weight:600">기업 기본 정보</div>\';',
        1,
    ),
    # 4. 섹션 헤더 — 담당자 정보
    (
        'html += \'<div style="font-size:11px;color:rgba(255,255,255,0.3);margin:16px 0 8px;font-family:var(--mono);text-transform:uppercase;letter-spacing:1px">담당자 정보</div>\';',
        'html += \'<div style="font-size:11px;color:rgba(255,255,255,0.65);margin:16px 0 8px;font-family:var(--mono);text-transform:uppercase;letter-spacing:1px;font-weight:600">담당자 정보</div>\';',
        1,
    ),
    # 5. 섹션 헤더 — 제품 / 비즈니스 정보
    (
        'html += \'<div style="font-size:11px;color:rgba(255,255,255,0.3);margin:16px 0 8px;font-family:var(--mono);text-transform:uppercase;letter-spacing:1px">제품 / 비즈니스 정보</div>\';',
        'html += \'<div style="font-size:11px;color:rgba(255,255,255,0.65);margin:16px 0 8px;font-family:var(--mono);text-transform:uppercase;letter-spacing:1px;font-weight:600">제품 / 비즈니스 정보</div>\';',
        1,
    ),
    # 6. 섹션 헤더 — 추가 정보
    (
        'html += \'<div style="font-size:11px;color:rgba(255,255,255,0.3);margin:16px 0 8px;font-family:var(--mono);text-transform:uppercase;letter-spacing:1px">추가 정보</div>\';',
        'html += \'<div style="font-size:11px;color:rgba(255,255,255,0.65);margin:16px 0 8px;font-family:var(--mono);text-transform:uppercase;letter-spacing:1px;font-weight:600">추가 정보</div>\';',
        1,
    ),
]


def main():
    print(f"[1/3] 파일 읽기: {INDEX}")
    with open(INDEX, "rb") as f:
        content = f.read()
    print(f"      크기: {len(content):,} bytes")

    print(f"[2/3] 백업 생성: {BACKUP}")
    shutil.copy2(INDEX, BACKUP)

    print(f"[3/3] 변경 적용 (총 {len(REPLACEMENTS)}건)...")
    failures = []
    for idx, (old, new, expected) in enumerate(REPLACEMENTS, 1):
        old_b = old.encode("utf-8")
        new_b = new.encode("utf-8")
        count = content.count(old_b)
        label = old[:60].replace("\n", " ")
        if count != expected:
            failures.append((idx, count, expected, label))
            print(f"      [{idx}] FAIL · 매치 {count}개 (예상 {expected}) — {label}...")
            continue
        content = content.replace(old_b, new_b)
        print(f"      [{idx}] OK   · 매치 {count}개 교체 — {label}...")

    if failures:
        print()
        print("=" * 60)
        print("실패 항목이 있어 파일을 저장하지 않습니다.")
        print("백업은 그대로 남아있고, 원본 index.html도 변경 없습니다.")
        print("=" * 60)
        sys.exit(1)

    with open(INDEX, "wb") as f:
        f.write(content)
    print()
    print("=" * 60)
    print("적용 완료")
    print("=" * 60)
    print("브라우저에서 관리자 페이지를 열어 라벨 가독성을 확인하세요.")
    print(f"문제 있으면: copy {os.path.basename(BACKUP)} index.html")


if __name__ == "__main__":
    main()
