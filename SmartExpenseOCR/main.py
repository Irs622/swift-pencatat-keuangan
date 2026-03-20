import os
import cv2
import numpy as np
from fastapi import FastAPI, File, UploadFile
from paddleocr import PaddleOCR
from PIL import Image
import io

app = FastAPI()

# Initialize PaddleOCR (Indonesian/English support)
ocr = PaddleOCR(use_angle_cls=True, lang='en') # 'en' works well for most receipts, can add 'id' if needed

def preprocess_image(image_bytes):
    # Convert bytes to numpy array
    nparr = np.frombuffer(image_bytes, np.uint8)
    img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
    
    # 1. Grayscale conversion
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    
    # 2. Increase contrast (CLAHE - Contrast Limited Adaptive Histogram Equalization)
    clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8,8))
    contrast = clahe.apply(gray)
    
    # 3. Denoising
    denoised = cv2.fastNlMeansDenoising(contrast, None, 10, 7, 21)
    
    # 4. Thresholding (to make text stand out)
    _, thresh = cv2.threshold(denoised, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
    
    return thresh

import re
from datetime import datetime

# ... (previous imports)

def parse_text(raw_text):
    lines = raw_text.split("\n")
    store_name = "Unknown Store"
    total_amount = 0.0
    date = datetime.now().strftime("%Y-%m-%d")
    category = "Others"
    
    # 1. Extract Store Name (First non-empty line usually)
    for line in lines:
        clean_line = line.strip()
        if clean_line and len(clean_line) > 3:
            store_name = clean_line
            break
            
    # 2. Extract Amount
    # RegEx for Indonesian formats: 10.000, 15,000, Rp 25.000
    amounts = []
    amount_pattern = r"(?:rp|rp\.)?\s?([0-9]{1,3}(?:[.,][0-9]{3})*|[0-9]+)"
    matches = re.finditer(amount_pattern, raw_text, re.IGNORECASE)
    for match in matches:
        val_str = match.group(1).replace(".", "").replace(",", "")
        try:
            amounts.append(float(val_str))
        except:
            continue
    if amounts:
        total_amount = max(amounts)

    # 3. Simple Category Heuristics
    text_lower = raw_text.lower()
    if any(k in text_lower for k in ["kopi", "coffee", "cafe", "starbucks"]):
        category = "Food"
    elif any(k in text_lower for k in ["bensin", "fuel", "gojek", "grab", "pertamina"]):
        category = "Transport"
    elif any(k in text_lower for k in ["mall", "clothe", "baju", "fashion"]):
        category = "Shopping"
    elif any(k in text_lower for k in ["listrik", "pln", "pulsa", "wifi"]):
        category = "Bills"

    return {
        "store_name": store_name,
        "date": date,
        "total_amount": total_amount,
        "category": category
    }

@app.post("/ocr/scan")
async def scan_receipt(file: UploadFile = File(...)):
    contents = await file.read()
    processed_img = preprocess_image(contents)
    result = ocr.ocr(processed_img, cls=True)
    
    full_text = ""
    if result and result[0]:
        for line in result[0]:
            full_text += line[1][0] + "\n"
            
    # Parse into structured data
    structured_data = parse_text(full_text)
    
    return {
        "raw_text": full_text.strip(),
        "structured": structured_data
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
