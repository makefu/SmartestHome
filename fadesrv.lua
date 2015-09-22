-- uses:
-- default_buf
-- buf
-- ledpin

local function handle_request(client,request)
   local _, _, method, path, vars = string.find(request, "([A-Z]+) (.+)?(.+) HTTP");
   if(method == nil)then
       _, _, method, path = string.find(request, "([A-Z]+) (.+) HTTP");
   end
   local _GET = {}
   if (vars ~= nil)then
       for k, v in string.gmatch(vars, "(%w+)=([%w.]+)&*") do
           _GET[k] = v
       end
   end

   client:send("HTTP/1.1 200 OK\r\n")
   client:send("Content-Type: text/html\r\n")
   client:send("Connection: close\r\n")
   client:send("\r\n")
   --  end preprocessing

   function send_file(f)
     file.open(f,"r")
     block = file.read(1024)
     while block do
       client:send(block)
       block = file.read(1024)
     end
     file.close()
   end
   if path == '/' then
        local ip,_,_=wifi.sta.getip()
        send_file('head.html')

        client:send("<div class='list-group'>")
        function send_item(a,b)
                client:send(string.format(
            "<a href='#' class='list-group-item'>%s: <b>%s</b></a>",
            a,b))
        end
        send_item("IP",ip)
        send_item("MAC",wifi.sta.getmac())
        send_item("Temperature / Humitidy ",
              string.format("%d℃ / %d%%",temp,humi))
        send_item("DNS Time (max)",
              string.format("%4dms (%4dms)",dns_time,max_dns_time))
        send_item("Google Time (max)",
              string.format("%4dms (%4dms)",http_time,max_http_time))
        send_item("LED State (rgb)",
              string.format("%d %d %d",buf:byte(2),buf:byte(1),buf:byte(3)))
        send_item("Uptime",
              string.format("%d seconds",tmr.time()))
        send_item("Door Status",
              string.format("%s",door_status and "open" or "closed"))
        client:send("</div>")
        send_file('end.html')
   elseif path == '/code.js' then
        send_file('code.js')
   elseif path == '/on' then
        client:send("LEDs are now on")
        buf = default_buf
        ws2812.write(ledpin,buf)
   elseif path == '/off' then
        buf = "LEDs are now off"
        buf=string.char(0,0,0)
        ws2812.write(ledpin,buf)
   elseif path == '/color' then
        local r = tonumber(_GET.r or 0)
        local g = tonumber(_GET.g or 0)
        local b = tonumber(_GET.b or 0)
        client:send("setting LEDS to ("..r..","..g..","..b..")")
        buf = string.char(g,r,b)
        ws2812.write(ledpin,buf)
   elseif path == '/restart' then
        client:send("bye")
        node.restart()
   elseif path == '/door/open' then
        open_door()
   elseif path == '/windrad' then
        start_windrad(5)
   elseif path == '/door/close' then
        close_door()
   else
        client:send("unknown path "..path)
   end

   client:close()
   collectgarbage()
end

srv=net.createServer(net.TCP,1)
srv:listen(80,function(conn)
    conn:on("receive", handle_request)
end)
