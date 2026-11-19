# Swiggy Customer Experience & Operational Root Cause Analytics

An end-to-end **Product & Business Analytics** portfolio project investigating delivery SLA breaches, customer sentiment drivers, and revenue leakage across 220 Swiggy orders in 6 Indian metro cities.

---

## 1. Business Problem
Between October and November 2026, customer satisfaction (CSAT) dropped to **2.88 / 5.0**, accompanied by elevated refund payouts. Operational logistics data (delivery times, order values, refunds) was siloed from unstructured customer reviews, preventing product and operations teams from pinpointing the exact root causes of customer churn and financial loss.

---

## 2. Tech Stack & Architecture
* **Data Cleaning & AI Enrichment (Python, Pandas, Groq LLM API):** Standardized raw transactional records, removed duplicates/nulls, and classified unstructured customer reviews into structured root-cause categories and departmental action owners.
* **Relational Modeling & Analysis (MySQL 8.0+):** Designed a normalized schema (`fact_order_operations` and `fact_swiggy_reviews`), authored 7 analytical queries using `JOIN`, `CASE WHEN`, `CTEs`, and `Window Functions (RANK, DENSE_RANK)`, and created a consolidated reporting view (`vw_swiggy_operational_kpis`).
* **Business Intelligence & Reporting (Power BI & DAX):** Built a 2-page interactive dashboard tailored for Product Analysts (app health & sentiment) and Business Analysts (SLA hotspots & financial leakage).

---

## 3. Key Quantitative Findings
* **Total GMV Analyzed:** ₹1,82,628 across 220 completed orders.
* **Delivery SLA Breach Rate:** **67.3%** of orders missed their promised delivery window, with **Bangalore** and **Chennai** showing severe failure rates on aggressive 25-minute SLA tiers.
* **Revenue at Risk:** **₹1,66,162 (91.0% of GMV)** was tied to orders experiencing severe delays (>15 mins) or negative customer sentiment.
* **Direct Refund Loss:** **₹43,855 (24.0% of GMV)** leaked directly through customer refunds, driven primarily by **Operations & Fleet (₹15.8K)** and **Restaurant Partners (₹14.3K)**.
* **Top Defect Drivers:** Food Quality / Wrong Item (**29.5%**), Delivery & Logistics Delay (**21.8%**), and App Bug / Tech Glitch (**16.4%**).

---

## 4. Power BI Dashboard Previews

### Page 1: Product Analyst View (App Health & Sentiment)
<img width="1920" height="1080" alt="dashboard_page1_product_analyst" src="https://github.com/user-attachments/assets/649d7803-244f-4c7d-aed0-86c8ea1005b1" />


### Page 2: Business Analyst View (Operations, SLA & Financial Risk)
<img width="1920" height="1080" alt="dashboard_page2_business_analyst" src="https://github.com/user-attachments/assets/20b48de5-ece0-4ca0-ba0b-7771642b8a46" />


---

## 5. Strategic Recommendations
1. **Dynamic SLA Recalibration (Operations & Fleet):** Adjust promised delivery times in traffic-heavy zones (Bangalore, Delhi NCR, Chennai) from 25 minutes to 30–35 minutes during peak hours to protect SLA compliance.
2. **Partner Quality Checklists (Restaurant Partners):** Introduce mandatory packaging and order-verification prompts at high-defect partner outlets to curb wrong/spilled item complaints.
3. **Checkout & Live-Tracking Stability (Product & Tech):** Prioritize bug fixes for payment/coupon glitches and map freezes (16.4% of defect tickets) to recover ₹30.5K in tech-attributed Revenue at Risk.

---

## 6. Repository Structure
├── data/
│   ├── fact_order_operations.csv       # Cleaned transactional & delivery SLA dataset
│   └── fact_swiggy_reviews.csv         # AI-classified reviews & root-cause taxonomy
├── sql/
│   └── swiggy_analytics_queries.sql    # Schema DDL, 7 business queries (CTEs/Window Functions) & BI View
├── dashboard/
│   ├── Swiggy_Operations_CX_Dashboard.pbix
│   ├── dashboard_page1_product_analyst.png
│   └── dashboard_page2_business_analyst.png
└── README.md
