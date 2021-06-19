-- This query extracts dose+durations of dopamine administration

CREATE MATERIALIZED VIEW mimiciv.dopamine_mv AS

select
stay_id, linkorderid
, rate as vaso_rate
, amount as vaso_amount
, starttime
, endtime
from mimic_icu.inputevents
where itemid = 221662 -- dopamine