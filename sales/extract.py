import os
import re
import csv
from PIL import Image
import pytesseract
import pandas as pd

INPUT_DIR = os.path.join(os.path.dirname(__file__), 'input')
OUTPUT_CSV = os.path.join(os.path.dirname(__file__), 'contacts.csv')

PHONE_RE = re.compile(r"(\+?\d[\d\s\-()]{6,}\d)")
EMAIL_RE = re.compile(r"[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+")


def ocr_image(path):
    try:
        img = Image.open(path)
    except Exception as e:
        print(f"Failed to open {path}: {e}")
        return ''
    text = pytesseract.image_to_string(img, lang='eng+kor')
    return text


def extract_fields(text):
    lines = [l.strip() for l in text.splitlines() if l.strip()]
    name = ''
    company = ''
    phone = ''
    email = ''

    # Heuristics: email first
    emails = EMAIL_RE.findall(text)
    if emails:
        email = emails[0]

    # phones
    phones = PHONE_RE.findall(text)
    if phones:
        phone = phones[0]

    # try to infer name/company from lines: usually top lines
    if lines:
        # assume first non-email, non-phone line is name
        for l in lines[:4]:
            if email and email in l: continue
            if any(p in l for p in phones): continue
            # skip words like 'Tel' etc
            if re.search(r'(?i)tel|fax|www|http', l):
                continue
            # if contains space and letters -> likely name
            if len(l.split()) <= 3 and re.search(r'[가-힣a-zA-Z]', l):
                if not name:
                    name = l
                    continue
        # company maybe the line after name or first line
        if not company:
            if len(lines) >= 2:
                company = lines[0] if lines[0] != name else lines[1]
            else:
                company = lines[0]

    return {'name': name, 'company': company, 'phone': phone, 'email': email}


def append_contact(contact):
    exists = False
    if os.path.exists(OUTPUT_CSV):
        df = pd.read_csv(OUTPUT_CSV)
        # simple duplicate by email or phone
        if contact['email'] and contact['email'] in df['email'].astype(str).values:
            exists = True
        if contact['phone'] and contact['phone'] in df['phone'].astype(str).values:
            exists = True
    else:
        df = pd.DataFrame(columns=['name','company','phone','email'])

    if not exists:
        # pandas.DataFrame.append was removed in recent pandas versions; use concat
        new_row = pd.DataFrame([contact])
        df = pd.concat([df, new_row], ignore_index=True)
        df.to_csv(OUTPUT_CSV, index=False)
        print('Saved contact:', contact)
    else:
        print('Contact already exists (by email or phone):', contact)


if __name__ == '__main__':
    if not os.path.exists(INPUT_DIR):
        os.makedirs(INPUT_DIR)
        print('Created input folder. Drop scanned business card images into:', INPUT_DIR)
    files = [os.path.join(INPUT_DIR, f) for f in os.listdir(INPUT_DIR) if f.lower().endswith(('.png','.jpg','.jpeg','.tiff'))]
    if not files:
        print('No images found in', INPUT_DIR)
    for f in files:
        print('Processing', f)
        text = ocr_image(f)
        contact = extract_fields(text)
        append_contact(contact)
