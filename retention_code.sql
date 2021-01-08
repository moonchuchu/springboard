with users as
(
SELECT 
cp.people_rc_extension_id as userid,
to_date(cp.people_registered_at) as signupdate,
case when datediff(to_date(cp.people_registered_at),to_date(date_trunc('week',to_date(cp.people_registered_at)))) < 3 
then date_add(date_trunc('week',to_date(cp.people_registered_at)),2)
else date_add(date_add(date_trunc('week',to_date(cp.people_registered_at)),7),2) end as rep_week,
to_date(meeting.dt) as meet_host_dt

from 

 glip_mongo_production.company_people cp

left join 
         ( 
            SELECT people_rc_extension_id,callid,dt
            from
            (
                SELECT DISTINCT people_rc_extension_id,callid,to_date(dt) as dt
                FROM glip_mongo_production.company_people LEFT JOIN product_analytics_db.rcv_num_of_hosts
                ON partnerextensionid = Cast(people_rc_extension_id as string)
                where callid IN (SELECT distinct callid FROM product_analytics_db.rcv_callid_2_more_participants)
            )m
            group by 1,2,3
         )meeting on meeting.people_rc_extension_id = cp.people_rc_extension_id

where cast(cp.company_rc_account_id as STRING) in (select * from product_analytics_db.phoenix_free_accounts) 
)

select 
u.rep_week,
count(distinct u.userid) as totalsignups,
count(distinct u0.userid) as ret_week0,
count(distinct u1.userid) as ret_week1,
count(distinct u2.userid) as ret_week2

from users u 

left join users u0 on u.userid = u0.userid and datediff(u0.meet_host_dt,u.signupdate) between 0 and 6 
left join users u1 on u1.userid = u0.userid and datediff(u1.meet_host_dt,u0.signupdate) between 7 and 13
left join users u2 on u2.userid = u1.userid and datediff(u2.meet_host_dt,u1.signupdate) between 14 and 20
where
u.rep_week >= '2020-07-15'
group by 1 
order by 1