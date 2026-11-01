DECLARE target_date DATE DEFAULT DATE(
    '{{ params.target_execution_date }}'
);

BEGIN TRANSACTION;

DELETE FROM `{{ params.project }}.staging.stg_event`
WHERE
    added_date = target_date;

INSERT INTO
    `{{ params.project }}.staging.stg_event`
WITH
    src AS (
        SELECT
            *,
            PARSE_DATE (
                '%Y%m%d',
                CAST(
                    DIV(DATEADDED, 1000000) AS STRING
                )
            ) as derived_added_date
        FROM
            `gdelt-bq.gdeltv2.events_partitioned`
        WHERE
            _PARTITIONTIME = TIMESTAMP(target_date)
    )
SELECT
    GLOBALEVENTID as event_id,
    SQLDATE as sql_date,
    DATEADDED as date_added,
    Actor1Code as actor1_code,
    Actor1Name as actor1_name,
    Actor1CountryCode as actor1_country_code,
    Actor1Type1Code as actor1_type1_code,
    Actor1Type2Code as actor1_type2_code,
    Actor2Code as actor2_code,
    Actor2Name as actor2_name,
    Actor2CountryCode as actor2_country_code,
    Actor2Type1Code as actor2_type1_code,
    Actor2Type2Code as actor2_type2_code,
    EventCode as event_code,
    EventRootCode as event_root_code,
    QuadClass as quad_class,
    GoldsteinScale as goldstein_scale,
    NumMentions as num_mentions,
    NumSources as num_sources,
    NumArticles as num_articles,
    AvgTone as avg_tone,
    ActionGeo_CountryCode as action_geo_country_code,
    ActionGeo_Lat as action_geo_lat,
    ActionGeo_Long as action_geo_long,
    SOURCEURL as source_url,
    SAFE.PARSE_DATE (
        '%Y%m%d',
        CAST(SQLDATE AS STRING)
    ) AS event_date,
    derived_added_date as added_date,
    '{{ params.batch_id }}' AS batch_id,
    CURRENT_TIMESTAMP() as ingested_at
FROM src
WHERE
    derived_added_date = target_date;

COMMIT TRANSACTION;