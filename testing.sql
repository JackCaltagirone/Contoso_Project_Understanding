-- Select the key identifiers for each sales line
SELECT 
    customerkey,          -- Unique ID for the customer who placed the order
    orderkey,             -- Unique ID for the order itself
    linenumber,           -- Line number within the order (each order can have multiple lines)

    -- Calculate the net revenue for this specific line item:
    -- quantity * netprice gives the total price in the original currency,
    -- multiplying by exchangerate converts it into a standard currency (e.g., EUR or USD)
    (quantity * netprice * exchangerate) AS net_revenue,

    -- Window function:
    -- Computes the average net revenue per line *for each customer*.
    -- PARTITION BY customerkey means:
    --   "Group rows by customer, but do NOT collapse them — return the average on every row."
    AVG(quantity * netprice * exchangerate)
        OVER (PARTITION BY customerkey) AS avg_revenue_per_unit

FROM sales

-- Sort the output so rows are grouped by customer
ORDER BY customerkey

-- Only return the first 10 rows of the sorted result
LIMIT 10;

--


SELECT
    customerkey as customer,
    orderdate,
    (quantity * netprice * exchangerate) AS net_revenue,
    row_number() over(
        PARTITION BY customerkey
        ORDER BY quantity * netprice * exchangerate DESC
    ) AS row_rank,
    sum(quantity * netprice * exchangerate) over(
        PARTITION by customerkey
        order by orderdate
    ) as customer_runningtotal

    from sales
    order by customerkey, orderdate desc  

    limit 10