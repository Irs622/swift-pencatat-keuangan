import os
import cv2
import numpy as np
from fastapi import FastAPI, File, UploadFile
from paddleocr import PaddleOCR, PPStructureV3
from PIL import Image, ExifTags
import io
import re
from datetime import datetime

app = FastAPI()

# Initialize PaddleOCR 3.x (PP-OCRv5)
ocr = PaddleOCR(use_angle_cls=True, lang='en', det_limit_side_len=2000)

# Initialize PP-StructureV3 for layout parsing
structure = PPStructureV3(table=False, ocr=True, show_log=False)

def get_image_orientation(image_bytes):
    try:
        img = Image.open(io.BytesIO(image_bytes))
        for orientation in ExifTags.TAGS.keys():
            if ExifTags.TAGS[orientation] == 'Orientation':
                break
        exif = dict(img._getexif().items())
        if exif[orientation] == 3:
            return 180
        elif exif[orientation] == 6:
            return 270
        elif exif[orientation] == 8:
            return 90
    except (AttributeError, KeyError, IndexError):
        pass
    return 0

def deskew(img):
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    gray = cv2.bitwise_not(gray)
    coords = np.column_stack(np.where(gray > 0))
    angle = cv2.minAreaRect(coords)[-1]
    if angle < -45:
        angle = -(90 + angle)
    else:
        angle = -angle
    (h, w) = img.shape[:2]
    center = (w // 2, h // 2)
    M = cv2.getRotationMatrix2D(center, angle, 1.0)
    rotated = cv2.warpAffine(img, M, (w, h), flags=cv2.INTER_CUBIC, borderMode=cv2.BORDER_REPLICATE)
    return rotated

def preprocess_image(image_bytes):
    nparr = np.frombuffer(image_bytes, np.uint8)
    img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
    
    # 1. Perspective Correction / Orientation
    orientation = get_image_orientation(image_bytes)
    if orientation != 0:
        if orientation == 90: img = cv2.rotate(img, cv2.ROTATE_90_CLOCKWISE)
        elif orientation == 180: img = cv2.rotate(img, cv2.ROTATE_180)
        elif orientation == 270: img = cv2.rotate(img, cv2.ROTATE_90_COUNTERCLOCKWISE)

    # 2. Deskew
    img = deskew(img)
    
    # 3. Enhancement
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8,8))
    contrast = clahe.apply(gray)
    denoised = cv2.fastNlMeansDenoising(contrast, None, 10, 7, 21)
    
    return denoised, img # Return both processed and original (for structure)

def parse_text(raw_text, layout_data=None):
    lines = [l.strip() for l in raw_text.split("\n") if l.strip()]
    store_name = "Unknown Store"
    total_amount = 0.0
    date = datetime.now().strftime("%Y-%m-%d")
    category = "Others"
    
    # 1. Extract Store Name
    # Heuristic: First few lines, often uppercase, with layout info if available
    if layout_data:
        # PP-Structure often identifies 'header' or 'title'
        headers = [res for res in layout_data if res['type'] in ['header', 'title']]
        if headers:
            # Join text from header regions
            header_text = " ".join([h['res'][0][1][0] if isinstance(h['res'], list) and len(h['res']) > 0 else "" for h in headers]).strip()
            if header_text: store_name = header_text
    
    if store_name == "Unknown Store" and lines:
        # Fallback to first line
        store_name = lines[0]

    # 2. Extract Date
    # Match patterns like DD/MM/YY, DD-MM-YYYY, etc.
    date_patterns = [
        r"(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})",
        r"(\d{4}[/-]\d{1,2}[/-]\d{1,2})"
    ]
    for pattern in date_patterns:
        match = re.search(pattern, raw_text)
        if match:
            date = match.group(1)
            break

    # 3. Extract Total Amount
    # Indonesian receipts often use "TOTAL", "TOTAL BAYAR", "GRAND TOTAL", "NETTO"
    # We look for keywords and the number following them or the largest number at the bottom half
    amount_keywords = [r"total", r"grand total", r"bayar", r"netto", r"jumlah", r"tunai"]
    
    potential_amounts = []
    # Find all numeric patterns that look like currency (10.000, 10,000, 10000)
    # We ignore very small numbers and dates
    money_pattern = r"(?:rp|rp\.)?\s?([0-9]{1,3}(?:[.,][0-9]{3})+|[0-9]{4,10})"
    
    # Check lines near keywords
    for i, line in enumerate(lines):
        line_lower = line.lower()
        if any(re.search(kw, line_lower) for kw in amount_keywords):
            # Check this line and the next 2 lines for money pattern
            search_context = " ".join(lines[i:i+3])
            match = re.search(money_pattern, search_context, re.IGNORECASE)
            if match:
                val = match.group(1).replace(".", "").replace(",", "")
                try: potential_amounts.append(float(val))
                except: pass

    if not potential_amounts:
        # Fallback: largest number in the bottom half of the text
        all_matches = re.finditer(money_pattern, raw_text, re.IGNORECASE)
        for match in all_matches:
            val = match.group(1).replace(".", "").replace(",", "")
            try: potential_amounts.append(float(val))
            except: pass

    if potential_amounts:
        total_amount = max(potential_amounts)

    # 4. Category Heuristics (Indonesian specialized)
    text_lower = raw_text.lower()
    mapping = {
        "Food": ["makan", "minum", "restoran", "kopi", "coffee", "cafe", "bakery", "warung", "indomaret", "alfamart", "alfamidi"],
        "Transport": ["bensin", "fuel", "pertamina", "gojek", "grab", "parkir", "tol"],
        "Shopping": ["baju", "pakaian", "sepatu", "tas", "mall", "fashion", "ecommerce", "shopee", "tokopedia"],
        "Bills": ["listrik", "pln", "pdam", "air", "wifi", "indihome", "telkom", "pulsa", "asuransi"],
        "Entertainment": ["bioskop", "xxi", "cgv", "tiket", "hiburan", "game", "netflix"]
    }
    
    for cat, keywords in mapping.items():
        if any(k in text_lower for k in keywords):
            category = cat
            break

    return {
        "store_name": store_name,
        "date": date,
        "total_amount": total_amount,
        "category": category
    }

@app.post("/ocr/scan")
async def scan_receipt(file: UploadFile = File(...)):
    contents = await file.read()
    processed_img, original_img = preprocess_image(contents)
    
    # 1. Run Layout Analysis (PP-StructureV3)
    # Structure works best on original or slightly enhanced color/gray images
    structure_res = structure(original_img)
    
    # 2. Extract Text (if structure didn't already handle it well)
    # We use PP-OCRv5 on the preprocessed (CLAHE + Denoised) image for best char recognition
    ocr_res = ocr.ocr(processed_img, cls=True)
    
    full_text = ""
    if ocr_res and ocr_res[0]:
        for line in ocr_res[0]:
            full_text += line[1][0] + "\n"
            
    # 3. Parse and return structured data
    structured_data = parse_text(full_text, layout_data=structure_res)
    
    # Final cleanup of results
    return {
        "raw_text": full_text.strip(),
        "structured": structured_data,
        "confidence": ocr_res[0][0][1][1] if ocr_res and ocr_res[0] else 0
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
