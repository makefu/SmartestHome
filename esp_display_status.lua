sda = 6 -- gpio12
scl = 7 -- gpio13
sla = 0x3c -- slave address

disp = nil
dns_in_progress=false
http_in_progress=false
dns_time=-1
max_dns_time=-1
http_time=-1
max_http_time=-1
temp=-99
humi=-1


tmrid=0
tmrid2=1
tmrid3=2
tmrid4=3

dht_pin = 4

local http_req="GET / HTTP/1.1\r\nHost: www.google.com\r\nConnection: keep-alive\r\nAccept: */*\r\n\r\n"
max_timeout=9999
refresh_interval=15000
local max_refresh_interval=60000 * 5

sk=net.createConnection(net.TCP, 0)
counter=0


ident="smart_home"
m = mqtt.Client(ident,120)
mqtt_host="10.42.2.135"
mqtt_port=1883
connected=false

-- connect in 1s to mqtt
tmr.alarm(6,1000,0,function()
    m:connect(mqtt_host,mqtt_port,0,function()
       connected=true
       print("init connect")
    end)
end)

m:on("connect", function(con)
    print ("connected")
    connected=true
end)
m:on("offline", function(con)
    print ("offline")
    connected=false
end)
m:lwt("/lwt", string.format("%s died",ident), 0, 0)

local function refresh_display()
    function draw()
        local ip,_,_=wifi.sta.getip()
        if not ip then ip = "NO IP" end
        disp:drawStr(0,0,"smarthome.shack")
        -- degree
        disp:drawStr(0,10, string.format("TEMP:  %d%sC %d%%",temp,string.char(176),humi))
        --disp:drawStr(0,10, string.format("IP  :%15s",ip))
        disp:drawStr(0,20,string.format("DNS :%4dms (%4dms)",dns_time,max_dns_time))
        disp:drawStr(0,30,string.format("HTTP:%4dms (%4dms)",http_time,max_http_time))
        disp:drawStr(0,40,string.format("LED :  %d %d %d",buf:byte(2),buf:byte(1),buf:byte(3)))
        disp:drawStr(0,50,string.format("UP  : %d seconds",tmr.time()))
    end
    dht_status()
    disp:firstPage()
    repeat
        draw()
    until disp:nextPage() == false
    if connected then
     m:publish(string.format("/sensor/temp/%s",ident),string.format("%d",temp),0,0)
     m:publish(string.format("/sensor/humi/%s",ident),string.format("%d",humi),0,0)
     m:publish(string.format("/timer/dns/%s",ident),string.format("%d",dns_time),0,0)
     m:publish(string.format("/timer/http/%s",ident),string.format("%d",http_time),0,0)
     m:publish(string.format("/timer/uptime/%s",ident),string.format("%d",tmr.time()),0,0)
    end

end

function dht_status()
    status,tmp_temp,tmp_humi,_,_ = dht.read11(dht_pin)
    if( status == dht.OK ) then
        temp = tmp_temp
        humi = tmp_humi
    end

end
function dns_status()
    if http_in_progress then return end

    http_in_progress = true
    dns_in_progress=true
    local begin=tmr.now()
    counter= counter + 1
    sk:close()
    sk = nil
    sk = net.createConnection(net.TCP, 0)

    sk:dns("www.google.com",function(conn,ip)

        dns_time=(tmr.now()-begin)/1000
        dns_in_progress=false
        if dns_time > max_dns_time then max_dns_time=dns_time  end

        sk:on("receive", function(sck, c)
            http_time=(tmr.now()-begin)/1000
            http_in_progress=false
            if http_time > max_http_time then max_http_time=http_time  end
            tmr.stop(tmrid2)
            refresh_display()
            end

            )
        sk:connect(80,ip)
        sk:send(http_req)
    end)

    local function trigger_timer()
        if dns_in_progress then
          max_dns_time = max_timeout
          dns_time=max_timeout
        end
        if http_in_progress then
            max_http_time = max_timeout
            http_time=max_timeout
        end
        dns_in_progress = false
        http_in_progress=false
        refresh_display()

    end
    -- last resort timer
    -- this timer will be disabled once the 'connect' succeeded
    tmr.alarm(tmrid2,max_timeout,0,trigger_timer)
end

local function reset_max_timer()
            max_dns_time= dns_time
            max_http_time=http_time
end

tmr.alarm(tmrid,refresh_interval,1,dns_status)
tmr.alarm(tmrid4,max_refresh_interval,1,reset_max_timer)

dht_status()

i2c.setup(0, sda, scl, i2c.SLOW)
disp = u8g.ssd1306_128x64_i2c(sla)


disp:setFont(u8g.font_6x10)
disp:setFontRefHeightExtendedText()
disp:setDefaultForegroundColor()
disp:setFontPosTop()

