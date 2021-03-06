using Toybox.System;
using Toybox.WatchUi;
using Toybox.SensorHistory;
using Toybox.Lang;
using Toybox.Graphics;
using Toybox.Time;
using Toybox.Time.Gregorian as Calendar;
using Toybox.ActivityMonitor as Monitor;
using Toybox.Math as Math;

class watchfacegenesysanalogView extends WatchUi.WatchFace {

    var lowPowerMode = false;
    var lowPowerModeMin = null; // minutes when low power mode got set
    
    function initialize() {
        WatchFace.initialize();
    }
    	
    // Load your resources here
    function onLayout(dc) {
    	setLayout(Rez.Layouts.WatchFace(dc));
    }
    
    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() {
    }
    
    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() {
    }

	// The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() {
	    lowPowerMode = false;
	    WatchUi.requestUpdate();     
    }

	// Terminate any active timers and prepare for slow updates.
    function onEnterSleep() {
	    lowPowerMode = true;
	    WatchUi.requestUpdate();
    }
    
    // Update the view
    function onUpdate(dc) {
		
        var clockTime  = System.getClockTime();
        
		// refresh only every minute
 		if(lowPowerMode) {
 			if(lowPowerModeMin != null && lowPowerModeMin == clockTime.min) {
 				return;
 			}
 			lowPowerModeMin = clockTime.min;
 		} else {
 			lowPowerModeMin = null;
 		}	
 		
 		refreshDisplay(dc, clockTime);		                
    }
    
    // --- Sensor History ---
	function getIteratorTemperature() {
	    // Check device for SensorHistory compatibility
	    if ((Toybox has :SensorHistory) && (Toybox.SensorHistory has :getTemperatureHistory)) {
	        return Toybox.SensorHistory.getTemperatureHistory({});
	    }
	    return null;
	}
	
	function getIteratorHeartRate() {
	    // Check device for SensorHistory compatibility
	    if ((Toybox has :SensorHistory) && (Toybox.SensorHistory has :getHeartRateHistory)) {
	        return Toybox.SensorHistory.getHeartRateHistory({});
	    }
	    return null;
	}
    
    function refreshDisplay(dc, clockTime) {
    	// refresh
 		View.onUpdate(dc);
 		
 		var width      = dc.getWidth();
        var height     = dc.getHeight();
        
        // --- TIME ---
        var angleHour, angleMin, angleSec;
 		var hour = ((clockTime.hour % 12) * 60.0 + clockTime.min) / 60.0;        
        angleHour = ((hour * 5.0) / 60.0) * Math.PI * 2;
        // System.println("Hours=" + hour + " => " + angleHour );
        angleMin = ( clockTime.min / 60.0) * Math.PI * 2;
        // System.println("Minutes=" + clockTime.min + " => " + angleMin );
        angleSec = ( clockTime.sec / 60.0) * Math.PI * 2;
        // System.println("Seconds=" + clockTime.sec + " => " + angleSec + " = " + angleSec * 360 / (2 * Math.PI));
    	drawHand(dc, width/2, height/2, angleHour, 0, 45, 10, 5); 	// hours
    	drawHand(dc, width/2, height/2, angleMin, 0, 80, 7, 4);		// minutes
		if(!lowPowerMode) {       
        	drawHandRound(dc, width/2, height/2, angleSec, 112, 5, 4); // seconds
		}
		
		// --- DATE ---
        var calendar = Calendar.info(Time.now(), Time.FORMAT_LONG);
        //var dateString = Lang.format("$1$, $2$ $3$", [calendar.day_of_week, calendar.month, calendar.day]);
        var dateString = Lang.format("$1$ $2$", [calendar.day_of_week, calendar.day]);
        dc.drawText(
	        dc.getWidth() / 2,
	        dc.getHeight() / 2 + 85,
	        Graphics.FONT_XTINY,
	        dateString,
	        Graphics.TEXT_JUSTIFY_CENTER
	    );
	    
	    // --- Battery ---
        var x = (dc.getWidth() - 28)/2;
	    drawBattery(dc, System.getSystemStats().battery, x, 18, 25, 10);
	    	    		
		/*
		// --- Temperature ---
		var sensorIter = getIteratorTemperature();
		if (sensorIter != null) {
		    // System.println(sensorIter.next().data);
		    dc.drawText(
		        dc.getWidth() / 2 + 30,
		        dc.getHeight() / 2 + 30,
		        Graphics.FONT_LARGE,
		        sensorIter.next().data.format("%02d"),
		        Graphics.TEXT_JUSTIFY_CENTER
		    );
		    dc.setPenWidth(1);
		    dc.drawCircle(dc.getWidth() / 2 + 45,dc.getHeight() / 2 + 40,2);
		}*/
		/*
		// --- HeartRate ---
		var sensorIterHeartRate = getIteratorHeartRate();
		if (sensorIterHeartRate != null) {
		    //System.println(sensorIterHeartRate.next().data);
		    dc.drawText(
		        17,
		        (dc.getHeight()-30) / 2,
		        Graphics.FONT_XTINY,
		        sensorIterHeartRate.next().data.format("%02d"),
		        Graphics.TEXT_JUSTIFY_LEFT
		    );
		    //drawHand(dc, 25, height/2+15, 0.7, 0, 8, 3, 3);
		    //drawHand(dc, 25, height/2+15, -0.7, 0, 8, 3, 3);
		}
		*/
    }
    
    function drawWithRotate(dc, coords, cos, sin, centerX, centerY) {
    	var coordsRotated = new [coords.size()];

		for (var i = 0; i < coords.size(); i += 1)
        {
            var x = (coords[i][0] * cos) - (coords[i][1] * sin);
            var y = (coords[i][0] * sin) + (coords[i][1] * cos);
            coordsRotated[i] = [ centerX+x, centerY+y];
        }
        dc.fillPolygon(coordsRotated);
    }

    function drawHand(dc, centerX, centerY, angle, distIn, distOut, radius, width) {
		
		// Math
		var cos = Math.cos(angle);
		var sin = Math.sin(angle);
		
		// 2 x Arcs		
		var x1 = centerX + (distOut * sin);
        var y1 = centerY - (distOut * cos);
        var x2 = centerX + (distIn * sin);
        var y2 = centerY - (distIn * cos);
                 
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT); 
        dc.setPenWidth(width);
              
        var angleArcStart = - ((angle * 360 / (2 * Math.PI)) + 90); 
        dc.drawArc(x1, y1, radius, Graphics.ARC_CLOCKWISE, angleArcStart - 90, angleArcStart + 90);
        dc.drawArc(x2, y2, radius, Graphics.ARC_CLOCKWISE, angleArcStart + 90, angleArcStart + 270);
        
        // Circle
        //drawHandRound(dc, centerX, centerY, angle, distOut, radius, width);
        //drawHandRound(dc, centerX, centerY, angle, distIn, radius, width);
        
        // 2 x Bars
        var length = distOut-distIn+1;
        var coords = [[radius + width/2, -distIn], [radius + width/2, -distIn-length], [radius - width/2, -distIn-length], [radius - width/2, -distIn]];
        drawWithRotate(dc, coords, cos, sin, centerX, centerY);
        
        coords = [[-radius + width/2, -distIn], [-radius + width/2, -distIn-length], [-radius - width/2, -distIn-length], [-radius - width/2, -distIn]];
        drawWithRotate(dc, coords, cos, sin, centerX, centerY);
    }
    
    function drawHandRound(dc, centerX, centerY, angle, dist, radius, width) {
    	dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT); 
        dc.setPenWidth(width);
    
		var cos = Math.cos(angle);
		var sin = Math.sin(angle);
		var x = centerX + (dist * sin);
        var y = centerY - (dist * cos);
                        
        dc.drawCircle(x,y,radius);        
    }
    
    function drawBattery(dc, batteryLevel, xStart, yStart, width, height) {                
        dc.setPenWidth(1);
        dc.drawRectangle(xStart, yStart, width, height);
        dc.fillRectangle(xStart + width - 1, yStart + 2, 4, height - 5);   
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        //dc.drawText(xStart+width/2 , yStart+height/2, 0, format("$1$%", [batteryLevel.format("%d")]), Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
       	dc.fillRectangle(xStart + 1, yStart + 1, (width-2) * batteryLevel / 100, height - 2);
    }

}

