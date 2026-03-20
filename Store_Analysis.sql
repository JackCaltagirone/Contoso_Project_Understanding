-- =====================================================================
-- Purpose:
-- Analyse store performance by exploring the relationship between
-- store size, store location, and sales outcomes. This establishes a
-- baseline understanding of whether larger stores generate higher
-- revenue or profit, how performance varies across states and countries,
-- and whether size and geography interact to influence sales efficiency.
-- =====================================================================


--getting all countries grouped and checking total square meters
SELECT
    countryname,
    countrycode,
    SUM(squaremeters) AS total_squaremeters_by_country
FROM store
GROUP BY
    countryname,
    countrycode
ORDER BY
    total_squaremeters_by_country DESC;

--next just to check, each country im going to get the total sales for
WITH store_sizes AS (
    SELECT
        countryname,
        countrycode,
        SUM(squaremeters) AS total_squaremeters_by_country
    FROM store
    GROUP BY
        countryname,
        countrycode
),
country_sales AS (
    SELECT
        s.countryname,
        s.countrycode,
        ROUND(SUM(sa.netprice)::numeric, 2) AS total_revenue,
        ROUND(SUM(sa.netprice - sa.unitcost)::numeric, 2) AS total_profit
    FROM store AS s
    JOIN sales AS sa
        ON s.storekey = sa.storekey
    GROUP BY
        s.countryname,
        s.countrycode
)
SELECT
    ss.countryname,
    ss.countrycode,
    ss.total_squaremeters_by_country,
    cs.total_revenue,
    cs.total_profit
FROM store_sizes ss
JOIN country_sales cs
    ON ss.countryname = cs.countryname
WHERE ss.countryname <> 'Online' -- take out the online store
ORDER BY
    cs.total_revenue DESC;


--got some good info here. near a direct correlations between store size and revenue.
--next going to check the top 50 largest stores and their profit margins
WITH store_sales AS (
    SELECT
        sa.storekey,
        ROUND(SUM(sa.netprice)::numeric, 2) AS revenue,
        ROUND(SUM(sa.netprice - sa.unitcost)::numeric, 2) AS profit,
        SUM(sa.quantity) AS total_items_sold
    FROM sales sa
    GROUP BY sa.storekey
),
store_ranked AS (
    SELECT
        s.storekey,
        s.countryname,
        s.state,
        s.squaremeters,
        ss.revenue,
        ss.profit,
        ss.total_items_sold,
        CASE 
            WHEN ss.revenue = 0 THEN 0
            ELSE ROUND((ss.profit / ss.revenue)::numeric, 4)
        END AS profit_margin
    FROM store s
    LEFT JOIN store_sales ss
        ON s.storekey = ss.storekey
    WHERE s.countryname <> 'Online'
)
SELECT *
FROM store_ranked
ORDER BY squaremeters DESC
LIMIT 50;


--checking top preforming stores by total profit froms sales
WITH add_sales AS (
    SELECT
        s.storekey,
        ROUND(SUM(netprice - unitcost)::numeric, 2) AS store_sales_profit
    FROM sales AS s
    GROUP BY s.storekey
),
add_store AS (
    SELECT
        st.storekey,
        st.countryname,
        st.state,
        s.store_sales_profit
        
    FROM store AS st
    LEFT JOIN add_sales AS s
        ON st.storekey = s.storekey

            where s.store_sales_profit is not null
)
SELECT *
FROM add_store

order by store_sales_profit desc


--

WITH customer_count AS (
    SELECT
        st.geoareakey,
        COUNT(DISTINCT s.customerkey) AS total_customers
    FROM sales AS s
    JOIN store AS st
        ON s.storekey = st.storekey
    GROUP BY st.geoareakey
),
add_sales AS (
    SELECT
        st.geoareakey,
        ROUND(SUM(netprice - unitcost)::numeric, 2) AS store_sales_profit
    FROM sales AS s
    JOIN store AS st
        ON s.storekey = st.storekey
    GROUP BY st.geoareakey
),
store_details AS (
    SELECT DISTINCT
        st.geoareakey,
        st.countryname,
        st.state,
        cc.total_customers,
        sa.store_sales_profit
    FROM store AS st
    LEFT JOIN customer_count AS cc
        ON st.geoareakey = cc.geoareakey
    LEFT JOIN add_sales AS sa
        ON st.geoareakey = sa.geoareakey
    WHERE st.countryname <> 'Online'
      AND st.closedate IS NULL
)
SELECT *
FROM store_details
ORDER BY total_customers DESC;


