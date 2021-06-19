-- This query extracts dose+durations of epinephrine administration

CREATE MATERIALIZED VIEW mimiciv.epinephrine_mv AS

select
stay_id, linkorderid
, rate as vaso_rate
, amount as vaso_amount
, starttime
, endtime
from mimic_icu.inputevents
where itemid = 221289 -- epinephrine