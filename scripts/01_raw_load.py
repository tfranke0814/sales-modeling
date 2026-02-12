import os
from dotenv import load_dotenv
import pandas as pd
from sqlalchemy import create_engine

load_dotenv()

def main():
    df = pd.read_csv("./kaggle/input/sales-forecasting/train.csv")

    # Preprocessing
    df.columns = df.columns.str.lower().str.replace(r"[\s-]+", "_", regex=True)
    df['order_date'] = pd.to_datetime(df['order_date'], format="%d/%m/%Y")
    df['ship_date'] = pd.to_datetime(df['ship_date'], format="%d/%m/%Y")

    df.info()

    # load into PostgreSQL
    engine = create_engine(os.getenv('DATABASE_URL')) # type: ignore
    df.to_sql("raw_sales_data", engine, index=False, if_exists="replace")


if __name__ == "__main__":
    main()