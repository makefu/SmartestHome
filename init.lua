-- servo
-- gpio.mode(2,gpio.OUTPUT)



wifi.setmode(wifi.STATION)
wifi.sta.config("shack","dickbutter")
buf=string.char( 255,0, 0)

default_buf = buf
ledpin=2

ws2812.write(ledpin,buf)
dofile("door_stuff.lc")
dofile("esp_display_status.lc")
dofile("fadesrv.lc")
