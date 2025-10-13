from sales.extract import extract_fields, append_contact

with open('sales/sample-card.txt', 'r', encoding='utf-8') as fh:
	sample = fh.read()

contact = extract_fields(sample)
print('Extracted:', contact)
# Save to contacts.csv (append if not duplicate)
append_contact(contact)
