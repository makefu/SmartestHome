dp= 3
doortimerid = 4
door_status= false -- false: close, open: true

function stop_door()
    pwm.stop(dp)
    pwm.close(dp)
end

function open_door()
    stop_windrad()
    door_status = true
    pwm.setup(dp,50,50)
    pwm.start(dp)
    tmr.alarm(doortimerid,1000,0,stop_door)
end

function close_door()
    stop_windrad()
    door_status = false
    pwm.setup(dp,50,140) --< max closed: 140
    pwm.start(dp)
    tmr.alarm(doortimerid,1000,0,stop_door)
end

wp = 5 --< windrad pin
windradtmrid= 5 
function stop_windrad()
    pwm.setduty(wp,0)
    pwm.stop(wp)
    pwm.close(wp)
end

function start_windrad(seconds)
    stop_door()
    pwm.setup(wp,50,700) --< windrad
    pwm.setduty(wp,700)
    pwm.start(wp)
    tmr.alarm(windradtmrid,seconds*1000,0,stop_windrad)
end

start_windrad(6)
-- at first we reuse the door timer
tmr.alarm(4,10000,0,function()
    open_door()
    -- then we reuse the windrad
    tmr.alarm(5,5000,0,function()
        close_door()
    end)
end)

