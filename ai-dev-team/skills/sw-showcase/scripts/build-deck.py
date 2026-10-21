#!/usr/bin/env python3
"""build-deck.py — 由 deck spec JSON 砌 2 頁 pitch deck (.pptx)，再 upload Drive 轉 Google Slides。

用法：python3 build-deck.py <deck-spec.json> <output.pptx>

版面固定（SKILL.md §Deck）：
  P1 Hero  — label、app 名、tagline、Problem → Solution、link、手機截圖
  P2 Features — 5–10 個賣點 grid、桌面截圖、KPI 列
配色只由 spec 嘅 accent_hex 決定；其餘顏色係固定中性色。

依賴：python-pptx（必須）、qrcode（可選，冇就唔出 QR）
"""

import json
import sys
from pathlib import Path

from pptx import Presentation
from pptx.dml.color import RGBColor
from pptx.enum.shapes import MSO_SHAPE
from pptx.enum.text import PP_ALIGN, MSO_ANCHOR
from pptx.util import Inches, Pt, Emu

try:
    import qrcode
except ImportError:  # QR 係可選
    qrcode = None

SLIDE_WIDTH_IN = 13.333
SLIDE_HEIGHT_IN = 7.5
MARGIN_IN = 0.6
FONT_FAMILY = "Inter"
INK = RGBColor(0x1F, 0x23, 0x2B)
MUTED = RGBColor(0x5B, 0x63, 0x70)
CARD_BG = RGBColor(0xF4, 0xF5, 0xF7)
WHITE = RGBColor(0xFF, 0xFF, 0xFF)
MIN_FEATURES = 5
MAX_FEATURES = 10
MAX_KPIS = 6
FEATURE_COLUMNS = 2
QR_SIZE_IN = 1.1
MAX_IMAGE_PX = 1600
JPEG_QUALITY = 85
LABEL_PT = 12
APP_NAME_PT = 44
APP_NAME_LONG_PT = 30
APP_NAME_LONG_CHARS = 20
TAGLINE_PT = 20
BODY_PT = 14
FEATURE_TITLE_PT = 13
FEATURE_DESC_PT = 11
KPI_VALUE_PT = 26
KPI_LABEL_PT = 11


def hex_to_rgb(hex_str):
    value = hex_str.lstrip("#")
    return RGBColor(int(value[0:2], 16), int(value[2:4], 16), int(value[4:6], 16))


def add_text(slide, box, text, size, color=INK, bold=False, align=PP_ALIGN.LEFT):
    left, top, width, height = (Inches(v) for v in box)
    frame = slide.shapes.add_textbox(left, top, width, height).text_frame
    frame.word_wrap = True
    paragraph = frame.paragraphs[0]
    paragraph.alignment = align
    run = paragraph.add_run()
    run.text = text
    run.font.size = Pt(size)
    run.font.bold = bold
    run.font.name = FONT_FAMILY
    run.font.color.rgb = color
    return frame


def add_rect(slide, box, fill, shape=MSO_SHAPE.RECTANGLE):
    left, top, width, height = (Inches(v) for v in box)
    rect = slide.shapes.add_shape(shape, left, top, width, height)
    rect.fill.solid()
    rect.fill.fore_color.rgb = fill
    rect.line.fill.background()
    rect.shadow.inherit = False
    return rect


def compress_image(image_path):
    """縮細 + 轉 JPEG（截圖係 3x DPR，原圖會令 deck 好大）；回傳 (BytesIO, ratio)。"""
    from io import BytesIO

    from PIL import Image

    with Image.open(image_path) as img:
        img = img.convert("RGB")
        img.thumbnail((MAX_IMAGE_PX, MAX_IMAGE_PX))
        buffer = BytesIO()
        img.save(buffer, "JPEG", quality=JPEG_QUALITY, optimize=True)
        ratio = img.width / img.height
    buffer.seek(0)
    return buffer, ratio


def add_picture_fit(slide, image_path, box):
    """喺 box 入面等比例縮放置中擺圖。"""
    left, top, width, height = box
    image_stream, ratio = compress_image(image_path)
    fit_w, fit_h = (width, width / ratio) if width / ratio <= height else (height * ratio, height)
    slide.shapes.add_picture(
        image_stream,
        Inches(left + (width - fit_w) / 2),
        Inches(top + (height - fit_h) / 2),
        Inches(fit_w),
        Inches(fit_h),
    )


def add_qr(slide, url, box):
    if qrcode is None or not url:
        return
    import tempfile

    with tempfile.TemporaryDirectory() as tmp_dir:
        qr_path = Path(tmp_dir) / "qr.png"
        qrcode.make(url).save(qr_path)
        add_picture_fit(slide, qr_path, box)


def build_hero(prs, spec, accent, base_dir):
    slide = prs.slides.add_slide(prs.slide_layouts[6])
    panel_left = SLIDE_WIDTH_IN * 0.62
    add_rect(slide, (panel_left, 0, SLIDE_WIDTH_IN - panel_left, SLIDE_HEIGHT_IN), accent)
    add_picture_fit(
        slide,
        base_dir / spec["hero_screenshot"],
        (panel_left + 0.4, 0.4, SLIDE_WIDTH_IN - panel_left - 0.8, SLIDE_HEIGHT_IN - 0.8),
    )
    text_width = panel_left - MARGIN_IN * 2
    add_text(slide, (MARGIN_IN, 0.6, text_width, 0.4), spec.get("label", "PORTFOLIO PROJECT"),
             LABEL_PT, accent, bold=True)
    name_pt = APP_NAME_PT if len(spec["app_name"]) <= APP_NAME_LONG_CHARS else APP_NAME_LONG_PT
    add_text(slide, (MARGIN_IN, 1.0, text_width, 0.9), spec["app_name"], name_pt, bold=True)
    add_text(slide, (MARGIN_IN, 1.95, text_width, 0.8), spec["tagline"], TAGLINE_PT, MUTED)
    add_problem_solution(slide, spec, accent, (MARGIN_IN, 3.0, text_width))
    add_text(slide, (MARGIN_IN, 6.5, text_width - QR_SIZE_IN, 0.4), spec.get("link_label", ""),
             BODY_PT, accent, bold=True)
    add_qr(slide, spec.get("qr_url"), (panel_left - QR_SIZE_IN - 0.3, 6.1, QR_SIZE_IN, QR_SIZE_IN))


def add_problem_solution(slide, spec, accent, origin):
    left, top, width = origin
    card_height = 1.45
    for index, (heading, body) in enumerate(
        (("THE PROBLEM", spec["problem"]), ("THE SOLUTION", spec["solution"]))
    ):
        card_top = top + index * (card_height + 0.2)
        add_rect(slide, (left, card_top, width, card_height), CARD_BG, MSO_SHAPE.ROUNDED_RECTANGLE)
        add_rect(slide, (left, card_top, 0.08, card_height), accent)
        add_text(slide, (left + 0.3, card_top + 0.12, width - 0.5, 0.3), heading, LABEL_PT, accent,
                 bold=True)
        add_text(slide, (left + 0.3, card_top + 0.45, width - 0.5, card_height - 0.5), body,
                 BODY_PT)


def build_features(prs, spec, accent, base_dir):
    slide = prs.slides.add_slide(prs.slide_layouts[6])
    grid_width = SLIDE_WIDTH_IN * 0.58
    add_text(slide, (MARGIN_IN, 0.4, grid_width, 0.6), spec.get("features_title", "Key features"),
             28, bold=True)
    add_feature_grid(slide, spec["features"], accent, (MARGIN_IN, 1.15, grid_width - MARGIN_IN))
    shot_left = grid_width + 0.3
    add_picture_fit(
        slide,
        base_dir / spec["desktop_screenshot"],
        (shot_left, 0.5, SLIDE_WIDTH_IN - shot_left - MARGIN_IN, 4.9),
    )
    add_kpi_strip(slide, spec["kpis"], accent)


def add_feature_grid(slide, features, accent, origin):
    left, top, width = origin
    rows = (len(features) + FEATURE_COLUMNS - 1) // FEATURE_COLUMNS
    gap = 0.15
    cell_w = (width - gap) / FEATURE_COLUMNS
    cell_h = min(0.95, (4.6 - gap * (rows - 1)) / rows)
    for index, feature in enumerate(features):
        col, row = index % FEATURE_COLUMNS, index // FEATURE_COLUMNS
        x, y = left + col * (cell_w + gap), top + row * (cell_h + gap)
        add_rect(slide, (x, y, cell_w, cell_h), CARD_BG, MSO_SHAPE.ROUNDED_RECTANGLE)
        add_text(slide, (x + 0.15, y + 0.06, cell_w - 0.3, 0.3), feature["title"],
                 FEATURE_TITLE_PT, accent, bold=True)
        add_text(slide, (x + 0.15, y + 0.36, cell_w - 0.3, cell_h - 0.4), feature["desc"],
                 FEATURE_DESC_PT, INK)


def add_kpi_strip(slide, kpis, accent):
    strip_top = 5.85
    strip_height = SLIDE_HEIGHT_IN - strip_top
    add_rect(slide, (0, strip_top, SLIDE_WIDTH_IN, strip_height), accent)
    cell_w = (SLIDE_WIDTH_IN - MARGIN_IN * 2) / len(kpis)
    for index, kpi in enumerate(kpis):
        x = MARGIN_IN + index * cell_w
        add_text(slide, (x, strip_top + 0.2, cell_w, 0.6), kpi["value"], KPI_VALUE_PT, WHITE,
                 bold=True, align=PP_ALIGN.CENTER)
        add_text(slide, (x, strip_top + 0.85, cell_w, 0.5), kpi["label"], KPI_LABEL_PT, WHITE,
                 align=PP_ALIGN.CENTER)


def validate(spec):
    count = len(spec.get("features", []))
    if not MIN_FEATURES <= count <= MAX_FEATURES:
        raise ValueError(f"features must be {MIN_FEATURES}-{MAX_FEATURES}, got {count}")
    if not 1 <= len(spec.get("kpis", [])) <= MAX_KPIS:
        raise ValueError(f"kpis must be 1-{MAX_KPIS}")
    for key in ("app_name", "tagline", "problem", "solution", "accent_hex",
                "hero_screenshot", "desktop_screenshot"):
        if not spec.get(key):
            raise ValueError(f"missing required field: {key}")


def main(spec_path, out_path):
    spec_file = Path(spec_path)
    spec = json.loads(spec_file.read_text(encoding="utf-8"))
    validate(spec)
    accent = hex_to_rgb(spec["accent_hex"])
    prs = Presentation()
    prs.slide_width = Emu(Inches(SLIDE_WIDTH_IN))
    prs.slide_height = Emu(Inches(SLIDE_HEIGHT_IN))
    build_hero(prs, spec, accent, spec_file.parent)
    build_features(prs, spec, accent, spec_file.parent)
    prs.save(out_path)
    print(f"deck written: {out_path}")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit("usage: build-deck.py <deck-spec.json> <output.pptx>")
    main(sys.argv[1], sys.argv[2])
