#!/usr/bin/env python3
# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "playwright",
#     "pillow",
# ]
# ///
"""
html_to_pdf.py — HTML 슬라이드 덱을 PDF로 변환

16:9 슬라이드 영역만 캡처 (4K 모니터 절반 기준: 1920×1080)
검정 letterbox 영역 제외, .slide-deck 요소만 정확히 캡처

사용법:
    uv run scripts/html_to_pdf.py input.html [output.pdf] [--width 1920] [--height 1080]

초기 설정 (최초 1회):
    uv run playwright install chromium
"""

import sys
import os
import argparse
import tempfile
from pathlib import Path


def parse_args():
    parser = argparse.ArgumentParser(
        description="HTML 슬라이드 덱을 PDF로 변환 (16:9 슬라이드 영역만 캡처)"
    )
    parser.add_argument("input", help="입력 HTML 파일 경로")
    parser.add_argument("output", nargs="?", help="출력 PDF 파일 경로 (기본: 입력파일명.pdf)")
    parser.add_argument("--width",  type=int, default=1920, help="뷰포트 너비 px (기본: 1920)")
    parser.add_argument("--height", type=int, default=1080, help="뷰포트 높이 px (기본: 1080)")
    parser.add_argument("--delay",  type=int, default=600,  help="슬라이드 전환 대기 ms (기본: 600)")
    return parser.parse_args()


def html_to_pdf(input_path: str, output_path: str, width: int, height: int, delay: int):
    try:
        from playwright.sync_api import sync_playwright
    except ImportError:
        print("ERROR: playwright가 설치되지 않았습니다.")
        print("  pip install playwright && playwright install chromium")
        sys.exit(1)

    try:
        from PIL import Image
    except ImportError:
        print("ERROR: Pillow가 설치되지 않았습니다.")
        print("  pip install pillow")
        sys.exit(1)

    input_abs = os.path.abspath(input_path)
    if not os.path.exists(input_abs):
        print(f"ERROR: 파일을 찾을 수 없습니다: {input_abs}")
        sys.exit(1)

    file_url = f"file:///{input_abs.replace(os.sep, '/')}"
    print(f"변환 시작: {input_abs}")
    print(f"뷰포트: {width}×{height} px")

    screenshots = []

    with sync_playwright() as p:
        browser = p.chromium.launch()
        page = browser.new_page(viewport={"width": width, "height": height})

        print(f"페이지 로딩: {file_url}")
        page.goto(file_url, wait_until="networkidle")
        page.wait_for_timeout(500)

        # 전체 슬라이드 수 확인
        total_slides = page.evaluate("document.querySelectorAll('.slide').length")
        print(f"총 슬라이드 수: {total_slides}")

        if total_slides == 0:
            print("ERROR: .slide 요소를 찾을 수 없습니다. HTML 파일이 올바른 형식인지 확인하세요.")
            browser.close()
            sys.exit(1)

        # slide-deck 영역의 실제 픽셀 위치/크기 측정
        deck_box = page.evaluate("""() => {
            const deck = document.getElementById('deck');
            if (!deck) return null;
            const rect = deck.getBoundingClientRect();
            return { x: rect.x, y: rect.y, width: rect.width, height: rect.height };
        }""")

        if not deck_box:
            print("WARNING: #deck 요소를 찾을 수 없습니다. 전체 화면을 캡처합니다.")
            clip = None
        else:
            print(f"슬라이드 영역: x={deck_box['x']:.0f} y={deck_box['y']:.0f} "
                  f"w={deck_box['width']:.0f} h={deck_box['height']:.0f}")
            clip = {
                "x":      deck_box["x"],
                "y":      deck_box["y"],
                "width":  deck_box["width"],
                "height": deck_box["height"],
            }

        with tempfile.TemporaryDirectory() as tmpdir:
            for i in range(total_slides):
                # 슬라이드 이동 (JS 직접 호출)
                page.evaluate(f"""() => {{
                    const slides = document.querySelectorAll('.slide');
                    slides.forEach((s, idx) => {{
                        s.classList.remove('active', 'exit-left');
                        if (idx === {i}) s.classList.add('active');
                    }});
                    // 헤더 라벨 업데이트
                    const label = slides[{i}].querySelector('.slide-label');
                    const headerLabel = document.getElementById('headerLabel');
                    if (label && headerLabel) headerLabel.textContent = label.textContent.trim();
                }}""")

                # 애니메이션 완료 대기
                page.wait_for_timeout(delay)

                # 스크린샷
                shot_path = os.path.join(tmpdir, f"slide_{i:03d}.png")
                if clip:
                    page.screenshot(path=shot_path, clip=clip)
                else:
                    page.screenshot(path=shot_path)

                print(f"  캡처: 슬라이드 {i+1}/{total_slides}")
                screenshots.append(shot_path)

            browser.close()

            # PNG → PDF 변환
            print(f"\nPDF 생성 중: {output_path}")
            images = [Image.open(s).convert("RGB") for s in screenshots]

            if not images:
                print("ERROR: 캡처된 슬라이드가 없습니다.")
                sys.exit(1)

            # 첫 장을 기준으로 나머지를 append
            images[0].save(
                output_path,
                save_all=True,
                append_images=images[1:],
                resolution=150,
            )

    print(f"\n완료: {output_path}")
    print(f"  슬라이드 수: {total_slides}")
    size_mb = os.path.getsize(output_path) / 1024 / 1024
    print(f"  파일 크기: {size_mb:.1f} MB")


def main():
    args = parse_args()

    # 출력 경로 결정
    if args.output:
        output_path = args.output
    else:
        input_stem = Path(args.input).stem
        output_path = str(Path(args.input).parent / f"{input_stem}.pdf")

    html_to_pdf(
        input_path=args.input,
        output_path=output_path,
        width=args.width,
        height=args.height,
        delay=args.delay,
    )


if __name__ == "__main__":
    main()
