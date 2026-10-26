CREATE TABLE IF NOT EXISTS `{{ params.project }}.mart.dim_date` OPTIONS (
    description = 'Date dimension, one row per calendar day'
) AS
SELECT
    CAST(
        FORMAT_DATE ('%Y%m%d', d) AS INT64
    ) AS date_key,
    d AS date,
    EXTRACT(
        YEAR
        FROM d
    ) AS year,
    EXTRACT(
        QUARTER
        FROM d
    ) AS quarter,
    EXTRACT(
        MONTH
        FROM d
    ) AS month,
    FORMAT_DATE ('%B', d) AS month_name,
    EXTRACT(
        ISOYEAR
        FROM d
    ) AS iso_year,
    EXTRACT(
        ISOWEEK
        FROM d
    ) AS iso_week,
    EXTRACT(
        DAY
        FROM d
    ) AS day,
    EXTRACT(
        DAYOFWEEK
        FROM d
    ) AS day_of_week, -- 1 = Sunday ... 7 = Saturday
    FORMAT_DATE ('%A', d) AS day_name,
    EXTRACT(
        DAYOFWEEK
        FROM d
    ) IN (1, 7) AS is_weekend
FROM UNNEST (
        GENERATE_DATE_ARRAY (
            DATE '2015-02-18', DATE '2035-12-31'
        )
    ) AS d;