import os
import pandas as pd
from tabulate import tabulate

CSV = os.path.join(os.path.dirname(__file__), 'contacts.csv')


def show():
    if not os.path.exists(CSV):
        print('No contacts yet. Run extract.py first or add contacts.csv')
        return
    df = pd.read_csv(CSV)
    print(tabulate(df, headers='keys', tablefmt='github', showindex=False))
    # export option
    out = os.path.join(os.path.dirname(__file__), 'contacts.xlsx')
    df.to_excel(out, index=False)
    print('Exported to', out)


if __name__ == '__main__':
    show()
