-- This query generates a row for every hour the patient is in the ICU.
-- The hours are based on clock-hours (i.e. 02:00, 03:00).
-- The hour clock starts 24 hours before the first heart rate measurement.
-- Note that the time of the first heart rate measurement is ceilinged to the hour.

-- this query extracts the cohort and every possible hour they were in the ICU
-- this table can be to other tables on ICUSTAY_ID and (ENDTIME - 1 hour,ENDTIME]

-- get first/last measurement time

CREATE MATERIALIZED VIEW mimiciv.icu_stay_hourly_mv AS

with all_hours as
(
select
  it.stay_id

  -- ceiling the intime to the nearest hour by adding 59 minutes then truncating
  -- note thart we truncate by parsing as string, rather than using DATETIME_TRUNC
  -- this is done to enable compatibility with psql
 -- , PARSE_DATETIME(
 --     '%Y-%m-%d %H:00:00',
 --     FORMAT_DATETIME(
 --       '%Y-%m-%d %H:00:00',
    , DATE_TRUNC('hour',it.intime_hr + INTERVAL '59 MINUTES')
   AS endtime
--	, it.intime_hr AS intt  -- can add to check
--	, it.outtime_hr AS outt -- can add to check
  -- create integers for each charttime in hours from admission
  -- so 0 is admission time, 1 is one hour after admission, etc, up to ICU disch
  --  we allow 24 hours before ICU admission (to grab labs before admit)
--	, generate_series(-24, (round(cast(extract(epoch from (it.outtime_hr - it.intime_hr)/3600 ) as numeric),0))) AS hrs 
	, generate_series(-24, (ceil(cast(extract(epoch from (it.outtime_hr - it.intime_hr)/3600 ) as numeric)))) AS hrs 
--  , GENERATE_ARRAY(-24, CEIL(DATETIME_DIFF(it.outtime_hr, it.intime_hr, HOUR))) as hrs
	
  from mimiciv.icustay_times_mv it
)
SELECT stay_id
, CAST(hrs AS integer) as hr
, (CAST(DATE_PART('hour', endtime) AS integer) + (CAST(hrs AS integer))) as endtime
-- , intt -- can add to check
-- , outt -- can add to check 
FROM all_hours

-- CROSS JOIN UNNEST(all_hours.hrs) AS hr; - I don't know what this achieves
-- CROSS JOIN UNNEST(array[all_hours.hrs]) AS hr2;  -- this works, but no extra output
-- cant get this last line to work. Series not an array. Nothing to unnest.
