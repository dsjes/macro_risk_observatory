DECLARE target_date DATE DEFAULT DATE(
    '{{params.target_execution_date}}'
);

DECLARE min_event_date DATE;

DECLARE max_event_date DATE;

SET(
    min_event_date,
    max_event_date
) = (
    SELECT AS STRUCT MIN(event_date), MAX(event_date)
    FROM `{{params.project}}.staging.stg_event`
    WHERE
        added_date = target_date
        AND batch_id = '{{params.batch_id}}'
);

MERGE `{{params.project}}.mart.fct_event` AS t USING (
    SELECT
        event_id,
        event_date,
        CAST(
            FORMAT_DATE ('%Y%m%d', event_date) AS INT64
        ) AS date_key,
        actor1_code,
        actor2_code,
        actor1_country_code,
        actor2_country_code,
        actor1_type1_code,
        actor2_type1_code,
        CONCAT(
            LEAST(
                actor1_country_code,
                actor2_country_code
            ),
            '-',
            GREATEST(
                actor1_country_code,
                actor2_country_code
            )
        ) AS dyad_key,
        event_code AS cameo_code,
        event_root_code,
        quad_class,
        action_geo_country_code,
        action_geo_lat AS lat,
        action_geo_long AS lon,
        goldstein_scale,
        avg_tone,
        num_mentions,
        num_articles,
        source_url
    FROM `{{params.project}}.staging.stg_event`
    WHERE
        added_date = target_date
        AND batch_id = '{{params.batch_id}}'
        AND event_date IS NOT NULL
    QUALIFY
        ROW_NUMBER() OVER (
            PARTITION BY
                event_id
            ORDER BY date_added DESC
        ) = 1
) AS s ON t.event_id = s.event_id
AND t.event_date BETWEEN min_event_date AND max_event_date  WHEN MATCHED THEN
UPDATE
SET
    event_date = s.event_date,
    date_key = s.date_key,
    actor1_code = s.actor1_code,
    actor2_code = s.actor2_code,
    actor1_country_code = s.actor1_country_code,
    actor2_country_code = s.actor2_country_code,
    actor1_type1_code = s.actor1_type1_code,
    actor2_type1_code = s.actor2_type1_code,
    dyad_key = s.dyad_key,
    cameo_code = s.cameo_code,
    event_root_code = s.event_root_code,
    quad_class = s.quad_class,
    action_geo_country_code = s.action_geo_country_code,
    lat = s.lat,
    lon = s.lon,
    goldstein_scale = s.goldstein_scale,
    avg_tone = s.avg_tone,
    num_mentions = s.num_mentions,
    num_articles = s.num_articles,
    source_url = s.source_url,
    batch_id = '{{ params.batch_id }}',
    updated_at = CURRENT_TIMESTAMP() WHEN NOT MATCHED THEN
INSERT (
        event_id,
        event_date,
        date_key,
        actor1_code,
        actor2_code,
        actor1_country_code,
        actor2_country_code,
        actor1_type1_code,
        actor2_type1_code,
        dyad_key,
        cameo_code,
        event_root_code,
        quad_class,
        action_geo_country_code,
        lat,
        lon,
        goldstein_scale,
        avg_tone,
        num_mentions,
        num_articles,
        source_url,
        batch_id,
        updated_at
    )
VALUES (
        s.event_id,
        s.event_date,
        s.date_key,
        s.actor1_code,
        s.actor2_code,
        s.actor1_country_code,
        s.actor2_country_code,
        s.actor1_type1_code,
        s.actor2_type1_code,
        s.dyad_key,
        s.cameo_code,
        s.event_root_code,
        s.quad_class,
        s.action_geo_country_code,
        s.lat,
        s.lon,
        s.goldstein_scale,
        s.avg_tone,
        s.num_mentions,
        s.num_articles,
        s.source_url,
        '{{ params.batch_id }}',
        CURRENT_TIMESTAMP()
    );