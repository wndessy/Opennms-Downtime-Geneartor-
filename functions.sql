



   CREATE OR REPLACE FUNCTION downtime(startime timestamp,endtime timestamp)
	 -- RETURNS interval AS
	 RETURNS text AS
	$BODY$
	   DECLARE
	     startDate timestamp;
	     endDate timestamp;
	     statusComent text;
	     downtime interval;
	     loopstartDate timestamp;
	    woking_hours_per_day interval= '09:00:00'::time;
	   BEGIN
              statusComent ='--';
              downtime='00:00:00'::time;
              startDate =startime;
	      endDate = endtime;
	 loopstartDate=startime + interval '1 day';

              
              IF (date_part('DOY',startDate) = date_part('DOY', endDate)) THEN 
		    statusComent= statusComent||'::the same day';
		    IF date_part('DOW',startDate) NOT IN(0,6) THEN 

			    IF (startDate::time,endDate::time)OVERLAPS('00:00:01'::time ,'08:00:00'::time) AND (startDate::time,endDate::time)OVERLAPS('17:00:00'::time ,'23:59:59'::time)THEN 
				statusComent= statusComent || '::the whole working day';
				downtime=woking_hours_per_day;
			    ELSEIF (startDate::time,endDate::time)OVERLAPS('00:00:01'::time ,'08:00:00'::time) AND (startDate::time,endDate::time)OVERLAPS('08:00:01'::time ,'17:00:00'::time)THEN 
				 statusComent= statusComent || '::overlapse morning and working hours ';
				 downtime=(endDate::time -'08:00:00'::time );
			    ELSEIF (startDate::time,endDate::time)OVERLAPS('08:00:00'::time ,'17:00:00'::time) AND (startDate::time,endDate::time)OVERLAPS('17:00:00'::time ,'23:59:59'::time)THEN 
				 statusComent= statusComent || '::overlaps working and evening hours';
				  downtime=( '17:00:00'::time - startDate::time );
			    ELSEIF (startDate::time,endDate::time)OVERLAPS('08:00:00'::time ,'17:00:00'::time) AND NOT (startDate::time,endDate::time)OVERLAPS('17:00:00'::time ,'23:59:59'::time) AND 
			           NOT (startDate::time,endDate::time)OVERLAPS('00:00:00'::time ,'08:00:00'::time)THEN 
			        statusComent= statusComent || '::overlaps working hours only';
			        downtime=( endDate::time - startDate::time );
			    ELSE statusComent=statusComent || '::not categotized for time';
			    END IF;
		  --   ELSE statusComent= statusComent || '::weekend';
--                     END IF;
-- 	      ELSEIF  (date_part('DOY',endDate ) - date_part('DOY',startDate)=1) THEN 
-- 		       statusComent= statusComent || '::one Day diference';
-- 		       
                       ELSE statusComent=statusComent || '::It is a weekend';
                       END IF;
                        
	      ELSEIF  date_part('DOY',endDate ) - date_part('DOY',startDate) = 1 THEN 
		       statusComent= statusComent || '::one Day diference';
		    IF date_part('DOW',startDate) NOT IN(0,6) THEN 
                        IF startDate::time < '08:00:00' THEN
			    statusComent= statusComent || '::morning start ';
			    downtime=downtime+('17:00:00'::time - '08:00:00'::time);
			    ------no working hour
			ELSEIF startDate::time > '08:00:00' AND startDate::time < '17:00:00' THEN
			      statusComent= statusComent || '::workingHour start ';
				downtime= downtime + ('17:00:00'::time - startDate::time );
			ELSEIF  startDate::time >'17:00:00' THEN
			      statusComent= statusComent || '::evening start';
			      ---no working hour for the day
			END IF ;
                    ELSE statusComent=statusComent || '::It is a weekend';
                    END IF ;
		    IF date_part('DOW',endDate) NOT IN(0,6) THEN 
			IF endDate::time < '08:00:00' THEN
			      statusComent= statusComent || '::morning end ';                   
			    --no working hour 
			ELSEIF endDate::time > '08:00:00' AND endDate::time < '17:00:00' THEN
			      statusComent= statusComent || '::workingHour end ';
				downtime=downtime+(endDate::time - '08:00:00'::time );
			ELSEIF  endDate::time >'17:00:00' THEN
			      statusComent= statusComent || '::evening end ';
			  downtime=downtime+('09:00:00'::time );
			END IF ;
	            ELSE statusComent=statusComent || '::It is a weekend';
                    END IF;
	     ELSEIF date_part('DOY',endDate ) - date_part('DOY',startDate) > 1 THEN 			 
	   --getting the in between dates
	      statusComent = statusComent || '::More than 1 day diference ';
		WHILE date_part('DOY',loopstartDate) < date_part('doy',endDate) LOOP
		   IF date_part('DOW',loopstartDate) IN (0,6) THEN 
		       RAISE NOTICE 'WeekEnd: %', loopstartDate;
		     ELSE 
		       downtime= downtime + woking_hours_per_day;
		       RAISE NOTICE 'WeekDay: %', loopstartDate;
		     END IF;
		     loopstartDate= loopstartDate + interval '1 day';
		END LOOP;

               -- to cater for start date and end date 
               -- for start date
                    IF date_part('DOW',startDate) NOT IN (0,6)THEN
                     statusComent= statusComent || '::Weekday start ';
                        IF startDate::time < '08:00:00' THEN
			    statusComent= statusComent || '::morning start ';
			    downtime=downtime+('17:00:00'::time - '08:00:00'::time );
			    ------no working hour
			ELSEIF startDate::time > '08:00:00' AND startDate::time < '17:00:00' THEN
			      statusComent= statusComent || '::workingHour start ';
				downtime=downtime+('17:00:00'::time - startDate::time );
			ELSEIF  startDate::time >'17:00:00' THEN
			      statusComent= statusComent || '::evening start';
			      ---no working hour for the day
			END IF ;
		    ELSE statusComent= statusComent || '::Weekend Start' || startDate;
		    END IF;
		    -- fo end date	
		    IF date_part('DOW',endDate)NOT IN (0,6)THEN
		       statusComent= statusComent || '::Weekday end ';
			IF endDate::time < '08:00:00' THEN
			      statusComent= statusComent || '::morning end ';                   
			    --no working hour 
			ELSEIF endDate::time > '08:00:00' AND endDate::time < '17:00:00' THEN
			      statusComent= statusComent || '::workingHour end ';
				downtime=downtime+(endDate::time - '08:00:00'::time );
			ELSEIF  endDate::time >'17:00:00' THEN
			      statusComent= statusComent || '::evening end ';
			  downtime=downtime+('09:00:00'::time );
			END IF ;
		   ELSE statusComent= statusComent || '::Weekend end '|| endDate;	
		   END IF;
		
           ELSE  statusComent= '::NO chek' ;   
           END IF;
	    -- RETURN downtime ;
	    RETURN downtime || '::' ||statusComent;   
	 END ;
	 
	$BODY$
   LANGUAGE plpgsql ;

 
 WITH allTickets AS (SELECT * FROM all_tickets_detailed LEFT  JOIN device_real_names ON all_tickets_detailed.nodesysname=device_real_names.link_address
 WHERE  all_tickets_detailed.firsteventtime >='2016-04-01' AND  all_tickets_detailed.firsteventtime <= '2016-04-30' )

Select actual_name,nodesysname,provider_name,provider_ticket,tticketid ,alarmackuser,iflostservice,ifregainedservice,
downtime(iflostservice::timestamp,ifregainedservice::timestamp),downtime_cause From allTickets;

select * from all_tickets_detailed limit 10;
